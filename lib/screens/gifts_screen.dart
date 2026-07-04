import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../widgets/app_scaffold.dart';

class GiftsScreen extends StatefulWidget {
  const GiftsScreen({super.key});

  @override
  State<GiftsScreen> createState() => _GiftsScreenState();
}

class _GiftsScreenState extends State<GiftsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Map<String, dynamic>> _received = [];
  List<Map<String, dynamic>> _sent = [];
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
      final received = await ApiService.getReceivedGifts();
      final sent = await ApiService.getSentGifts();
      if (mounted) {
        setState(() {
          _received = received;
          _sent = sent;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Подарки',
      bottom: TabBar(
        controller: _tabController,
        tabs: const [
          Tab(text: 'Полученные'),
          Tab(text: 'Отправленные'),
        ],
      ),
      child: _loading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildList(_received, true),
                _buildList(_sent, false),
              ],
            ),
    );
  }

  Widget _buildList(List<Map<String, dynamic>> gifts, bool isReceived) {
    if (gifts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isReceived ? Icons.card_giftcard : Icons.send,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              isReceived ? 'У вас пока нет подарков' : 'Вы ещё не отправляли подарков',
              style: TextStyle(color: Colors.grey[600], fontSize: 16),
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 0.85,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: gifts.length,
      itemBuilder: (context, index) {
        final gift = gifts[index];
        return _GiftCard(
          gift: gift,
          isReceived: isReceived,
        );
      },
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}

class _GiftCard extends StatelessWidget {
  final Map<String, dynamic> gift;
  final bool isReceived;

  const _GiftCard({required this.gift, required this.isReceived});

  @override
  Widget build(BuildContext context) {
    final senderName = gift['sender_name'] ?? gift['sender_first_name'] ?? 'Аноним';
    final receiverName = gift['receiver_name'] ?? gift['receiver_first_name'] ?? '';
    final imageUrl = gift['image_url'] ?? gift['animation_url'];
    final sentAt = gift['sent_at'] ?? gift['received_at'];

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              child: Container(
                color: Colors.grey[100],
                child: imageUrl != null
                    ? Image.network(
                        imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const Icon(
                          Icons.card_giftcard,
                          size: 40,
                          color: Colors.grey,
                        ),
                      )
                    : const Icon(
                        Icons.card_giftcard,
                        size: 40,
                        color: Colors.grey,
                      ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  gift['name'] ?? 'Подарок',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  isReceived ? 'От: $senderName' : 'Кому: $receiverName',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey[600],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (sentAt != null)
                  Text(
                    _formatDate(sentAt),
                    style: TextStyle(
                      fontSize: 9,
                      color: Colors.grey[500],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      return '${date.day}.${date.month}.${date.year}';
    } catch (_) {
      return '';
    }
  }
}