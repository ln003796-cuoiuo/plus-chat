import 'dart:async';
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/chat.dart';
import '../widgets/chat_tile.dart';
import 'chat_screen.dart';

class SearchChatsScreen extends StatefulWidget {
  const SearchChatsScreen({super.key});

  @override
  State<SearchChatsScreen> createState() => _SearchChatsScreenState();
}

class _SearchChatsScreenState extends State<SearchChatsScreen> {
  final _controller = TextEditingController();
  List<Chat> _allChats = [];
  List<Chat> _filteredChats = [];
  bool _loading = true;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _loadChats();
  }

  Future<void> _loadChats() async {
    setState(() => _loading = true);
    try {
      final chats = await ApiService.getChats();
      if (mounted) {
        setState(() {
          _allChats = chats;
          _filteredChats = chats;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      _filter(value);
    });
  }

  void _filter(String query) {
    if (query.trim().isEmpty) {
      setState(() => _filteredChats = _allChats);
      return;
    }

    final q = query.toLowerCase();
    setState(() {
      _filteredChats = _allChats.where((chat) {
        // ✅ Ищем по названию, имени собеседника, username, последнему сообщению
        final title = (chat.title ?? '').toLowerCase();
        final companionName = (chat.companionName ?? '').toLowerCase();
        final companionUsername = (chat.companionUsername ?? '').toLowerCase();
        final displayName = chat.displayName.toLowerCase();
        final lastMessage = (chat.lastMessage ?? '').toLowerCase();

        return title.contains(q) ||
            companionName.contains(q) ||
            companionUsername.contains(q) ||
            displayName.contains(q) ||
            lastMessage.contains(q);
      }).toList();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // ✅ Обычный Scaffold со стрелкой назад
    return Scaffold(
      appBar: AppBar(
        title: const Text('Поиск чатов'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _controller,
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                hintText: 'Поиск по названию или сообщениям...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _controller.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _controller.clear();
                          setState(() => _filteredChats = _allChats);
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey[200],
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                autofocus: true,
              ),
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _filteredChats.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.search_off,
                                size: 64, color: Colors.grey[400]),
                            const SizedBox(height: 16),
                            Text(
                              _controller.text.isEmpty
                                  ? 'У вас пока нет чатов'
                                  : 'Ничего не найдено',
                              style: TextStyle(
                                  color: Colors.grey[600], fontSize: 16),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: _filteredChats.length,
                        itemBuilder: (context, index) {
                          final chat = _filteredChats[index];
                          return ChatTile(
                            chat: chat,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => ChatScreen(chat: chat),
                                ),
                              );
                            },
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}