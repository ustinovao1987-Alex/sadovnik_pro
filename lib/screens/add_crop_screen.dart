import 'package:flutter/material.dart';

import '../data/crops_data.dart';
import '../data/garden_store.dart';

class AddCropScreen extends StatefulWidget {
  final int initialTab;
  const AddCropScreen({super.key, this.initialTab = 0});

  @override
  State<AddCropScreen> createState() => _AddCropScreenState();
}

class _AddCropScreenState extends State<AddCropScreen>
    with SingleTickerProviderStateMixin {
  static const Color _leaf = Color(0xFF2E7D32);
  static const Color _sprout = Color(0xFF66BB6A);
  static const Color _sun = Color(0xFFFFB300);
  static const Color _berry = Color(0xFFC62828);
  static const Color _cream = Color(0xFFF7F5EF);

  late final TabController _tabs;
  final TextEditingController _search = TextEditingController();
  String _query = '';
  int _filter = 0;

  @override
  void initState() {
    super.initState();
    _tabs =
        TabController(length: 2, vsync: this, initialIndex: widget.initialTab);
    GardenStore.instance.addListener(_onStore);
  }

  void _onStore() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    GardenStore.instance.removeListener(_onStore);
    _tabs.dispose();
    _search.dispose();
    super.dispose();
  }

  Future<void> _add(Crop crop) async {
    await GardenStore.instance.addCrop(crop.name);
    if (!mounted) return;
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: _leaf,
        duration: const Duration(seconds: 2),
        content: Text('${crop.emoji} ${crop.name} — в вашем саду'),
        action: SnackBarAction(
          label: 'Отменить',
          textColor: _sun,
          onPressed: () => GardenStore.instance.removeCrop(cropIdOf(crop.name)),
        ),
      ),
    );
  }

  Future<void> _remove(Crop crop) async {
    final store = GardenStore.instance;
    final index = store.cropIds.indexOf(cropIdOf(crop.name));
    await store.removeCrop(cropIdOf(crop.name));
    if (!mounted) return;
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: _berry,
        content: Text('${crop.name} убрана из сада'),
        action: SnackBarAction(
          label: 'Вернуть',
          textColor: _sun,
          onPressed: () =>
              store.insertCrop(index < 0 ? 0 : index, cropIdOf(crop.name)),
        ),
      ),
    );
  }

  Future<void> _clearAll() async {
    final store = GardenStore.instance;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text('Начать новый набор?'),
        content:
            const Text('Список культур очистится — удобно перед новым сезоном. '
                'Дневник и весь урожай прошлых лет сохранятся.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Отмена')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: _berry, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Очистить сад'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    final snapshot = await store.clearGarden();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: _berry,
        duration: const Duration(seconds: 5),
        content: const Text('Сад очищен. Дневник сохранён.'),
        action: SnackBarAction(
          label: 'Вернуть',
          textColor: _sun,
          onPressed: () => store.restoreGarden(snapshot),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final store = GardenStore.instance;
    return Scaffold(
      backgroundColor: _cream,
      appBar: AppBar(
        backgroundColor: _leaf,
        foregroundColor: Colors.white,
        title: const Text('Мой сад',
            style: TextStyle(fontWeight: FontWeight.bold)),
        bottom: TabBar(
          controller: _tabs,
          indicatorColor: _sun,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          tabs: [
            const Tab(text: 'Каталог культур'),
            Tab(text: 'В саду (${store.count})'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: [_catalogTab(), _gardenTab()],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.07),
                blurRadius: 12,
                offset: const Offset(0, -3)),
          ],
        ),
        child: SafeArea(
          top: false,
          child: SizedBox(
            height: 50,
            child: ElevatedButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.check),
              label: Text('Готово • ${store.count} культур в саду',
                  style: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: _leaf,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _catalogTab() {
    final store = GardenStore.instance;
    final items = availableCrops.where((c) {
      final id = cropIdOf(c.name);
      if (_query.isNotEmpty &&
          !c.name.toLowerCase().contains(_query) &&
          !c.description.toLowerCase().contains(_query)) {
        return false;
      }
      if (_filter == 1) return !store.has(id);
      if (_filter == 2) return store.has(id);
      return true;
    }).toList();

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [_leaf, Color(0xFF3E8E43), _sprout],
            ),
          ),
          child: Column(
            children: [
              TextField(
                controller: _search,
                onChanged: (v) => setState(() {
                  _query = v.trim().toLowerCase();
                }),
                style: const TextStyle(fontSize: 15),
                decoration: InputDecoration(
                  hintText: 'Начните вводить: помидоры, огурцы…',
                  prefixIcon: const Icon(Icons.search, color: _leaf),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: EdgeInsets.zero,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
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
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  _filterChip(0, 'Все'),
                  const SizedBox(width: 8),
                  _filterChip(1, 'Ещё не в саду'),
                  const SizedBox(width: 8),
                  _filterChip(2, 'Уже в саду'),
                ],
              ),
            ],
          ),
        ),
        Expanded(
          child: items.isEmpty
              ? _empty(
                  Icons.search_off,
                  'Ничего не найдено.\nПопробуйте написать короче — «помид», «огур».',
                )
              : Scrollbar(
                  thickness: 6,
                  radius: const Radius.circular(3),
                  thumbVisibility: true,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: items.length,
                    itemBuilder: (_, i) => _catalogTile(items[i]),
                  ),
                ),
        ),
      ],
    );
  }

  Widget _catalogTile(Crop crop) {
    final store = GardenStore.instance;
    final added = store.has(cropIdOf(crop.name));
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
            color: added
                ? _leaf.withValues(alpha: 0.45)
                : Colors.grey.withValues(alpha: 0.22)),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: (added ? _leaf : _sprout).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Center(
                child: Text(crop.emoji, style: const TextStyle(fontSize: 25))),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(crop.name,
                    style: const TextStyle(
                        fontSize: 15.5, fontWeight: FontWeight.bold)),
                const SizedBox(height: 3),
                Text(
                  crop.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      fontSize: 12, color: Colors.grey[600], height: 1.3),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          added
              ? OutlinedButton.icon(
                  onPressed: () => _remove(crop),
                  icon: const Icon(Icons.check, size: 16, color: _leaf),
                  label: const Text('В саду',
                      style: TextStyle(fontSize: 12.5, color: _leaf)),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: _leaf),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(11)),
                  ),
                )
              : ElevatedButton.icon(
                  onPressed: () => _add(crop),
                  icon: const Icon(Icons.add, size: 17),
                  label:
                      const Text('Добавить', style: TextStyle(fontSize: 12.5)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _leaf,
                    foregroundColor: Colors.white,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(11)),
                  ),
                ),
        ],
      ),
    );
  }

  Widget _gardenTab() {
    final store = GardenStore.instance;
    final crops = store.crops;
    if (crops.isEmpty) {
      return _empty(
        Icons.yard_outlined,
        'В саду пока пусто.\nПерейдите в «Каталог культур» и добавьте то, что посадили в этом году.',
        action: TextButton.icon(
          onPressed: () => _tabs.animateTo(0),
          icon: const Icon(Icons.search),
          label: const Text('Открыть каталог'),
        ),
      );
    }
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Перетаскивайте за ручку — порядок сохранится на главном экране.',
                  style: TextStyle(
                      fontSize: 12.5, color: Colors.grey[600], height: 1.35),
                ),
              ),
              TextButton.icon(
                onPressed: _clearAll,
                icon: const Icon(Icons.delete_sweep, size: 18, color: _berry),
                label: const Text('Очистить',
                    style: TextStyle(color: _berry, fontSize: 13)),
              ),
            ],
          ),
        ),
        Expanded(
          child: ReorderableListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
            itemCount: crops.length,
            onReorderItem: (o, n) => store.reorder(o, n),
            itemBuilder: (_, i) {
              final crop = crops[i];
              return Container(
                key: ValueKey(cropIdOf(crop.name)),
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.fromLTRB(10, 10, 8, 10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: _leaf.withValues(alpha: 0.28)),
                ),
                child: Row(
                  children: [
                    ReorderableDragStartListener(
                      index: i,
                      child: Padding(
                        padding: const EdgeInsets.all(6),
                        child: Icon(Icons.drag_handle, color: Colors.grey[500]),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(crop.emoji, style: const TextStyle(fontSize: 26)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(crop.name,
                          style: const TextStyle(
                              fontSize: 15.5, fontWeight: FontWeight.w600)),
                    ),
                    IconButton(
                      tooltip: 'Убрать из сада',
                      onPressed: () => _remove(crop),
                      icon: const Icon(Icons.remove_circle_outline,
                          color: _berry),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _filterChip(int value, String label) {
    final selected = _filter == value;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() {
          _filter = value;
        }),
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 4),
          decoration: BoxDecoration(
            color:
                selected ? Colors.white : Colors.white.withValues(alpha: 0.18),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: selected ? Colors.white : Colors.white38),
          ),
          child: Text(label,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.bold,
                  color: selected ? _leaf : Colors.white)),
        ),
      ),
    );
  }

  Widget _empty(IconData icon, String text, {Widget? action}) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 56, color: _leaf.withValues(alpha: 0.4)),
            const SizedBox(height: 14),
            Text(text,
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 14.5, color: Colors.grey[700], height: 1.5)),
            if (action != null) ...[const SizedBox(height: 12), action],
          ],
        ),
      ),
    );
  }
}
