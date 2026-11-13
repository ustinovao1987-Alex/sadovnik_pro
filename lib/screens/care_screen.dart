import 'package:flutter/material.dart';

import '../data/crop_care_data.dart';
import '../data/crops_data.dart';
import '../data/irrigation.dart';

class CareScreen extends StatefulWidget {
  final Crop crop;
  const CareScreen({super.key, required this.crop});

  @override
  State<CareScreen> createState() => _CareScreenState();
}

class _CareScreenState extends State<CareScreen> {
  DateTime? _lastWater;
  List<bool> _checks = const [];
  bool _loading = true;
  bool _showMath = false;
  String _careKey = '';

  static const Color _leaf = Color(0xFF2E7D32);
  static const Color _sprout = Color(0xFF66BB6A);
  static const Color _water = Color(0xFF1E88E5);
  static const Color _sun = Color(0xFFFFB300);
  static const Color _soilC = Color(0xFF8D6E63);
  static const Color _cream = Color(0xFFF7F5EF);

  @override
  void initState() {
    super.initState();
    IrrigationSettings.instance.addListener(_onSettings);
    _bootstrap();
  }

  void _onSettings() {
    if (mounted) setState(() {});
  }

  Future<void> _bootstrap() async {
    await IrrigationSettings.instance.syncLatitude();
    final care = CropCareRepository.forCrop(widget.crop.name);
    final last = await WateringLog.last(care.key);
    final checks = await CareChecklist.load(care.key, care.tips.length);
    if (!mounted) return;
    setState(() {
      _careKey = care.key;
      _lastWater = last;
      _checks = checks;
      _loading = false;
    });
  }

  @override
  void dispose() {
    IrrigationSettings.instance.removeListener(_onSettings);
    super.dispose();
  }

  Future<void> _markWatered() async {
    final prev = _lastWater;
    final now = DateTime.now();
    await WateringLog.mark(_careKey, now);
    if (!mounted) return;
    setState(() {
      _lastWater = now;
    });
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: _leaf,
        content: const Text('💧 Полив отмечен'),
        action: SnackBarAction(
          label: 'Отменить',
          textColor: _sun,
          onPressed: () async {
            if (prev == null) {
              await WateringLog.clear(_careKey);
            } else {
              await WateringLog.mark(_careKey, prev);
            }
            if (!mounted) return;
            setState(() {
              _lastWater = prev;
            });
          },
        ),
      ),
    );
  }

  Future<void> _toggleTip(int i, bool v) async {
    setState(() {
      _checks[i] = v;
    });
    await CareChecklist.set(_careKey, i, v);
  }

  Future<void> _resetTips(int count) async {
    await CareChecklist.reset(_careKey, count);
    if (!mounted) return;
    setState(() {
      _checks = List.filled(count, false);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        backgroundColor: _cream,
        appBar: AppBar(title: const Text('Уход и полив')),
        body: const Center(child: CircularProgressIndicator(color: _leaf)),
      );
    }

    final care = CropCareRepository.forCrop(widget.crop.name);
    final plan = care.plan;
    final s = IrrigationSettings.instance;
    final gap = care.waterEveryDays <= 0 ? 5 : care.waterEveryDays;
    final due = WateringLog.isDue(_lastWater, gap);
    final days = _lastWater == null
        ? null
        : DateTime.now().difference(_lastWater!).inDays;
    final done = _checks.where((c) => c).length;
    final progress = care.tips.isEmpty ? 0.0 : done / care.tips.length;

    return Scaffold(
      backgroundColor: _cream,
      body: Scrollbar(
        thickness: 6,
        radius: const Radius.circular(3),
        thumbVisibility: true,
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              expandedHeight: 160,
              pinned: true,
              backgroundColor: _leaf,
              foregroundColor: Colors.white,
              flexibleSpace: FlexibleSpaceBar(
                title: Text('${widget.crop.emoji} ${care.name}',
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold)),
                background: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [_water, _leaf, _sprout],
                    ),
                  ),
                  child: const Center(
                    child:
                        Icon(Icons.water_drop, size: 70, color: Colors.white24),
                  ),
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  if (plan != null) _planCard(plan, care),
                  const SizedBox(height: 14),
                  _conditionsCard(s),
                  const SizedBox(height: 14),
                  _trackerCard(care, due, days, gap),
                  const SizedBox(height: 14),
                  _section(
                    icon: Icons.opacity,
                    color: _water,
                    title: 'Как поливать',
                    child: Text(care.waterMethod,
                        style: const TextStyle(fontSize: 14, height: 1.5)),
                  ),
                  const SizedBox(height: 14),
                  _section(
                    icon: Icons.science,
                    color: _sun,
                    title: 'Подкормки по этапам',
                    child: Column(
                      children: List.generate(care.feeding.length, (i) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              CircleAvatar(
                                radius: 13,
                                backgroundColor: _sun.withValues(alpha: 0.2),
                                child: Text('${i + 1}',
                                    style: const TextStyle(
                                        color: Color(0xFF8D6E00),
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13)),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(care.feeding[i],
                                    style: const TextStyle(
                                        fontSize: 14, height: 1.45)),
                              ),
                            ],
                          ),
                        );
                      }),
                    ),
                  ),
                  const SizedBox(height: 14),
                  _section(
                    icon: Icons.terrain,
                    color: _soilC,
                    title: 'Почва',
                    child: Text(care.soil,
                        style: const TextStyle(fontSize: 14, height: 1.5)),
                  ),
                  const SizedBox(height: 14),
                  _section(
                    icon: Icons.checklist,
                    color: _leaf,
                    title: 'Приёмы ухода • чек-лист',
                    trailing: TextButton(
                      onPressed: () => _resetTips(care.tips.length),
                      child: const Text('Сбросить'),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(6),
                                child: LinearProgressIndicator(
                                  value: progress,
                                  minHeight: 8,
                                  backgroundColor:
                                      _leaf.withValues(alpha: 0.12),
                                  valueColor:
                                      const AlwaysStoppedAnimation(_leaf),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text('$done / ${care.tips.length}',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold, color: _leaf)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ...List.generate(care.tips.length, (i) {
                          final checked =
                              i < _checks.length ? _checks[i] : false;
                          return CheckboxListTile(
                            value: checked,
                            onChanged: (v) => _toggleTip(i, v ?? false),
                            activeColor: _leaf,
                            contentPadding: EdgeInsets.zero,
                            controlAffinity: ListTileControlAffinity.leading,
                            title: Text(care.tips[i],
                                style: TextStyle(
                                  fontSize: 14,
                                  height: 1.4,
                                  decoration: checked
                                      ? TextDecoration.lineThrough
                                      : TextDecoration.none,
                                  color: checked
                                      ? Colors.grey
                                      : const Color(0xFF2B2B2B),
                                )),
                          );
                        }),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _planCard(IrrigationPlan plan, CropCare care) {
    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            _water.withValues(alpha: 0.16),
            _sprout.withValues(alpha: 0.08),
          ],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _water.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.calculate, color: _water, size: 20),
              const SizedBox(width: 8),
              const Expanded(
                child: Text('Норма полива • расчёт',
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _water.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text('FAO-56',
                    style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: _water)),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (plan.rainCoversNeed)
            Container(
              padding: const EdgeInsets.all(13),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.75),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                children: [
                  Text('🌧️', style: TextStyle(fontSize: 26)),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Дождя достаточно — полив сегодня не нужен.',
                      style: TextStyle(
                          fontSize: 14.5, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            )
          else
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(plan.litersPerPlant.toStringAsFixed(1),
                    style: const TextStyle(
                        fontSize: 40,
                        height: 1,
                        fontWeight: FontWeight.bold,
                        color: _water)),
                const SizedBox(width: 6),
                const Padding(
                  padding: EdgeInsets.only(bottom: 5),
                  child: Text('л под растение',
                      style: TextStyle(
                          fontSize: 13.5, fontWeight: FontWeight.w600)),
                ),
                const Spacer(),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(plan.intervalText,
                        style: const TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.bold,
                            color: _leaf)),
                    Text('≈ ${plan.perAreaText}',
                        style:
                            TextStyle(fontSize: 11.5, color: Colors.grey[600])),
                  ],
                ),
              ],
            ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              _tag('ET₀ ${plan.et0.toStringAsFixed(2)} мм/сут'),
              _tag('Kc ${plan.kc.toStringAsFixed(2)}'),
              _tag('Потребность ${plan.weeklyMm.toStringAsFixed(0)} мм/нед'),
              _tag('Площадь питания ${care.plantAreaM2.toStringAsFixed(2)} м²'),
            ],
          ),
          const SizedBox(height: 10),
          InkWell(
            onTap: () => setState(() {
              _showMath = !_showMath;
            }),
            borderRadius: BorderRadius.circular(10),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: [
                  Icon(_showMath ? Icons.expand_less : Icons.expand_more,
                      size: 20, color: _water),
                  const SizedBox(width: 6),
                  const Text('Почему именно столько?',
                      style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w600,
                          color: _water)),
                ],
              ),
            ),
          ),
          if (_showMath)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.8),
                borderRadius: BorderRadius.circular(11),
              ),
              child: Text(plan.reasoning,
                  style: const TextStyle(fontSize: 12.5, height: 1.5)),
            ),
          const SizedBox(height: 8),
          Text(
            'Расчёт — ориентир, а не догма. Проверяйте влажность на глубине '
            '5–10 см: комок распадается — пора поливать.',
            style:
                TextStyle(fontSize: 11.5, color: Colors.grey[600], height: 1.4),
          ),
        ],
      ),
    );
  }

  Widget _tag(String t) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.75),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(t,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
      );

  Widget _conditionsCard(IrrigationSettings s) {
    return _section(
      icon: Icons.tune,
      color: _leaf,
      title: 'Условия на участке',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('ТИП ПОЧВЫ',
              style: TextStyle(
                  fontSize: 10.5,
                  letterSpacing: 1,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[600])),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: SoilType.values.map((t) {
              final sel = s.soil == t;
              return ChoiceChip(
                label: Text(kSoils[t]!.short,
                    style: const TextStyle(fontSize: 12.5)),
                selected: sel,
                selectedColor: _soilC,
                backgroundColor: Colors.white,
                labelStyle: TextStyle(
                    color: sel ? Colors.white : Colors.grey[800],
                    fontWeight: FontWeight.w600),
                side: BorderSide(
                    color: sel ? _soilC : Colors.grey.withValues(alpha: 0.3)),
                onSelected: (_) => s.setSoil(t),
              );
            }).toList(),
          ),
          const SizedBox(height: 14),
          Text('ПОГОДА СЕГОДНЯ',
              style: TextStyle(
                  fontSize: 10.5,
                  letterSpacing: 1,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[600])),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: WeatherPreset.values.map((w) {
              final sel = s.weather == w;
              return ChoiceChip(
                label: Text(kWeatherPresets[w]!.label,
                    style: const TextStyle(fontSize: 12)),
                selected: sel,
                selectedColor: _sun,
                backgroundColor: Colors.white,
                labelStyle: TextStyle(
                    color: sel ? Colors.white : Colors.grey[800],
                    fontWeight: FontWeight.w600),
                side: BorderSide(
                    color: sel ? _sun : Colors.grey.withValues(alpha: 0.3)),
                onSelected: (_) => s.setWeather(w),
              );
            }).toList(),
          ),
          const SizedBox(height: 6),
          SwitchListTile(
            value: s.mulched,
            onChanged: (v) => s.setMulched(v),
            activeThumbColor: Colors.green,
            contentPadding: EdgeInsets.zero,
            title: const Text('Грядка замульчирована',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            subtitle: Text('Испарение ниже на 20%',
                style: TextStyle(fontSize: 12, color: Colors.grey[600])),
          ),
          SwitchListTile(
            value: s.rainToday,
            onChanged: (v) => s.setRainToday(v),
            activeThumbColor: Colors.green,
            contentPadding: EdgeInsets.zero,
            title: const Text('Прошёл хороший дождь',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            subtitle: Text('Учитывается только сегодня',
                style: TextStyle(fontSize: 12, color: Colors.grey[600])),
          ),
          Text(
            'Погоду вы задаёте вручную. В следующем обновлении она будет '
            'подставляться автоматически по прогнозу для ваших координат.',
            style:
                TextStyle(fontSize: 11.5, color: Colors.grey[600], height: 1.4),
          ),
        ],
      ),
    );
  }

  Widget _trackerCard(CropCare care, bool due, int? days, int gap) {
    final color = _lastWater == null
        ? Colors.grey
        : due
            ? const Color(0xFFE65100)
            : _leaf;
    final inSeason = DateTime.now().month >= 4 && DateTime.now().month <= 9;
    return _section(
      icon: Icons.water_drop,
      color: _water,
      title: 'Трекер полива',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(WateringLog.sinceText(_lastWater),
                    style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: color)),
              ),
              if (days != null)
                Text('$days дн.',
                    style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: color)),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              _lastWater == null
                  ? 'Отметьте первый полив — начнём считать интервал.'
                  : due
                      ? '💧 Пора полить: ${care.waterAmount}.'
                      : '✅ Всё хорошо. Следующий полив через ${gap - days!} дн.',
              style: TextStyle(
                  fontSize: 13, color: color, fontWeight: FontWeight.w600),
            ),
          ),
          if (!inSeason) ...[
            const SizedBox(height: 8),
            Text(
              'Сейчас межсезонье: расчёт актуален для теплицы, рассады и зимнего сада.',
              style: TextStyle(fontSize: 11.5, color: Colors.grey[600]),
            ),
          ],
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 46,
            child: ElevatedButton.icon(
              onPressed: _markWatered,
              icon: const Icon(Icons.check),
              label: const Text('Отметить полив сегодня',
                  style: TextStyle(fontSize: 15)),
              style: ElevatedButton.styleFrom(
                backgroundColor: _water,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(13)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _section({
    required IconData icon,
    required Color color,
    required String title,
    required Widget child,
    Widget? trailing,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.25)),
        boxShadow: [
          BoxShadow(
              color: color.withValues(alpha: 0.08),
              blurRadius: 10,
              offset: const Offset(0, 3)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 22),
              const SizedBox(width: 8),
              Expanded(
                child: Text(title,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold)),
              ),
              if (trailing != null) trailing,
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}
