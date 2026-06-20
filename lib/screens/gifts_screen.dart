import 'package:flutter/material.dart';
import '../services/api_service.dart';

class GiftsScreen extends StatefulWidget {
  const GiftsScreen({super.key});

  @override
  State<GiftsScreen> createState() => _GiftsScreenState();
}

class _GiftsScreenState extends State<GiftsScreen> with SingleTickerProviderStateMixin {
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Подарки'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Полученные'),
            Tab(text: 'Отправленные'),
          ],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [_buildList(_received, true), _buildList(_sent, false)],
            ),
    );
  }

  Widget _buildList(List<Map<String, dynamic>> gifts, bool isReceived) {
    if (gifts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.card_giftcard_outlined, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              isReceived ? 'Нет полученных подарков' : 'Нет отправленных подарков',
              style: TextStyle(color: Colors.grey[600], fontSize: 16),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: gifts.length,
      itemBuilder: (context, index) {
        final gift = gifts[index];
        final sender = gift['sender'] as Map<String, dynamic>?;
        final receiver = gift['receiver'] as Map<String, dynamic>?;
        final person = isReceived ? sender : receiver;
        final personName = person?['name'] ?? 'Аноним';

        return ListTile(
          leading: gift['image_url'] != null
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(gift['image_url'], width: 50, height: 50, fit: BoxFit.cover),
                )
              : const Icon(Icons.card_giftcard, size: 50),
          title: Text(gift['gift_name'] ?? 'Подарок'),
          subtitle: Text('${isReceived ? 'От' : 'Кому'}: $personName'),
          trailing: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(' ${gift['price_paid']}', style: const TextStyle(fontWeight: FontWeight.bold)),
              Text(
                gift['sent_at'] ?? '',
                style: TextStyle(fontSize: 11, color: Colors.grey[600]),
              ),
            ],
          ),
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