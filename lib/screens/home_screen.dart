import 'dart:async';
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../models/user.dart';
import '../models/chat.dart';
import '../widgets/chat_tile.dart';
import 'chat_screen.dart';
import 'login_screen.dart';
import 'create_chat_screen.dart';
import 'search_chats_screen.dart';
import 'user_profile_screen.dart';
import 'settings_screen.dart';
import 'friends_screen.dart';
import 'contacts_screen.dart';

class HomeScreen extends StatefulWidget {
  final String title;
  const HomeScreen({super.key, this.title = 'Чаты'});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Chat> _chats = [];
  List<Chat> _archivedChats = [];
  List<Chat> _favoriteChats = [];
  bool _loading = true;
  String? _errorMessage;
  Timer? _pollTimer;
  User? _currentUser;
  
  // Выделение чатов
  bool _isSelectionMode = false;
  Set<String> _selectedChatIds = {};

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
    _loadData();
    _startPolling();
  }

  Future<void> _loadCurrentUser() async {
    try {
      final user = await ApiService.getMe();
      if (mounted) setState(() => _currentUser = user);
    } catch (_) {}
  }

  Future<void> _loadData() async {
    try {
      setState(() {
        _loading = true;
        _errorMessage = null;
      });

      final results = await Future.wait([
        ApiService.getChats(archived: false, favorites: false),
        ApiService.getChats(archived: true),
        ApiService.getChats(favorites: true),
      ]);

      if (mounted) {
        setState(() {
          _chats = results[0];
          _archivedChats = results[1];
          _favoriteChats = results[2];
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

  void _startPolling() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 15), (_) {
      _loadData();
    });
  }

  // ============================================
  // ВЫДЕЛЕНИЕ ЧАТОВ
  // ============================================
  void _toggleChatSelection(String chatId) {
    setState(() {
      if (_selectedChatIds.contains(chatId)) {
        _selectedChatIds.remove(chatId);
      } else {
        _selectedChatIds.add(chatId);
      }
      
      if (_selectedChatIds.isEmpty) {
        _isSelectionMode = false;
      } else {
        _isSelectionMode = true;
      }
    });
  }

  void _exitSelectionMode() {
    setState(() {
      _isSelectionMode = false;
      _selectedChatIds.clear();
    });
  }

  // ============================================
  // ДЕЙСТВИЯ С ВЫДЕЛЕННЫМИ ЧАТАМИ
  // ============================================
  Future<void> _archiveSelected() async {
    await ApiService.archiveChats(_selectedChatIds.toList());
    _exitSelectionMode();
    _loadData();
  }

  Future<void> _muteSelected() async {
    await ApiService.muteChats(_selectedChatIds.toList());
    _exitSelectionMode();
    _loadData();
  }

  Future<void> _deleteSelected() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Удалить чаты?'),
        content: Text('Будет удалено чатов: ${_selectedChatIds.length}'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Удалить', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    
    if (confirm == true) {
      await ApiService.deleteChats(_selectedChatIds.toList());
      _exitSelectionMode();
      _loadData();
    }
  }

  // ============================================
  // МОДАЛКА АРХИВА
  // ============================================
  void _showArchivedModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) {
          return Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              children: [
                const SizedBox(height: 12),
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Row(
                    children: [
                      const Text(
                        'Архив',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '${_archivedChats.length}',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: _archivedChats.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.archive_outlined,
                                  size: 64, color: Colors.grey[400]),
                              const SizedBox(height: 16),
                              Text(
                                'Архив пуст',
                                style: TextStyle(
                                    color: Colors.grey[600], fontSize: 16),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          controller: scrollController,
                          itemCount: _archivedChats.length,
                          itemBuilder: (context, index) {
                            final chat = _archivedChats[index];
                            return Dismissible(
                              key: Key(chat.id),
                              direction: DismissDirection.endToStart,
                              background: Container(
                                color: Colors.orange,
                                alignment: Alignment.centerRight,
                                padding: const EdgeInsets.only(right: 20),
                                child: const Icon(Icons.unarchive,
                                    color: Colors.white),
                              ),
                              confirmDismiss: (_) async {
                                return await showDialog<bool>(
                                  context: context,
                                  builder: (ctx) => AlertDialog(
                                    title: const Text('Разархивировать?'),
                                    content: Text(
                                        'Чат "${chat.displayName}" будет возвращён в список'),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(ctx, false),
                                        child: const Text('Отмена'),
                                      ),
                                      FilledButton(
                                        onPressed: () => Navigator.pop(ctx, true),
                                        child: const Text('Разархивировать'),
                                      ),
                                    ],
                                  ),
                                );
                              },
                              onDismissed: (_) async {
                                await ApiService.unarchiveChats([chat.id]);
                                _loadData();
                              },
                              child: ChatTile(
                                chat: chat,
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => ChatScreen(chat: chat),
                                    ),
                                  );
                                },
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // ============================================
  // МОДАЛКА ИЗБРАННОГО
  // ============================================
  void _showFavoritesModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) {
          return Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              children: [
                const SizedBox(height: 12),
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Row(
                    children: [
                      const Text(
                        'Избранное',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '${_favoriteChats.length}',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: _favoriteChats.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.star_outline,
                                  size: 64, color: Colors.grey[400]),
                              const SizedBox(height: 16),
                              Text(
                                'Нет избранных чатов',
                                style: TextStyle(
                                    color: Colors.grey[600], fontSize: 16),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Добавьте чат в избранное через меню',
                                style: TextStyle(
                                    color: Colors.grey[500], fontSize: 13),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          controller: scrollController,
                          itemCount: _favoriteChats.length,
                          itemBuilder: (context, index) {
                            final chat = _favoriteChats[index];
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
        },
      ),
    );
  }

  // ============================================
  // МЕНЮ ЧАТА (долгое нажатие)
  // ============================================
  void _showChatOptions(Chat chat) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(
                chat.isFavorite ? Icons.star : Icons.star_outline,
                color: chat.isFavorite ? Colors.amber : null,
              ),
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
              leading: Icon(
                chat.isArchived ? Icons.unarchive : Icons.archive_outlined,
              ),
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
              leading: Icon(
                chat.isMuted ? Icons.notifications : Icons.notifications_off,
              ),
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
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: const Text('Отмена'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        child: const Text('Удалить', style: TextStyle(color: Colors.red)),
                      ),
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

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Выйти?'),
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

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: _isSelectionMode
            ? Text('Выбрано: ${_selectedChatIds.length}')
            : Text(widget.title),
        centerTitle: true,
        leading: _isSelectionMode
            ? IconButton(
                icon: const Icon(Icons.close),
                onPressed: _exitSelectionMode,
              )
            : Builder(
                builder: (context) => IconButton(
                  icon: const Icon(Icons.menu),
                  onPressed: () => Scaffold.of(context).openDrawer(),
                ),
              ),
        actions: _isSelectionMode
            ? [
                IconButton(
                  icon: const Icon(Icons.archive_outlined),
                  onPressed: _archiveSelected,
                ),
                IconButton(
                  icon: const Icon(Icons.notifications_off),
                  onPressed: _muteSelected,
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline),
                  onPressed: _deleteSelected,
                ),
              ]
            : [
                IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const SearchChatsScreen()),
                    ).then((_) => _loadData());
                  },
                ),
              ],
      ),
      drawer: _buildDrawer(),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, size: 64, color: Colors.red[400]),
                      const SizedBox(height: 16),
                      Text(
                        _errorMessage!,
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 24),
                      FilledButton(
                        onPressed: _loadData,
                        child: const Text('Повторить'),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    // Плитка "Избранное"
                    if (_favoriteChats.isNotEmpty)
                      InkWell(
                        onTap: _showFavoritesModal,
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: Colors.amber[50],
                            border: Border(
                              bottom: BorderSide(color: Colors.amber[200]!),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.star, size: 20, color: Colors.amber[700]),
                              const SizedBox(width: 12),
                              Text(
                                'Избранное',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.amber[900],
                                ),
                              ),
                              const Spacer(),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.amber[700],
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  '${_favoriteChats.length}',
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
                    // Плитка "Архив"
                    if (_archivedChats.isNotEmpty)
                      InkWell(
                        onTap: _showArchivedModal,
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            border: Border(
                              bottom: BorderSide(color: Colors.grey[300]!),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.archive_outlined,
                                  size: 20, color: Colors.grey[700]),
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
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.grey[600],
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
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.chat_bubble_outline,
                                      size: 64, color: Colors.grey[400]),
                                  const SizedBox(height: 16),
                                  Text(
                                    'Пока нет чатов',
                                    style: TextStyle(
                                        fontSize: 18, color: Colors.grey[600]),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Нажмите + чтобы начать общение',
                                    style: TextStyle(
                                        fontSize: 14, color: Colors.grey[500]),
                                  ),
                                ],
                              ),
                            )
                          : ListView.builder(
                              itemCount: _chats.length,
                              itemBuilder: (context, index) {
                                final chat = _chats[index];
                                final isSelected = _selectedChatIds.contains(chat.id);
                                
                                return ChatTile(
                                  chat: chat,
                                  isSelected: isSelected,
                                  onTap: () {
                                    if (_isSelectionMode) {
                                      _toggleChatSelection(chat.id);
                                    } else {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => ChatScreen(chat: chat),
                                        ),
                                      ).then((_) => _loadData());
                                    }
                                  },
                                  onLongPress: () {
                                    if (_isSelectionMode) {
                                      _toggleChatSelection(chat.id);
                                    } else {
                                      _toggleChatSelection(chat.id);
                                    }
                                  },
                                );
                              },
                            ),
                    ),
                  ],
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CreateChatScreen()),
          ).then((_) => _loadData());
        },
        backgroundColor: const Color(0xFF075E54),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
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
                                    color: Colors.black54,
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
                ],
              ),
            ),
            const Divider(),
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
                    leading: const Icon(Icons.people_outline),
                    title: const Text('Друзья'),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pushNamed(context, '/friends');
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
}