import 'dart:async';
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/user.dart';

class CreateChatScreen extends StatefulWidget {
  const CreateChatScreen({super.key});

  @override
  State<CreateChatScreen> createState() => _CreateChatScreenState();
}

class _CreateChatScreenState extends State<CreateChatScreen> {
  String _type = 'private';
  final _titleController = TextEditingController();
  final _searchController = TextEditingController();
  List<User> _searchResults = [];
  List<User> _selectedMembers = [];
  bool _isPublic = false;
  bool _searching = false;
  Timer? _debounce;

  @override
  void dispose() {
    _titleController.dispose();
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      _searchUsers(query);
    });
  }

  Future<void> _searchUsers(String query) async {
    if (query.trim().length < 2) {
      setState(() => _searchResults = []);
      return;
    }

    setState(() => _searching = true);
    try {
      final users = await ApiService.searchUsers(
        query: query.trim(),
        type: 'all',
        limit: 20,
      );
      if (mounted) {
        setState(() {
          _searchResults = users;
          _searching = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _searching = false);
    }
  }

  void _toggleMember(User user) {
    if (_type == 'private') {
      // Для ЛС — только один
      setState(() {
        if (_selectedMembers.any((u) => u.id == user.id)) {
          _selectedMembers.removeWhere((u) => u.id == user.id);
        } else {
          _selectedMembers = [user];
        }
      });
    } else {
      setState(() {
        if (_selectedMembers.any((u) => u.id == user.id)) {
          _selectedMembers.removeWhere((u) => u.id == user.id);
        } else {
          _selectedMembers.add(user);
        }
      });
    }
  }

  Future<void> _create() async {
    if (_selectedMembers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Выберите собеседника')),
      );
      return;
    }

    try {
      if (_type == 'private') {
        final res = await ApiService.createChat(
          type: 'private',
          members: [_selectedMembers.first.id],
        );
        if (res['success'] == true && mounted) {
          Navigator.pop(context, res['chat_id']);
        } else if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(res['error'] ?? 'Ошибка')),
          );
        }
      } else {
        if (_titleController.text.trim().isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Укажите название')),
          );
          return;
        }

        final res = await ApiService.createChat(
          type: _type,
          title: _titleController.text.trim(),
          isPublic: _isPublic,
          members: _selectedMembers.map((u) => u.id).toList(),
        );
        if (res['success'] == true && mounted) {
          Navigator.pop(context, res['chat_id']);
        } else if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(res['error'] ?? 'Ошибка')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Новый чат'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          TextButton(
            onPressed: _create,
            child: const Text(
              'Создать',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Выбор типа
          Padding(
            padding: const EdgeInsets.all(16),
            child: SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'private', label: Text('Личный')),
                ButtonSegment(value: 'group', label: Text('Группа')),
                ButtonSegment(value: 'channel', label: Text('Канал')),
              ],
              selected: {_type},
              onSelectionChanged: (set) {
                setState(() => _type = set.first);
              },
            ),
          ),
          // Название (для группы/канала)
          if (_type != 'private')
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Название',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
          // Поиск пользователей
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                hintText: 'Поиск пользователей...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey[200],
              ),
            ),
          ),
          // Выбранные участники
          if (_selectedMembers.isNotEmpty)
            Container(
              height: 60,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _selectedMembers.length,
                itemBuilder: (context, index) {
                  final user = _selectedMembers[index];
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: GestureDetector(
                      onTap: () => _toggleMember(user),
                      child: Stack(
                        children: [
                          CircleAvatar(
                            backgroundImage: user.avatarUrl != null
                                ? NetworkImage(user.avatarUrl!)
                                : null,
                            child: user.avatarUrl == null
                                ? Text(user.firstName.isNotEmpty
                                    ? user.firstName[0].toUpperCase()
                                    : '?')
                                : null,
                          ),
                          Positioned(
                            right: 0,
                            top: 0,
                            child: Container(
                              padding: const EdgeInsets.all(2),
                              decoration: const BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.close,
                                  size: 12, color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          const Divider(),
          // Результаты поиска
          Expanded(
            child: _searching
                ? const Center(child: CircularProgressIndicator())
                : _searchResults.isEmpty
                    ? Center(
                        child: Text(
                          _type == 'private'
                              ? 'Найдите пользователя по имени'
                              : 'Добавьте участников',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      )
                    : ListView.builder(
                        itemCount: _searchResults.length,
                        itemBuilder: (context, index) {
                          final user = _searchResults[index];
                          final isSelected =
                              _selectedMembers.any((u) => u.id == user.id);

                          return ListTile(
                            leading: CircleAvatar(
                              backgroundImage: user.avatarUrl != null
                                  ? NetworkImage(user.avatarUrl!)
                                  : null,
                              child: user.avatarUrl == null
                                  ? Text(user.firstName.isNotEmpty
                                      ? user.firstName[0].toUpperCase()
                                      : '?')
                                  : null,
                            ),
                            title:
                                Text('${user.firstName} ${user.lastName}'.trim()),
                            subtitle: Text('@${user.username}'),
                            trailing: isSelected
                                ? const Icon(Icons.check_circle,
                                    color: Colors.teal)
                                : null,
                            onTap: () => _toggleMember(user),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}