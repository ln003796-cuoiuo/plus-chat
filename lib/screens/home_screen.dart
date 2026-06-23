import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../models/user.dart';
import '../models/chat.dart';
import '../widgets/chat_tile.dart';
import 'chat_screen.dart';
import 'login_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  User? _currentUser;
  List<Chat> _chats = [];
  List<Chat> _archivedChats = [];
  bool _loading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _loading = true;
      _errorMessage = '';
    });
    try {
      final user = await ApiService.getMe();
      final chats = await ApiService.getChats();
      final archived = await ApiService.getChats(archived: true);
      if (mounted) {
        setState(() {
          _currentUser = user;
          _chats = chats;
          _archivedChats = archived;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _loading = false;
        });
      }
    }
  }

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Выход'),
        content: const Text('Вы уверены, что хотите выйти?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Выйти', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirm == true && mounted) {
      await AuthService.logout();
      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
      }
    }
  }

  void _showCreateChatDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Новый чат'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                labelText: 'ID пользователя',
                hintText: 'usr_...',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Введите ID пользователя для создания личного чата',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Отмена'),
          ),
          FilledButton(
            onPressed: () async {
              final id = controller.text.trim();
              if (id.isEmpty) return;
              Navigator.pop(ctx);
              final res = await ApiService.createChat(
                type: 'private',
                members: [id],
              );
              if (res['success'] == true) {
                await _loadData();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Чат создан')),
                  );
                }
              } else {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(res['error'] ?? 'Ошибка создания чата'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text('Создать'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Чаты'),
        centerTitle: true,
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              // TODO: Поиск чатов
            },
          ),
        ],
      ),
      drawer: _buildDrawer(),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage.isNotEmpty
              ? _buildErrorState()
              : _buildChatsList(),
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreateChatDialog,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: Colors.red),
          const SizedBox(height: 16),
          Text('Ошибка загрузки', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              _errorMessage,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600]),
            ),
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _loadData,
            child: const Text('Повторить'),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            // Шапка с аватаром
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Theme.of(context).colorScheme.primary,
                    Theme.of(context).colorScheme.primary.withOpacity(0.7),
                  ],
                ),
              ),
              child: Column(
                children: [
                 GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pushNamed(context, '/profile');
                    },
                    child: Stack(
                      children: [
                        CircleAvatar(
                          radius: 40,
                          backgroundColor: Colors.white,
                          backgroundImage: _currentUser?.avatarUrl != null
                              ? NetworkImage(_currentUser!.avatarUrl!)
                              : null,
                          child: _currentUser?.avatarUrl == null
                              ? Text(
                                  _currentUser?.initials ?? '?',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 32,
                                    fontWeight: FontWeight.bold,
                                  ),
                                )
                              : null,
                        ),
                        if (_currentUser?.isOnline ?? false)
                          Positioned(
                            bottom: 2,
                            right: 2,
                            child: Container(
                              width: 16,
                              height: 16,
                              decoration: BoxDecoration(
                                color: Colors.green,
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 2),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _currentUser?.displayName ?? 'Пользователь',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '@${_currentUser?.username ?? 'username'}',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withOpacity(0.8),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'В сети',
                       style: const TextStyle(
                         color: Colors.white,
                         fontSize: 12,
                         fontWeight: FontWeight.w500,
                       ),
                     ),
                   ),
                 ),
                  if (_currentUser?.isPremium ?? false) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.star, color: Colors.white, size: 14),
                          SizedBox(width: 4),
                          Text(
                            'Premium',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const Divider(),
            // Меню
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 8),
                children: [
                  ListTile(
                    leading: const Icon(Icons.chat_bubble_outline),
                    title: const Text('Чаты'),
                    onTap: () => Navigator.pop(context),
                  ),
                  ListTile(
                    leading: const Icon(Icons.contacts_outlined),
                    title: const Text('Контакты'),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pushNamed(context, '/contacts');
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.contacts_outlined),
                    title: const Text('Контакты'),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pushNamed(context, '/contacts');
                    },
                  ),
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.card_giftcard_outlined),
                    title: const Text('Подарки'),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pushNamed(context, '/gifts');
                    },
                  ),
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.settings_outlined),
                    title: const Text('Настройки'),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pushNamed(context, '/settings');
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.logout, color: Colors.red),
                    title: const Text('Выйти', style: TextStyle(color: Colors.red)),
                    onTap: () {
                      Navigator.pop(context);
                      _logout();
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChatsList() {
    return Column(
      children: [        
        // Архив
        if (_archivedChats.isNotEmpty)
          InkWell(
            onTap: () {
              Navigator.pushNamed(context, '/archived');
            },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                border: Border(
                  bottom: BorderSide(color: Colors.grey[300]!),
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.archive_outlined, size: 20, color: Colors.grey[700]),
                  const SizedBox(width: 12),
                  Text(
                    'Архив',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey[700],
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.grey[400],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${_archivedChats.length}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        // Список чатов
        Expanded(
          child: _chats.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.chat_bubble_outline, size: 80, color: Colors.grey),
                      SizedBox(height: 16),
                      Text('Пока нет чатов', style: TextStyle(fontSize: 18, color: Colors.grey)),
                      SizedBox(height: 8),
                      Text('Нажмите + чтобы начать общение', style: TextStyle(fontSize: 14, color: Colors.grey)),
                    ],
                  ),
                )
              : ListView.builder(
                  itemCount: _chats.length,
                  itemBuilder: (context, index) {
                    final chat = _chats[index];
                    return ChatTile(
                      chat: chat,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => ChatScreen(chat: chat)),
                        ).then((_) => _loadData());
                      },
                      onLongPress: () => _showChatOptions(chat),
                    );
                  },
                ),
        ),
      ],
    );
  }

  void _showChatOptions(Chat chat) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.archive_outlined),
              title: Text(chat.isArchived ? 'Разархивировать' : 'В архив'),
              onTap: () async {
                Navigator.pop(ctx);
                if (chat.isArchived) {
                  await ApiService.unarchiveChats([chat.id]);
                } else {
                  await ApiService.archiveChats([chat.id]);
                }
                _loadData();
              },
            ),
            ListTile(
              leading: Icon(chat.isMuted ? Icons.notifications : Icons.notifications_off),
              title: Text(chat.isMuted ? 'Включить звук' : 'Выключить звук'),
              onTap: () async {
                Navigator.pop(ctx);
                if (chat.isMuted) {
                  await ApiService.unmuteChats([chat.id]);
                } else {
                  await ApiService.muteChats([chat.id]);
                }
                _loadData();
              },
            ),
            ListTile(
              leading: Icon(chat.isFavorite ? Icons.star_border : Icons.star),
              title: Text(chat.isFavorite ? 'Убрать из избранного' : 'В избранное'),
              onTap: () async {
                Navigator.pop(ctx);
                if (chat.isFavorite) {
                  await ApiService.unfavoriteChats([chat.id]);
                } else {
                  await ApiService.favoriteChats([chat.id]);
                }
                _loadData();
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline, color: Colors.red),
              title: const Text('Удалить чат', style: TextStyle(color: Colors.red)),
              onTap: () async {
                Navigator.pop(ctx);
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Удалить чат?'),
                    content: const Text('Все сообщения будут удалены'),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Отмена')),
                      TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Удалить')),
                    ],
                  ),
                );
                if (confirm == true) {
                  await ApiService.deleteChat(chat.id);
                  _loadData();
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}