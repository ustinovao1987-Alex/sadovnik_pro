import 'package:flutter/material.dart';

import '../data/garden_store.dart';
import 'diary_entry_screen.dart';

class DiaryScreen extends StatefulWidget {
  const DiaryScreen({super.key});

  @override
  State<DiaryScreen> createState() => _DiaryScreenState();
}

class _DiaryScreenState extends State<DiaryScreen> {
  static const Color _leaf = Color(0xFF2E7D32);
  static const Color _sprout = Color(0xFF66BB6A);
  static const Color _sun = Color(0xFFFFB300);
  static const Color _water = Color(0xFF1E88E5);
  static const Color _soil = Color(0xFF8D6E63);
  static const Color _berry = Color(0xFFC62828);
  static const Color _cream = Color(0xFFF7F5EF);
  static const Color _night = Color(0xFF1D2B47);

  final TextEditingController _search = TextEditingController();
  String _query = '';
  int _kindFilter = -1;

  @override
  void initState() {
    super.initState();
    GardenStore.instance.addListener(_onStore);
  }

  void _onStore() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    GardenStore.instance.removeListener(_onStore);
    _search.dispose();
    super.dispose();
  }

  Color _kindColor(DiaryKind k) {
    switch (k) {
      case DiaryKind.planting:
        return _leaf;
      case DiaryKind.harvest:
        return _sun;
      case DiaryKind.care:
        return _water;
      case DiaryKind.note:
        return _soil;
    }
  }

  Future<void> _openEditor({DiaryEntry? entry}) async {
    final result = await Navigator.push<dynamic>(
      context,
      MaterialPageRoute(builder: (_) => DiaryEntryScreen(entry: entry)),
    );
    if (!mounted || result == null) return;
    if (result == 'deleted') {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: _berry,
          content: const Text('Запись удалена'),
          action: entry == null
              ? null
              : SnackBarAction(
                  label: 'Вернуть',
                  textColor: _sun,
                  onPressed: () => GardenStore.instance.upsertEntry(entry),
                ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            backgroundColor: _leaf, content: Text('✅ Дневник обновлён')),
      );
    }
  }

  Future<void> _delete(DiaryEntry e) async {
    await GardenStore.instance.deleteEntry(e.id);
    if (!mounted) return;
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: _berry,
        content: Text('Удалено: ${e.cropName} • ${DiaryMeta.title(e.kind)}'),
        action: SnackBarAction(
          label: 'Вернуть',
          textColor: _sun,
          onPressed: () => GardenStore.instance.upsertEntry(e),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final store = GardenStore.instance;
    final year = store.season;
    final stats = store.statsFor(year);
    final top = store.topCrop(year);

    final entries = store.query(
      year: year,
      kind: _kindFilter < 0 ? null : DiaryKind.values[_kindFilter],
      search: _query,
    );

    final groups = <String, List<DiaryEntry>>{};
    for (final e in entries) {
      final key = '${kMonthsGen[e.date.month - 1]} ${e.date.year}';
      groups.putIfAbsent(key, () => []).add(e);
    }

    return Scaffold(
      backgroundColor: _cream,
      appBar: AppBar(
        backgroundColor: _night,
        foregroundColor: Colors.white,
        title: const Text('Дневник садовода',
            style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: _leaf,
        foregroundColor: Colors.white,
        onPressed: () => _openEditor(),
        icon: const Icon(Icons.edit_note),
        label: const Text('Новая запись',
            style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: Scrollbar(
        thickness: 6,
        radius: const Radius.circular(3),
        thumbVisibility: true,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
          children: [
            _seasonBar(store),
            const SizedBox(height: 14),
            _statsCard(stats, top, year),
            const SizedBox(height: 14),
            _searchField(),
            const SizedBox(height: 10),
            _kindChips(),
            const SizedBox(height: 16),
            if (entries.isEmpty)
              _empty(year)
            else
              ...groups.entries.expand((g) => [
                    _monthHeader(g.key, g.value.length),
                    ...g.value.map(_entryCard),
                  ]),
          ],
        ),
      ),
    );
  }

  Widget _seasonBar(GardenStore store) {
    final years = store.availableYears;
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: years.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final y = years[i];
          final sel = y == store.season;
          return InkWell(
            onTap: () => store.setSeason(y),
            borderRadius: BorderRadius.circular(12),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
              decoration: BoxDecoration(
                color: sel ? _night : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: sel ? _night : Colors.grey.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.calendar_today,
                      size: 14, color: sel ? _sun : Colors.grey[600]),
                  const SizedBox(width: 7),
                  Text('Сезон $y',
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: sel ? Colors.white : Colors.grey[800])),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _statsCard(DiaryStats s, MapEntry<String, double>? top, int year) {
    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_leaf, Color(0xFF3E8E43), _sprout],
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
              color: _leaf.withValues(alpha: 0.3),
              blurRadius: 14,
              offset: const Offset(0, 5)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('ИТОГИ СЕЗОНА $year',
              style: TextStyle(
                  fontSize: 10.5,
                  letterSpacing: 1.2,
                  fontWeight: FontWeight.bold,
                  color: Colors.white.withValues(alpha: 0.85))),
          const SizedBox(height: 12),
          Row(
            children: [
              _metric('${s.plantings}', 'посадок'),
              _metric('${s.harvests}', 'сборов'),
              _metric(
                  s.totalKg == 0
                      ? '—'
                      : s.totalKg.toStringAsFixed(
                          s.totalKg == s.totalKg.roundToDouble() ? 0 : 1),
                  'кг урожая'),
              _metric(s.avgRating == 0 ? '—' : s.avgRating.toStringAsFixed(1),
                  'оценка'),
            ],
          ),
          if (top != null) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(11),
                border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
              ),
              child: Row(
                children: [
                  const Text('🏆', style: TextStyle(fontSize: 18)),
                  const SizedBox(width: 9),
                  Expanded(
                    child: Text(
                      'Урожайнее всего: ${top.key} — ${top.value.toStringAsFixed(1)} кг',
                      style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _metric(String value, String label) {
    return Expanded(
      child: Column(
        children: [
          Text(value,
              style: const TextStyle(
                  fontSize: 23,
                  fontWeight: FontWeight.bold,
                  color: Colors.white)),
          const SizedBox(height: 2),
          Text(label,
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 10.5, color: Colors.white.withValues(alpha: 0.85))),
        ],
      ),
    );
  }

  Widget _searchField() {
    return TextField(
      controller: _search,
      onChanged: (v) => setState(() {
        _query = v;
      }),
      decoration: InputDecoration(
        hintText: 'Поиск по культуре, сорту, заметке…',
        prefixIcon: const Icon(Icons.search, color: _leaf),
        filled: true,
        fillColor: Colors.white,
        contentPadding: EdgeInsets.zero,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.grey.withValues(alpha: 0.25)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.grey.withValues(alpha: 0.25)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: _leaf, width: 1.6),
        ),
        suffixIcon: _search.text.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.close, size: 20),
                onPressed: () {
                  _search.clear();
                  setState(() {
                    _query = '';
                  });
                },
              )
            : null,
      ),
    );
  }

  Widget _kindChips() {
    final labels = ['Все', '🌱 Посадки', '🧺 Урожай', '💧 Уход', '📝 Заметки'];
    return SizedBox(
      height: 38,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: labels.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final sel = _kindFilter == i - 1;
          return InkWell(
            onTap: () => setState(() {
              _kindFilter = i - 1;
            }),
            borderRadius: BorderRadius.circular(11),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
              decoration: BoxDecoration(
                color: sel ? _leaf : Colors.white,
                borderRadius: BorderRadius.circular(11),
                border: Border.all(
                    color: sel ? _leaf : Colors.grey.withValues(alpha: 0.3)),
              ),
              child: Text(labels[i],
                  style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.bold,
                      color: sel ? Colors.white : Colors.grey[700])),
            ),
          );
        },
      ),
    );
  }

  Widget _monthHeader(String title, int count) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(2, 16, 2, 9),
      child: Row(
        children: [
          Text(title.toUpperCase(),
              style: TextStyle(
                  fontSize: 11.5,
                  letterSpacing: 1,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[700])),
          const SizedBox(width: 10),
          Expanded(
            child: Divider(color: Colors.grey.withValues(alpha: 0.3)),
          ),
          const SizedBox(width: 10),
          Text('$count',
              style: TextStyle(fontSize: 12, color: Colors.grey[600])),
        ],
      ),
    );
  }

  Widget _entryCard(DiaryEntry e) {
    final color = _kindColor(e.kind);
    return Dismissible(
      key: ValueKey(e.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => _delete(e),
      background: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: _berry,
          borderRadius: BorderRadius.circular(15),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 22),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text('Удалить',
                style: TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold)),
            SizedBox(width: 8),
            Icon(Icons.delete, color: Colors.white),
          ],
        ),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          border: Border(left: BorderSide(color: color, width: 4)),
          boxShadow: [
            BoxShadow(
                color: color.withValues(alpha: 0.08),
                blurRadius: 8,
                offset: const Offset(0, 3)),
          ],
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(15),
          onTap: () => _openEditor(entry: e),
          child: Padding(
            padding: const EdgeInsets.all(13),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: Center(
                      child: Text(e.cropEmoji,
                          style: const TextStyle(fontSize: 23))),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(e.cropName,
                                style: const TextStyle(
                                    fontSize: 15.5,
                                    fontWeight: FontWeight.bold)),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.14),
                              borderRadius: BorderRadius.circular(7),
                            ),
                            child: Text(
                              '${DiaryMeta.emoji(e.kind)} ${DiaryMeta.title(e.kind)}',
                              style: TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.bold,
                                  color: color),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 5),
                      Wrap(
                        spacing: 10,
                        runSpacing: 4,
                        children: [
                          _meta(Icons.event,
                              '${e.date.day} ${kMonthsGen[e.date.month - 1]}'),
                          if (e.variety.isNotEmpty)
                            _meta(Icons.label_outline, e.variety),
                          if (e.method.isNotEmpty) _meta(Icons.yard, e.method),
                          if (e.amountText.isNotEmpty)
                            _meta(Icons.scale, e.amountText),
                        ],
                      ),
                      if (e.rating > 0) ...[
                        const SizedBox(height: 5),
                        Row(
                          children: List.generate(
                            5,
                            (i) => Icon(
                              i < e.rating ? Icons.star : Icons.star_border,
                              size: 15,
                              color: i < e.rating ? _sun : Colors.grey[400],
                            ),
                          ),
                        ),
                      ],
                      if (e.note.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(e.note,
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                                fontSize: 12.5,
                                color: Colors.grey[700],
                                height: 1.4)),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                Icon(Icons.chevron_right, color: Colors.grey[400]),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _meta(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: Colors.grey[500]),
        const SizedBox(width: 4),
        Text(text, style: TextStyle(fontSize: 11.5, color: Colors.grey[600])),
      ],
    );
  }

  Widget _empty(int year) {
    final store = GardenStore.instance;
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          const Text('📖', style: TextStyle(fontSize: 52)),
          const SizedBox(height: 14),
          Text(
            _query.isNotEmpty || _kindFilter >= 0
                ? 'По этому фильтру записей нет.'
                : 'В сезоне $year пока пусто.',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Записывайте посадки и урожай — через год вы точно вспомните, '
            'какой сорт удался, когда сажали и сколько собрали.',
            textAlign: TextAlign.center,
            style:
                TextStyle(fontSize: 13.5, color: Colors.grey[600], height: 1.5),
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: [
              ElevatedButton.icon(
                onPressed: () => _openEditor(),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Первая запись'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _leaf,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
              if (store.count > 0)
                OutlinedButton.icon(
                  onPressed: () async {
                    final c = store.crops.first;
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => DiaryEntryScreen(
                          presetCropId: cropIdOf(c.name),
                          presetKind: DiaryKind.planting,
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.eco, size: 18, color: _leaf),
                  label: Text('Посадил ${store.crops.first.name}',
                      style: const TextStyle(color: _leaf, fontSize: 12.5)),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: _leaf),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
