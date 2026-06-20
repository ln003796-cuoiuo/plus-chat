import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/user.dart';
import '../widgets/user_tile.dart';

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

  @override
  void dispose() {
    _titleController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _searchUsers(String query) async {
    if (query.trim().length < 2) {
      setState(() => _searchResults = []);
      return;
    }
    setState(() => _searching = true);
    try {
      final users = await ApiService.searchUsers(query);
      if (mounted) {
        setState(() {
          _searchResults = users.where((u) => !_selectedMembers.any((s) => s.id == u.id)).toList();
          _searching = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _searching = false);
    }
  }

  void _toggleMember(User user) {
    setState(() {
      if (_selectedMembers.any((u) => u.id == user.id)) {
        _selectedMembers.removeWhere((u) => u.id == user.id);
      } else {
        _selectedMembers.add(user);
      }
    });
  }

  Future<void> _create() async {
    if (_type == 'private') {
      if (_selectedMembers.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Выберите собеседника')),
        );
        return;
      }
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
            child: const Text('Создать', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
      body: Column(
        children: [
          // Выбор типа
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(child: _typeChip('private', 'ЛС', Icons.person)),
                const SizedBox(width: 8),
                Expanded(child: _typeChip('group', 'Группа', Icons.group)),
                const SizedBox(width: 8),
                Expanded(child: _typeChip('channel', 'Канал', Icons.campaign)),
              ],
            ),
          ),
          const Divider(),

          // Название (для групп/каналов)
          if (_type != 'private')
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Название',
                  border: OutlineInputBorder(),
                ),
              ),
            ),

          // Публичный (для групп/каналов)
          if (_type != 'private')
            SwitchListTile(
              title: const Text('Публичный'),
              subtitle: const Text('Любой может найти и вступить'),
              value: _isPublic,
              onChanged: (v) => setState(() => _isPublic = v),
            ),

          const Divider(),

          // Поиск
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              onChanged: _searchUsers,
              decoration: InputDecoration(
                hintText: _type == 'private' ? 'Найти пользователя...' : 'Добавить участников...',
                prefixIcon: const Icon(Icons.search),
                border: const OutlineInputBorder(),
              ),
            ),
          ),

          // Выбранные участники
          if (_selectedMembers.isNotEmpty)
            Container(
              height: 80,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _selectedMembers.length,
                itemBuilder: (context, index) {
                  final user = _selectedMembers[index];
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Stack(
                      children: [
                        CircleAvatar(
                          backgroundImage: user.avatarUrl != null ? NetworkImage(user.avatarUrl!) : null,
                          child: user.avatarUrl == null ? Text(user.initial) : null,
                        ),
                        Positioned(
                          right: 0,
                          top: 0,
                          child: GestureDetector(
                            onTap: () => _toggleMember(user),
                            child: Container(
                              padding: const EdgeInsets.all(2),
                              decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                              child: const Icon(Icons.close, size: 12, color: Colors.white),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

          // Результаты поиска
          Expanded(
            child: _searching
                ? const Center(child: CircularProgressIndicator())
                : _searchResults.isEmpty
                    ? Center(
                        child: Text(
                          _type == 'private' ? 'Найдите пользователя по имени' : 'Добавьте участников',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      )
                    : ListView.builder(
                        itemCount: _searchResults.length,
                        itemBuilder: (context, index) {
                          final user = _searchResults[index];
                          final isSelected = _selectedMembers.any((u) => u.id == user.id);
                          return UserTile(
                            user: user,
                            onTap: () => _toggleMember(user),
                            trailing: isSelected
                                ? const Icon(Icons.check_circle, color: Colors.green)
                                : null,
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _typeChip(String type, String label, IconData icon) {
    final isSelected = _type == type;
    return GestureDetector(
      onTap: () => setState(() => _type = type),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? Theme.of(context).primaryColor.withOpacity(0.1) : Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? Theme.of(context).primaryColor : Colors.transparent,
            width: 2,
          ),
        ),
        child: Column(
          children: [
            Icon(icon, color: isSelected ? Theme.of(context).primaryColor : Colors.grey),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Theme.of(context).primaryColor : Colors.grey[700],
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}