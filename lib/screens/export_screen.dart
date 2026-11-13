import 'package:flutter/material.dart';
import '../data/diary_export.dart';
import '../data/garden_store.dart';

class ExportScreen extends StatefulWidget {
  const ExportScreen({super.key});

  @override
  State<ExportScreen> createState() => _ExportScreenState();
}

class _ExportScreenState extends State<ExportScreen> {
  static const Color _leaf = Color(0xFF2E7D32);
  static const Color _cream = Color(0xFFF7F5EF);
  int _selectedYear = DateTime.now().year;

  @override
  Widget build(BuildContext context) {
    final store = GardenStore.instance;
    final entries = store.query(year: _selectedYear);

    return Scaffold(
      backgroundColor: _cream,
      appBar: AppBar(
        backgroundColor: _leaf,
        foregroundColor: Colors.white,
        title: const Text('Экспорт дневника'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Text('Год: ', style: TextStyle(fontSize: 16)),
                Expanded(
                  child: DropdownButton<int>(
                    value: _selectedYear,
                    isExpanded: true,
                    items: List.generate(5, (i) => _selectedYear - i)
                        .map((year) => DropdownMenuItem(
                            value: year, child: Text('$year год')))
                        .toList(),
                    onChanged: (value) {
                      if (value != null) setState(() => _selectedYear = value);
                    },
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _statCard(
                    icon: Icons.calendar_today,
                    title: 'Записей за год',
                    value: '${entries.length}',
                    color: Colors.blue),
                const SizedBox(height: 12),
                _statCard(
                    icon: Icons.agriculture,
                    title: 'Посадок',
                    value:
                        '${entries.where((e) => e.kind == DiaryKind.planting).length}',
                    color: Colors.green),
                const SizedBox(height: 12),
                _statCard(
                    icon: Icons.shopping_basket,
                    title: 'Урожаев',
                    value:
                        '${entries.where((e) => e.kind == DiaryKind.harvest).length}',
                    color: Colors.orange),
                const SizedBox(height: 12),
                _statCard(
                    icon: Icons.note,
                    title: 'Заметок',
                    value:
                        '${entries.where((e) => e.kind == DiaryKind.note).length}',
                    color: Colors.purple),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                ElevatedButton.icon(
                  onPressed: () => DiaryExporter.exportAndShare(
                      year: _selectedYear, entries: entries),
                  icon: const Icon(Icons.share),
                  label: const Text('Экспорт в CSV (Excel)'),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: _leaf,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 50)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _statCard(
      {required IconData icon,
      required String title,
      required String value,
      required Color color}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.2))),
      child: Row(
        children: [
          Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, color: color, size: 24)),
          const SizedBox(width: 16),
          Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title,
                  style: TextStyle(fontSize: 14, color: Colors.grey[600])),
              const SizedBox(height: 4),
              Text(value,
                  style: const TextStyle(
                      fontSize: 24, fontWeight: FontWeight.bold)),
            ]),
          ),
        ],
      ),
    );
  }
}
