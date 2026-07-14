import 'dart:async';
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/user.dart';
import '../models/chat.dart';
import 'chat_screen.dart';

class CreateChatScreen extends StatefulWidget {
  const CreateChatScreen({super.key});

  @override
  State<CreateChatScreen> createState() => _CreateChatScreenState();
}

class _CreateChatScreenState extends State<CreateChatScreen> {
  String _type = 'private'; // private, group, channel
  final _titleController = TextEditingController();
  final _searchController = TextEditingController();
  List<User> _searchResults = [];
  List<User> _selectedMembers = [];
  bool _isPublic = false;
  bool _isHidden = false; // ✅ Скрытый чат
  bool _searching = false;
  bool _creating = false;
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
      final users = await ApiService.searchUsers(query.trim(), type: 'all');
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
    setState(() {
      if (_type == 'private') {
        // Для ЛС — только один собеседник
        if (_selectedMembers.any((u) => u.id == user.id)) {
          _selectedMembers.clear();
        } else {
          _selectedMembers = [user];
        }
      } else {
        // Для группы/канала — несколько
        if (_selectedMembers.any((u) => u.id == user.id)) {
          _selectedMembers.removeWhere((u) => u.id == user.id);
        } else {
          _selectedMembers.add(user);
        }
      }
    });
  }

  Future<void> _create() async {
    // Валидация
    if (_selectedMembers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Выберите хотя бы одного участника')),
      );
      return;
    }

    if (_type != 'private' && _titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Укажите название для группы/канала')),
      );
      return;
    }

    setState(() => _creating = true);

    try {
      final res = await ApiService.createChat(
        type: _type,
        title: _type == 'private' ? null : _titleController.text.trim(),
        isPublic: _isPublic,
        isHidden: _isHidden, // ✅ Передаём скрытый чат
        members: _selectedMembers.map((u) => u.id).toList(),
      );

      if (!mounted) return;

      if (res['success'] == true) {
        final chatData = res['chat'];
        final alreadyExists = res['already_exists'] == true;

        if (chatData != null) {
          final chat = Chat.fromJson(chatData);
          
          // Закрываем экран создания
          Navigator.pop(context);
          
          // Открываем чат
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => ChatScreen(chat: chat)),
          );

          // Показываем уведомление если чат уже существовал
          if (alreadyExists) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Открыт существующий чат')),
            );
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Чат создан, но данные не получены')),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(res['error'] ?? 'Ошибка создания чата'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _creating = false);
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
            onPressed: _creating ? null : _create,
            child: _creating
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text(
                    'Создать',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Переключатель типа чата
          Padding(
            padding: const EdgeInsets.all(16),
            child: SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'private', label: Text('ЛС')),
                ButtonSegment(value: 'group', label: Text('Группа')),
                ButtonSegment(value: 'channel', label: Text('Канал')),
              ],
              selected: {_type},
              onSelectionChanged: (set) {
                setState(() => _type = set.first);
              },
            ),
          ),

          // Название (только для группы/канала)
          if (_type != 'private')
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Название',
                  hintText: 'Введите название группы/канала',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.title),
                ),
                maxLength: 255,
              ),
            ),

          // Настройки для группы/канала
          if (_type != 'private') ...[
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Открытый чат'),
                    subtitle: const Text('Любой может найти и вступить'),
                    value: _isPublic,
                    onChanged: (v) => setState(() => _isPublic = v),
                    secondary: const Icon(Icons.public),
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Скрытый чат'),
                    subtitle: const Text('Не показывается в поиске'),
                    value: _isHidden,
                    onChanged: (v) => setState(() => _isHidden = v),
                    secondary: const Icon(Icons.visibility_off),
                  ),
                ],
              ),
            ),
          ],

          // Поиск пользователей
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                hintText: _type == 'private'
                    ? 'Найдите собеседника...'
                    : 'Добавьте участников...',
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

          // Выбранные участники (чипсы)
          if (_selectedMembers.isNotEmpty)
            Container(
              height: 70,
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
                          Column(
                            children: [
                              CircleAvatar(
                                radius: 24,
                                backgroundImage: user.avatarUrl != null
                                    ? NetworkImage(user.avatarUrl!)
                                    : null,
                                child: user.avatarUrl == null
                                    ? Text(user.initials)
                                    : null,
                              ),
                              const SizedBox(height: 4),
                              SizedBox(
                                width: 60,
                                child: Text(
                                  user.firstName,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(fontSize: 11),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
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
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.people_outline,
                                size: 64, color: Colors.grey[400]),
                            const SizedBox(height: 16),
                            Text(
                              _type == 'private'
                                  ? 'Найдите пользователя по имени или username'
                                  : 'Добавьте участников в группу',
                              style: TextStyle(color: Colors.grey[600]),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: _searchResults.length,
                        itemBuilder: (context, index) {
                          final user = _searchResults[index];
                          final isSelected =
                              _selectedMembers.any((u) => u.id == user.id);

                          return ListTile(
                            leading: Stack(
                              children: [
                                CircleAvatar(
                                  backgroundImage: user.avatarUrl != null
                                      ? NetworkImage(user.avatarUrl!)
                                      : null,
                                  child: user.avatarUrl == null
                                      ? Text(user.initials)
                                      : null,
                                ),
                                if (user.isOnline)
                                  Positioned(
                                    bottom: 0,
                                    right: 0,
                                    child: Container(
                                      width: 12,
                                      height: 12,
                                      decoration: BoxDecoration(
                                        color: Colors.green,
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                            color: Colors.white, width: 2),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            title: Text(user.displayName),
                            subtitle: Text('@${user.username ?? 'username'}'),
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