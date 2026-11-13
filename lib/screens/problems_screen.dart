import 'package:flutter/material.dart';
import '../data/crop_care_data.dart';
import '../data/crops_data.dart';

class ProblemsScreen extends StatefulWidget {
  final Crop crop;
  const ProblemsScreen({super.key, required this.crop});

  @override
  State<ProblemsScreen> createState() => _ProblemsScreenState();
}

class _ProblemsScreenState extends State<ProblemsScreen> {
  late final CropCare _care;
  final TextEditingController _search = TextEditingController();
  int _filter = 0; // 0 все, 1 болезни, 2 вредители

  static const Color _leaf = Color(0xFF2E7D32);
  static const Color _berry = Color(0xFFC62828);
  static const Color _soil = Color(0xFF8D6E63);
  static const Color _cream = Color(0xFFF7F5EF);

  @override
  void initState() {
    super.initState();
    _care = CropCareRepository.forCrop(widget.crop.name);
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  List<CropProblem> get _filtered {
    final q = _search.text.trim().toLowerCase();
    return _care.problems.where((p) {
      if (_filter == 1 && p.kind != ProblemKind.disease) return false;
      if (_filter == 2 && p.kind != ProblemKind.pest) return false;
      if (q.isEmpty) return true;
      return p.name.toLowerCase().contains(q) ||
          p.symptoms.toLowerCase().contains(q);
    }).toList();
  }

  Color _dangerColor(DangerLevel d) {
    switch (d) {
      case DangerLevel.high:
        return const Color(0xFFC62828);
      case DangerLevel.medium:
        return const Color(0xFFEF6C00);
      case DangerLevel.low:
        return _leaf;
    }
  }

  String _dangerText(DangerLevel d) {
    switch (d) {
      case DangerLevel.high:
        return 'Высокий риск';
      case DangerLevel.medium:
        return 'Средний риск';
      case DangerLevel.low:
        return 'Низкий риск';
    }
  }

  @override
  Widget build(BuildContext context) {
    final items = _filtered;
    final diseases =
        _care.problems.where((p) => p.kind == ProblemKind.disease).length;
    final pests =
        _care.problems.where((p) => p.kind == ProblemKind.pest).length;

    return Scaffold(
      backgroundColor: _cream,
      appBar: AppBar(
        title: Text('${widget.crop.emoji} Болезни и вредители'),
        centerTitle: true,
        backgroundColor: _berry,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [_berry, _soil],
              ),
            ),
            child: Column(
              children: [
                TextField(
                  controller: _search,
                  onChanged: (_) => setState(() {}),
                  style: const TextStyle(fontSize: 15),
                  decoration: InputDecoration(
                    hintText: 'Поиск по названию или симптомам…',
                    prefixIcon: const Icon(Icons.search, color: _berry),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(vertical: 0),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                    suffixIcon: _search.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () {
                              _search.clear();
                              setState(() {});
                            },
                          )
                        : null,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    _chip(0, 'Все (${_care.problems.length})'),
                    const SizedBox(width: 8),
                    _chip(1, 'Болезни ($diseases)'),
                    const SizedBox(width: 8),
                    _chip(2, 'Вредители ($pests)'),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: items.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(28),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.eco,
                              size: 64, color: _leaf.withValues(alpha: 0.5)),
                          const SizedBox(height: 14),
                          Text(
                            _care.problems.isEmpty
                                ? 'Для этой культуры справочник пока пополняется.\nГлавное правило: осмотр раз в неделю, полив под корень и севооборот.'
                                : 'Ничего не найдено. Попробуйте другой запрос или фильтр.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                fontSize: 15,
                                color: Colors.grey[700],
                                height: 1.5),
                          ),
                        ],
                      ),
                    ),
                  )
                : Scrollbar(
                    thickness: 6,
                    radius: const Radius.circular(3),
                    thumbVisibility: true,
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: items.length,
                      itemBuilder: (context, i) => _problemCard(items[i]),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _chip(int value, String label) {
    final selected = _filter == value;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() {
          _filter = value;
        }),
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 9),
          decoration: BoxDecoration(
            color:
                selected ? Colors.white : Colors.white.withValues(alpha: 0.18),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: selected ? Colors.white : Colors.white38),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.bold,
              color: selected ? _berry : Colors.white,
            ),
          ),
        ),
      ),
    );
  }

  Widget _problemCard(CropProblem p) {
    final kindColor = p.kind == ProblemKind.disease ? _berry : _soil;
    final dc = _dangerColor(p.danger);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kindColor.withValues(alpha: 0.25)),
        boxShadow: [
          BoxShadow(
              color: kindColor.withValues(alpha: 0.07),
              blurRadius: 8,
              offset: const Offset(0, 3)),
        ],
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
          leading: CircleAvatar(
            backgroundColor: kindColor.withValues(alpha: 0.14),
            child: Icon(
              p.kind == ProblemKind.disease
                  ? Icons.coronavirus
                  : Icons.bug_report,
              color: kindColor,
              size: 22,
            ),
          ),
          title: Text(p.name,
              style:
                  const TextStyle(fontSize: 15.5, fontWeight: FontWeight.bold)),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: dc.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(_dangerText(p.danger),
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: dc)),
                ),
                const SizedBox(width: 8),
                Text(
                  p.kind == ProblemKind.disease ? 'Болезнь' : 'Вредитель',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          children: [
            _block('Симптомы', Icons.visibility, kindColor, [p.symptoms]),
            const SizedBox(height: 10),
            _block('Что делать', Icons.healing, const Color(0xFFEF6C00),
                p.treatment,
                numbered: true),
            const SizedBox(height: 10),
            _block('Профилактика', Icons.shield, _leaf, p.prevention),
          ],
        ),
      ),
    );
  }

  Widget _block(String title, IconData icon, Color color, List<String> lines,
      {bool numbered = false}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(12),
        border: Border(left: BorderSide(color: color, width: 4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 17, color: color),
              const SizedBox(width: 6),
              Text(title,
                  style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.bold,
                      color: color)),
            ],
          ),
          const SizedBox(height: 6),
          ...List.generate(lines.length, (i) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 5),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    numbered ? '${i + 1}.' : '•',
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: color),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(lines[i],
                        style: const TextStyle(fontSize: 13.5, height: 1.45)),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
