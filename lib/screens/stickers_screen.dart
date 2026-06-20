import 'package:flutter/material.dart';
import '../services/api_service.dart';

class StickersScreen extends StatefulWidget {
  const StickersScreen({super.key});

  @override
  State<StickersScreen> createState() => _StickersScreenState();
}

class _StickersScreenState extends State<StickersScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Map<String, dynamic>> _installed = [];
  List<Map<String, dynamic>> _all = [];
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
          _installed = installed;
          _all = all;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _togglePack(int packId, bool isInstalled) async {
    if (isInstalled) {
      await ApiService.uninstallPack(packId);
    } else {
      await ApiService.installPack(packId);
    }
    _loadData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Стикеры'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Мои'),
            Tab(text: 'Все'),
          ],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [_buildPacks(_installed, true), _buildPacks(_all, false)],
            ),
    );
  }

  Widget _buildPacks(List<Map<String, dynamic>> packs, bool isInstalledList) {
    if (packs.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.emoji_emotions_outlined, size: 64, color: Colors.grey[400]),
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
        final isInstalled = pack['is_installed'] == true;
        final stickers = pack['stickers'] as List? ?? [];

        return Card(
          margin: const EdgeInsets.all(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(pack['name'] ?? '', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          if (pack['description'] != null)
                            Text(pack['description'], style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                        ],
                      ),
                    ),
                    if (pack['is_premium'] == true)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(color: Colors.amber, borderRadius: BorderRadius.circular(12)),
                        child: const Text('⭐ Premium', style: TextStyle(color: Colors.white, fontSize: 11)),
                      ),
                    const SizedBox(width: 8),
                    FilledButton.tonal(
                      onPressed: () => _togglePack(packId, isInstalled),
                      child: Text(isInstalled ? 'Удалить' : 'Установить'),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: (stickers as List).map((s) {
                    return Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Image.network(s['file_url'] ?? '', fit: BoxFit.contain),
                    );
                  }).toList(),
                ),
              ],
            ),
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