import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/chat.dart';

class ChatInfoScreen extends StatefulWidget {
  final Chat chat;
  const ChatInfoScreen({super.key, required this.chat});

  @override
  State<ChatInfoScreen> createState() => _ChatInfoScreenState();
}

class _ChatInfoScreenState extends State<ChatInfoScreen> {
  List<Map<String, dynamic>> _members = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadMembers();
  }

  Future<void> _loadMembers() async {
    try {
      final members = await ApiService.getChatMembers(widget.chat.id);
      if (mounted) {
        setState(() {
          _members = members;
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
        title: const Text('Информация'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              children: [
                // Шапка
                Container(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 50,
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        backgroundImage: widget.chat.avatarUrl != null
                            ? NetworkImage(widget.chat.avatarUrl!)
                            : null,
                        child: widget.chat.avatarUrl == null
                            ? Text(
                                widget.chat.initial,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 40,
                                  fontWeight: FontWeight.bold,
                                ),
                              )
                            : null,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        widget.chat.displayName,
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${widget.chat.type.label} · ${widget.chat.membersCount} участников',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                      if (widget.chat.description != null && widget.chat.description!.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        Text(
                          widget.chat.description!,
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey[700]),
                        ),
                      ],
                    ],
                  ),
                ),
                const Divider(),

                // Участники
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'Участники (${_members.length})',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
                ..._members.map((m) => ListTile(
                      leading: CircleAvatar(
                        backgroundImage: m['avatar_url'] != null ? NetworkImage(m['avatar_url']) : null,
                        child: m['avatar_url'] == null
                            ? Text((m['first_name'] ?? '?')[0].toUpperCase())
                            : null,
                      ),
                      title: Text('${m['first_name'] ?? ''} ${m['last_name'] ?? ''}'),
                      subtitle: Text('@${m['username'] ?? ''}'),
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: _roleColor(m['role'] ?? ''),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          _roleLabel(m['role'] ?? ''),
                          style: const TextStyle(color: Colors.white, fontSize: 11),
                        ),
                      ),
                    )),
                const Divider(),

                // Действия
                if (widget.chat.type != ChatType.private)
                  ListTile(
                    leading: const Icon(Icons.person_add),
                    title: const Text('Добавить участников'),
                    onTap: () {
                      // TODO
                    },
                  ),
                ListTile(
                  leading: Icon(widget.chat.isMuted ? Icons.notifications : Icons.notifications_off),
                  title: Text(widget.chat.isMuted ? 'Включить звук' : 'Выключить звук'),
                  onTap: () async {
                    if (widget.chat.isMuted) {
                      await ApiService.unmuteChat(widget.chat.id);
                    } else {
                      await ApiService.muteChat(widget.chat.id);
                    }
                    if (mounted) Navigator.pop(context, true);
                  },
                ),
                ListTile(
                  leading: Icon(widget.chat.isFavorite ? Icons.star_border : Icons.star),
                  title: Text(widget.chat.isFavorite ? 'Убрать из избранного' : 'В избранное'),
                  onTap: () async {
                    if (widget.chat.isFavorite) {
                      await ApiService.unfavoriteChat(widget.chat.id);
                    } else {
                      await ApiService.favoriteChat(widget.chat.id);
                    }
                    if (mounted) Navigator.pop(context, true);
                  },
                ),
                ListTile(
                  leading: Icon(widget.chat.isArchived ? Icons.unarchive : Icons.archive),
                  title: Text(widget.chat.isArchived ? 'Разархивировать' : 'В архив'),
                  onTap: () async {
                    if (widget.chat.isArchived) {
                      await ApiService.unarchiveChat(widget.chat.id);
                    } else {
                      await ApiService.archiveChat(widget.chat.id);
                    }
                    if (mounted) Navigator.pop(context, true);
                  },
                ),
                const Divider(),

                // Опасные действия
                if (widget.chat.myRole == 'owner' && widget.chat.type != ChatType.private)
                  ListTile(
                    leading: const Icon(Icons.delete, color: Colors.red),
                    title: const Text('Удалить чат', style: TextStyle(color: Colors.red)),
                    onTap: () async {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('Удалить чат?'),
                          content: const Text('Все сообщения будут удалены навсегда'),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Отмена')),
                            TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Удалить')),
                          ],
                        ),
                      );
                      if (confirm == true) {
                        await ApiService.deleteChat(widget.chat.id);
                        if (mounted) {
                          Navigator.pop(context);
                          Navigator.pop(context);
                        }
                      }
                    },
                  ),
                if (widget.chat.myRole != 'owner' || widget.chat.type == ChatType.private)
                  ListTile(
                    leading: const Icon(Icons.exit_to_app, color: Colors.red),
                    title: const Text('Покинуть чат', style: TextStyle(color: Colors.red)),
                    onTap: () async {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('Покинуть чат?'),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Отмена')),
                            TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Покинуть')),
                          ],
                        ),
                      );
                      if (confirm == true) {
                        await ApiService.leaveChat(widget.chat.id);
                        if (mounted) {
                          Navigator.pop(context);
                          Navigator.pop(context);
                        }
                      }
                    },
                  ),
              ],
            ),
    );
  }

  Color _roleColor(String role) {
    switch (role) {
      case 'owner':
        return Colors.red;
      case 'admin':
        return Colors.orange;
      case 'moderator':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  String _roleLabel(String role) {
    switch (role) {
      case 'owner':
        return 'Владелец';
      case 'admin':
        return 'Админ';
      case 'moderator':
        return 'Модератор';
      default:
        return 'Участник';
    }
  }
}