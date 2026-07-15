// lib/widgets/sticker_picker.dart
import 'package:flutter/material.dart';
import '../services/api_service.dart';

class StickerPicker extends StatefulWidget {
  final Function(Map<String, dynamic>, int) onStickerSelected;

  const StickerPicker({Key? key, required this.onStickerSelected}) : super(key: key);

  @override
  State<StickerPicker> createState() => _StickerPickerState();
}

class _StickerPickerState extends State<StickerPicker> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Map<String, dynamic>> _installedPacks = [];
  List<Map<String, dynamic>> _allPacks = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadStickerPacks();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadStickerPacks() async {
    try {
      final installedRes = await ApiService.getInstalledStickerPacks();
      final allRes = await ApiService.getStickers();

      if (mounted) {
        setState(() {
          _installedPacks = (installedRes['packs'] as List? ?? []).cast<Map<String, dynamic>>();
          _allPacks = (allRes['packs'] as List? ?? []).cast<Map<String, dynamic>>();
          _loading = false;
        });
      }
    } catch (e) {
      print('Ошибка загрузки паков стикеров: $e');
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      children: [
        TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Мои'),
            Tab(text: 'Все'),
          ],
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildPackList(_installedPacks, true),
              _buildPackList(_allPacks, false),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPackList(List<Map<String, dynamic>> packs, bool isInstalledList) {
    if (packs.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.sticky_note_2_outlined, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              isInstalledList ? 'Нет установленных паков' : 'Нет доступных паков',
              style: TextStyle(color: Colors.grey[600], fontSize: 16),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: packs.length,
      itemBuilder: (context, index) {
        final pack = packs[index];
        final packId = pack['id'] as int;
        final stickers = pack['stickers'] as List? ?? [];

        return Card(
          margin: const EdgeInsets.all(8),
          child: ExpansionTile(
            title: Text(pack['name'] ?? 'Пак ${packId}'),
            subtitle: Text('${stickers.length} стикеров'),
            children: [
              SizedBox(
                height: 100, // Высота сетки стикеров
                child: GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(), // Отключаем скролл внутри сетки
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 5, // Количество стикеров в строке
                    crossAxisSpacing: 4,
                    mainAxisSpacing: 4,
                  ),
                  itemCount: stickers.length,
                  itemBuilder: (context, stickerIndex) {
                    final sticker = stickers[stickerIndex];
                    return GestureDetector(
                      onTap: () => widget.onStickerSelected(sticker, packId),
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: Image.network(
                            sticker['file_url'],
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}