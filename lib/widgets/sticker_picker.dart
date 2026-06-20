import 'package:flutter/material.dart';
import '../services/api_service.dart';

class StickerPicker extends StatefulWidget {
  final Function(Map<String, dynamic> sticker, int packId) onStickerSelected;

  const StickerPicker({super.key, required this.onStickerSelected});

  @override
  State<StickerPicker> createState() => _StickerPickerState();
}

class _StickerPickerState extends State<StickerPicker>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Map<String, dynamic>> _installedPacks = [];
  List<Map<String, dynamic>> _allPacks = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    try {
      final installed = await ApiService.getInstalledPacks();
      final all = await ApiService.getStickerPacks();
      if (mounted) {
        setState(() {
          _installedPacks = installed;
          _allPacks = all;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка загрузки: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 400,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Заголовок
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Theme.of(context).dividerColor),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.emoji_emotions, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Стикеры',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),

          // Вкладки
          TabBar(
            controller: _tabController,
            tabs: const [
              Tab(text: 'Мои'),
              Tab(text: 'Все'),
            ],
          ),

          // Контент
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : TabBarView(
                    controller: _tabController,
                    children: [
                      _buildPacksList(_installedPacks),
                      _buildPacksList(_allPacks),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildPacksList(List<Map<String, dynamic>> packs) {
    if (packs.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.emoji_emotions_outlined,
                size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'Нет доступных паков',
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

        return Container(
          margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Название пака
              Row(
                children: [
                  Text(
                    pack['name'] as String? ?? 'Пак',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  if (pack['is_installed'] == true)
                    const Icon(Icons.check_circle,
                        color: Colors.green, size: 20),
                ],
              ),
              const SizedBox(height: 8),

              // Стикеры
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: (stickers as List).map((sticker) {
                  return GestureDetector(
                    onTap: () {
                      widget.onStickerSelected(
                        sticker as Map<String, dynamic>,
                        packId,
                      );
                      Navigator.pop(context);
                    },
                    child: Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                      child: Image.network(
                        sticker['file_url'] as String? ?? '',
                        fit: BoxFit.contain,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        );
      },
    );
  }
}