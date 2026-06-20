import 'package:flutter/material.dart';
import '../services/api_service.dart';

class GiftPicker extends StatefulWidget {
  final String receiverId;
  final Function(Map<String, dynamic> gift) onGiftSelected;

  const GiftPicker({
    super.key,
    required this.receiverId,
    required this.onGiftSelected,
  });

  @override
  State<GiftPicker> createState() => _GiftPickerState();
}

class _GiftPickerState extends State<GiftPicker> {
  List<Map<String, dynamic>> _gifts = [];
  List<Map<String, dynamic>> _categories = [];
  String? _selectedCategory;
  bool _loading = true;
  int _balance = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    try {
      final gifts = await ApiService.getGifts(category: _selectedCategory);
      final categories = await ApiService.getGiftCategories();
      final me = await ApiService.getMe();

      if (mounted) {
        setState(() {
          _gifts = gifts;
          _categories = categories;
          _balance = me?.plusCoins ?? 0;
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
  Widget build(BuildContext context) {
    return Container(
      height: 500,
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
                const Icon(Icons.card_giftcard, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Отправить подарок',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.amber,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('🪙', style: TextStyle(fontSize: 14)),
                      const SizedBox(width: 4),
                      Text(
                        '$_balance',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),

          // Категории
          if (_categories.isNotEmpty)
            Container(
              height: 50,
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _categories.length,
                itemBuilder: (context, index) {
                  final cat = _categories[index];
                  final isSelected = cat['id'] == _selectedCategory;
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: FilterChip(
                      label: Text(
                        '${cat['emoji']} ${cat['name']}',
                        style: TextStyle(fontSize: 12),
                      ),
                      selected: isSelected,
                      onSelected: (selected) {
                        setState(() {
                          _selectedCategory =
                              selected ? cat['id'] as String : null;
                        });
                        _loadData();
                      },
                    ),
                  );
                },
              ),
            ),

          // Список подарков
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _gifts.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.card_giftcard_outlined,
                                size: 64, color: Colors.grey[400]),
                            const SizedBox(height: 16),
                            Text(
                              'Нет доступных подарков',
                              style: TextStyle(
                                  color: Colors.grey[600], fontSize: 16),
                            ),
                          ],
                        ),
                      )
                    : GridView.builder(
                        padding: const EdgeInsets.all(16),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: 0.85,
                        ),
                        itemCount: _gifts.length,
                        itemBuilder: (context, index) {
                          final gift = _gifts[index];
                          final price = gift['price'] as int;
                          final canAfford = _balance >= price;

                          return GestureDetector(
                            onTap: canAfford
                                ? () {
                                    widget.onGiftSelected(gift);
                                    Navigator.pop(context);
                                  }
                                : null,
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: canAfford
                                    ? Colors.white
                                    : Colors.grey[200],
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: canAfford
                                      ? Theme.of(context).primaryColor
                                      : Colors.grey[400]!,
                                  width: 2,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Column(
                                children: [
                                  // Изображение
                                  Expanded(
                                    child: Image.network(
                                      gift['image_url'] as String? ?? '',
                                      fit: BoxFit.contain,
                                    ),
                                  ),
                                  const SizedBox(height: 8),

                                  // Название
                                  Text(
                                    gift['name'] as String? ?? 'Подарок',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),

                                  // Цена
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Text('🪙',
                                          style: TextStyle(fontSize: 12)),
                                      const SizedBox(width: 4),
                                      Text(
                                        '$price',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                          color: canAfford
                                              ? Colors.amber[700]
                                              : Colors.grey[600],
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}