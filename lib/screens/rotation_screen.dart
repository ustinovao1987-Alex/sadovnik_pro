import 'package:flutter/material.dart';
import '../data/rotation_advisor.dart';
import '../data/crop_catalog.dart';
import '../data/garden_store.dart';

class RotationScreen extends StatefulWidget {
  const RotationScreen({super.key});

  @override
  State<RotationScreen> createState() => _RotationScreenState();
}

class _RotationScreenState extends State<RotationScreen> {
  static const Color _leaf = Color(0xFF2E7D32);
  static const Color _cream = Color(0xFFF7F5EF);

  String? _selectedPlot = 'Основная грядка';
  String? _selectedCrop;

  @override
  Widget build(BuildContext context) {
    final store = GardenStore.instance;
    final plots = _getUniquePlots(store);

    return Scaffold(
      backgroundColor: _cream,
      appBar: AppBar(
          backgroundColor: _leaf,
          foregroundColor: Colors.white,
          title: const Text('Севооборот')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                DropdownButtonFormField<String>(
                  value: _selectedPlot,
                  decoration: const InputDecoration(
                      labelText: 'Выберите грядку',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.yard)),
                  items: plots
                      .map((plot) =>
                          DropdownMenuItem(value: plot, child: Text(plot)))
                      .toList(),
                  onChanged: (value) => setState(() => _selectedPlot = value),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _selectedCrop,
                  decoration: const InputDecoration(
                      labelText: 'Культура для посадки',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.eco)),
                  items: CropCatalog.all
                      .map((crop) => DropdownMenuItem(
                          value: crop.id,
                          child: Text('${crop.emoji} ${crop.name}')))
                      .toList(),
                  onChanged: (value) => setState(() => _selectedCrop = value),
                ),
              ],
            ),
          ),
          if (_selectedPlot != null && _selectedCrop != null)
            Expanded(child: _buildAdvice(store)),
        ],
      ),
    );
  }

  List<String> _getUniquePlots(GardenStore store) {
    final plots = <String>{};
    for (final entry in store.entries) {
      if (entry.plotId.isNotEmpty) plots.add(entry.plotId);
    }
    return plots.isEmpty ? ['Основная грядка'] : plots.toList();
  }

  Widget _buildAdvice(GardenStore store) {
    if (_selectedCrop == null || _selectedPlot == null)
      return const SizedBox.shrink();

    final advice = RotationAdvisor.checkRotation(
        cropId: _selectedCrop!, plotId: _selectedPlot!, history: store.entries);
    final crop = CropCatalog.byId(_selectedCrop!);
    if (crop == null) return const SizedBox.shrink();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _adviceCard(advice),
        const SizedBox(height: 16),
        _cropInfoCard(crop),
        const SizedBox(height: 16),
        _recommendationsCard(store)
      ],
    );
  }

  Widget _adviceCard(RotationAdvice advice) {
    Color bgColor, textColor;
    IconData icon;
    switch (advice.level) {
      case AdviceLevel.success:
        bgColor = Colors.green.withValues(alpha: 0.1);
        textColor = Colors.green;
        icon = Icons.check_circle;
        break;
      case AdviceLevel.info:
        bgColor = Colors.blue.withValues(alpha: 0.1);
        textColor = Colors.blue;
        icon = Icons.info;
        break;
      case AdviceLevel.warning:
        bgColor = Colors.orange.withValues(alpha: 0.1);
        textColor = Colors.orange;
        icon = Icons.warning;
        break;
      case AdviceLevel.error:
        bgColor = Colors.red.withValues(alpha: 0.1);
        textColor = Colors.red;
        icon = Icons.error;
        break;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: textColor.withValues(alpha: 0.3))),
      child: Column(
        children: [
          Icon(icon, color: textColor, size: 48),
          const SizedBox(height: 12),
          Text(advice.allowed ? 'Можно сажать!' : 'Не рекомендуется',
              style: TextStyle(
                  fontSize: 20, fontWeight: FontWeight.bold, color: textColor)),
          const SizedBox(height: 8),
          Text(advice.reason,
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 14, color: textColor.withValues(alpha: 0.9))),
          if (advice.waitYears != null && advice.waitYears! > 0) ...[
            const SizedBox(height: 8),
            Text(
                'Подождите ещё ${advice.waitYears} ${_yearsWord(advice.waitYears!)}',
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: textColor)),
          ],
        ],
      ),
    );
  }

  Widget _cropInfoCard(CropRecord crop) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(crop.emoji, style: const TextStyle(fontSize: 32)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(crop.name,
                          style: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold)),
                      Text(RotationAdvisor.familyTitle(crop.family),
                          style:
                              TextStyle(fontSize: 14, color: Colors.grey[600])),
                    ]),
              ),
            ],
          ),
          const Divider(height: 24),
          const Text('Хорошие предшественники:',
              style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Wrap(
              spacing: 8,
              children: RotationAdvisor.getGoodPredecessors(crop.family)
                  .map((f) => Chip(
                      label: Text(RotationAdvisor.familyTitle(f)),
                      backgroundColor: Colors.green.withValues(alpha: 0.1)))
                  .toList()),
          const SizedBox(height: 12),
          const Text('Плохие предшественники:',
              style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Wrap(
              spacing: 8,
              children: RotationAdvisor.getBadPredecessors(crop.family)
                  .map((f) => Chip(
                      label: Text(RotationAdvisor.familyTitle(f)),
                      backgroundColor: Colors.red.withValues(alpha: 0.1)))
                  .toList()),
        ],
      ),
    );
  }

  Widget _recommendationsCard(GardenStore store) {
    final recommendations = RotationAdvisor.recommendCrops(
        plotId: _selectedPlot ?? '', history: store.entries);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Рекомендуемые культуры для этого участка:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          ...recommendations.take(5).map((crop) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(children: [
                Text(crop.emoji, style: const TextStyle(fontSize: 20)),
                const SizedBox(width: 12),
                Text(crop.name)
              ]))),
        ],
      ),
    );
  }

  String _yearsWord(int n) {
    if (n == 1) return 'год';
    if (n >= 2 && n <= 4) return 'года';
    return 'лет';
  }
}
