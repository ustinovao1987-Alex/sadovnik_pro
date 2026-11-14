import 'package:flutter/material.dart';

import '../data/crops_data.dart';
import '../data/garden_store.dart';

const List<String> kMonthsGen = [
  'января',
  'февраля',
  'марта',
  'апреля',
  'мая',
  'июня',
  'июля',
  'августа',
  'сентября',
  'октября',
  'ноября',
  'декабря',
];

class DiaryEntryScreen extends StatefulWidget {
  final DiaryEntry? entry;
  final String? presetCropId;
  final DiaryKind? presetKind;

  const DiaryEntryScreen({
    super.key,
    this.entry,
    this.presetCropId,
    this.presetKind,
  });

  @override
  State<DiaryEntryScreen> createState() => _DiaryEntryScreenState();
}

class _DiaryEntryScreenState extends State<DiaryEntryScreen> {
  static const Color _leaf = Color(0xFF2E7D32);
  static const Color _sun = Color(0xFFFFB300);
  static const Color _water = Color(0xFF1E88E5);
  static const Color _berry = Color(0xFFC62828);
  static const Color _soil = Color(0xFF8D6E63);
  static const Color _cream = Color(0xFFF7F5EF);

  late DiaryKind _kind;
  late DateTime _date;
  String _cropId = '';
  String _cropName = 'Весь сад';
  String _cropEmoji = '🌿';
  int _rating = 0;
  String _method = 'Открытый грунт';
  String _unit = 'кг';

  final _variety = TextEditingController();
  final _amount = TextEditingController();
  final _note = TextEditingController();
  bool _saving = false;

  static const _methods = [
    'Открытый грунт',
    'Теплица',
    'Рассада',
    'Парник',
    'Балкон / кашпо',
  ];
  static const _units = ['кг', 'г', 'шт', 'л', 'м²'];

  @override
  void initState() {
    super.initState();
    final e = widget.entry;
    _kind = e?.kind ?? widget.presetKind ?? DiaryKind.planting;
    _date = e?.date ?? DateTime.now();
    _rating = e?.rating ?? 0;
    _unit = e?.unit ?? 'кг';
    _method = (e?.method.isNotEmpty ?? false) ? e!.method : _methods.first;
    _variety.text = e?.variety ?? '';
    _amount.text = e?.amount == null
        ? ''
        : (e!.amount == e.amount!.roundToDouble()
            ? e.amount!.toStringAsFixed(0)
            : e.amount!.toStringAsFixed(1));
    _note.text = e?.note ?? '';

    if (e != null) {
      _cropId = e.cropId;
      _cropName = e.cropName;
      _cropEmoji = e.cropEmoji;
    } else if (widget.presetCropId != null) {
      final c = GardenStore.instance.cropById(widget.presetCropId!);
      if (c != null) {
        _cropId = cropIdOf(c.name);
        _cropName = c.name;
        _cropEmoji = c.emoji;
      }
    }
  }

  @override
  void dispose() {
    _variety.dispose();
    _amount.dispose();
    _note.dispose();
    super.dispose();
  }

  Color get _accent {
    switch (_kind) {
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

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2015),
      lastDate: DateTime(DateTime.now().year + 2, 12, 31),
      helpText: 'Дата события',
      cancelText: 'Отмена',
      confirmText: 'Выбрать',
    );
    if (picked == null) return;
    setState(() {
      _date = DateTime(
          picked.year, picked.month, picked.day, _date.hour, _date.minute);
    });
  }

  Future<void> _pickCrop() async {
    final store = GardenStore.instance;
    final garden = store.crops;
    final others =
        availableCrops.where((c) => !store.has(cropIdOf(c.name))).toList();

    final result = await showModalBottomSheet<Crop?>(
      context: context,
      backgroundColor: _cream,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.7,
        maxChildSize: 0.92,
        builder: (_, controller) => Column(
          children: [
            const SizedBox(height: 12),
            Container(
              width: 42,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[400],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('О какой культуре запись?',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
            ),
            Expanded(
              child: ListView(
                controller: controller,
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                children: [
                  ListTile(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(13)),
                    tileColor: Colors.white,
                    leading: const Text('🌿', style: TextStyle(fontSize: 26)),
                    title: const Text('Весь сад',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: const Text('Общая запись без привязки'),
                    onTap: () => Navigator.pop(ctx, null),
                  ),
                  if (garden.isNotEmpty) _sheetHeader('МОЙ САД'),
                  ...garden.map((c) => _sheetTile(ctx, c)),
                  if (others.isNotEmpty) _sheetHeader('ОСТАЛЬНЫЙ КАТАЛОГ'),
                  ...others.map((c) => _sheetTile(ctx, c)),
                ],
              ),
            ),
          ],
        ),
      ),
    );

    if (!mounted) return;
    if (result == null) {
      setState(() {
        _cropId = '';
        _cropName = 'Весь сад';
        _cropEmoji = '🌿';
      });
    } else {
      setState(() {
        _cropId = cropIdOf(result.name);
        _cropName = result.name;
        _cropEmoji = result.emoji;
      });
    }
  }

  Widget _sheetHeader(String t) => Padding(
        padding: const EdgeInsets.fromLTRB(4, 18, 4, 8),
        child: Text(t,
            style: TextStyle(
                fontSize: 11.5,
                letterSpacing: 1,
                fontWeight: FontWeight.bold,
                color: Colors.grey[600])),
      );

  Widget _sheetTile(BuildContext ctx, Crop c) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: ListTile(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)),
          tileColor: Colors.white,
          leading: Text(c.emoji, style: const TextStyle(fontSize: 26)),
          title:
              Text(c.name, style: const TextStyle(fontWeight: FontWeight.w600)),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => Navigator.pop(ctx, c),
        ),
      );

  Future<void> _save() async {
    final parsed = double.tryParse(_amount.text.replaceAll(',', '.'));
    setState(() {
      _saving = true;
    });
    final entry = DiaryEntry(
      id: widget.entry?.id ?? DiaryEntry.newId(),
      cropId: _cropId,
      cropName: _cropName,
      cropEmoji: _cropEmoji,
      kind: _kind,
      date: _date,
      variety: _variety.text.trim(),
      method: _kind == DiaryKind.planting ? _method : '',
      amount: parsed,
      unit: _unit,
      rating: _kind == DiaryKind.harvest ? _rating : 0,
      note: _note.text.trim(),
    );
    await GardenStore.instance.upsertEntry(entry);
    if (!mounted) return;
    Navigator.pop(context, entry);
  }

  Future<void> _delete() async {
    final e = widget.entry;
    if (e == null) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text('Удалить запись?'),
        content: Text('${e.cropName} • ${DiaryMeta.title(e.kind)}'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Отмена')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: _berry, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await GardenStore.instance.deleteEntry(e.id);
    if (!mounted) return;
    Navigator.pop(context, 'deleted');
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.entry != null;
    return Scaffold(
      backgroundColor: _cream,
      appBar: AppBar(
        backgroundColor: _accent,
        foregroundColor: Colors.white,
        title: Text(isEdit ? 'Правка записи' : 'Новая запись',
            style: const TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          if (isEdit)
            IconButton(
              tooltip: 'Удалить',
              onPressed: _delete,
              icon: const Icon(Icons.delete_outline),
            ),
        ],
      ),
      body: Scrollbar(
        thickness: 6,
        radius: const Radius.circular(3),
        thumbVisibility: true,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _card(
              title: 'Что произошло?',
              icon: Icons.category,
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: DiaryKind.values.map((k) {
                  final sel = _kind == k;
                  return InkWell(
                    onTap: () => setState(() {
                      _kind = k;
                    }),
                    borderRadius: BorderRadius.circular(13),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      width: 150,
                      padding: const EdgeInsets.symmetric(
                          vertical: 13, horizontal: 10),
                      decoration: BoxDecoration(
                        color: sel ? _accent : Colors.white,
                        borderRadius: BorderRadius.circular(13),
                        border: Border.all(
                            color: sel
                                ? _accent
                                : Colors.grey.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(DiaryMeta.emoji(k),
                              style: const TextStyle(fontSize: 19)),
                          const SizedBox(width: 8),
                          Text(DiaryMeta.title(k),
                              style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color:
                                      sel ? Colors.white : Colors.grey[800])),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 14),
            _card(
              title: 'Культура и дата',
              icon: Icons.eco,
              child: Column(
                children: [
                  InkWell(
                    onTap: _pickCrop,
                    borderRadius: BorderRadius.circular(13),
                    child: Container(
                      padding: const EdgeInsets.all(13),
                      decoration: BoxDecoration(
                        color: _leaf.withValues(alpha: 0.07),
                        borderRadius: BorderRadius.circular(13),
                        border:
                            Border.all(color: _leaf.withValues(alpha: 0.25)),
                      ),
                      child: Row(
                        children: [
                          Text(_cropEmoji,
                              style: const TextStyle(fontSize: 27)),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(_cropName,
                                style: const TextStyle(
                                    fontSize: 15.5,
                                    fontWeight: FontWeight.bold)),
                          ),
                          const Icon(Icons.expand_more, color: _leaf),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  InkWell(
                    onTap: _pickDate,
                    borderRadius: BorderRadius.circular(13),
                    child: Container(
                      padding: const EdgeInsets.all(13),
                      decoration: BoxDecoration(
                        color: _water.withValues(alpha: 0.07),
                        borderRadius: BorderRadius.circular(13),
                        border:
                            Border.all(color: _water.withValues(alpha: 0.25)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.event, color: _water),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              '${_date.day} ${kMonthsGen[_date.month - 1]} ${_date.year}',
                              style: const TextStyle(
                                  fontSize: 15.5, fontWeight: FontWeight.bold),
                            ),
                          ),
                          const Icon(Icons.edit_calendar,
                              color: _water, size: 20),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _variety,
                    decoration: _dec('Сорт / гибрид', 'например, Бычье сердце'),
                  ),
                ],
              ),
            ),
            if (_kind == DiaryKind.planting) ...[
              const SizedBox(height: 14),
              _card(
                title: 'Способ посадки',
                icon: Icons.yard,
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _methods.map((m) {
                    final sel = _method == m;
                    return ChoiceChip(
                      label: Text(m, style: const TextStyle(fontSize: 12.5)),
                      selected: sel,
                      selectedColor: _leaf,
                      labelStyle: TextStyle(
                          color: sel ? Colors.white : Colors.grey[800],
                          fontWeight: FontWeight.w600),
                      backgroundColor: Colors.white,
                      side: BorderSide(
                          color:
                              sel ? _leaf : Colors.grey.withValues(alpha: 0.3)),
                      onSelected: (_) => setState(() {
                        _method = m;
                      }),
                    );
                  }).toList(),
                ),
              ),
            ],
            const SizedBox(height: 14),
            _card(
              title: _kind == DiaryKind.harvest
                  ? 'Сколько собрали?'
                  : 'Количество (необязательно)',
              icon: Icons.scale,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: TextField(
                      controller: _amount,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      decoration: _dec('Например, 12,5', '0'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  SizedBox(
                    width: 96,
                    child: DropdownButtonFormField<String>(
                      initialValue: _unit,
                      decoration: _dec('Единица', ''),
                      items: _units
                          .map(
                              (u) => DropdownMenuItem(value: u, child: Text(u)))
                          .toList(),
                      onChanged: (v) => setState(() {
                        _unit = v ?? 'кг';
                      }),
                    ),
                  ),
                ],
              ),
            ),
            if (_kind == DiaryKind.harvest) ...[
              const SizedBox(height: 14),
              _card(
                title: 'Оценка урожая',
                icon: Icons.star,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: List.generate(5, (i) {
                        final filled = i < _rating;
                        return IconButton(
                          onPressed: () => setState(() {
                            _rating = _rating == i + 1 ? 0 : i + 1;
                          }),
                          icon: Icon(
                            filled ? Icons.star : Icons.star_border,
                            size: 34,
                            color: filled ? _sun : Colors.grey[400],
                          ),
                        );
                      }),
                    ),
                    Text(
                      _rating == 0
                          ? 'Поставьте оценку — в конце сезона увидите, что удалось лучше всего.'
                          : 'Оценка: $_rating из 5',
                      style: TextStyle(fontSize: 12.5, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 14),
            _card(
              title: 'Заметки',
              icon: Icons.notes,
              child: TextField(
                controller: _note,
                maxLines: 5,
                decoration: _dec('Что получилось, что нет',
                    'Погода, полив, болезни, вкус, выводы на следующий год…'),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 52,
              child: ElevatedButton.icon(
                onPressed: _saving ? null : _save,
                icon: const Icon(Icons.save),
                label: Text(
                    isEdit ? 'Сохранить изменения' : 'Записать в дневник',
                    style: const TextStyle(
                        fontSize: 15.5, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _accent,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15)),
                ),
              ),
            ),
            const SizedBox(height: 26),
          ],
        ),
      ),
    );
  }

  InputDecoration _dec(String label, String hint) => InputDecoration(
        labelText: label,
        hintText: hint,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(13),
          borderSide: BorderSide(color: Colors.grey.withValues(alpha: 0.3)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(13),
          borderSide: BorderSide(color: Colors.grey.withValues(alpha: 0.3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(13),
          borderSide: BorderSide(color: _accent, width: 1.6),
        ),
      );

  Widget _card({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _accent.withValues(alpha: 0.22)),
        boxShadow: [
          BoxShadow(
              color: _accent.withValues(alpha: 0.06),
              blurRadius: 9,
              offset: const Offset(0, 3)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 19, color: _accent),
              const SizedBox(width: 8),
              Text(title,
                  style: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 13),
          child,
        ],
      ),
    );
  }
}
