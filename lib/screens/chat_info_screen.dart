import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/chat.dart';
import '../widgets/app_scaffold.dart';

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
    return AppScaffold(
      title: 'Информация о чате',
      child: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              children: [
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
                        style: const TextStyle(
                            fontSize: 22, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        widget.chat.type == 'private'
                            ? 'Личный чат'
                            : widget.chat.type == 'group'
                                ? 'Группа'
                                : 'Канал',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
                const Divider(),
                if (widget.chat.description != null &&
                    widget.chat.description!.isNotEmpty)
                  ListTile(
                    leading: const Icon(Icons.description),
                    title: const Text('Описание'),
                    subtitle: Text(widget.chat.description!),
                  ),
                ListTile(
                  leading: const Icon(Icons.people),
                  title: const Text('Участники'),
                  subtitle: Text('${_members.length} человек'),
                ),
                const Divider(),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'Участники',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[700],
                    ),
                  ),
                ),
                ..._members.map((m) => ListTile(
                      leading: CircleAvatar(
                        backgroundImage: m['avatar_url'] != null
                            ? NetworkImage(m['avatar_url'])
                            : null,
                        child: m['avatar_url'] == null
                            ? Text(
                                (m['first_name'] ?? '?')[0].toUpperCase(),
                              )
                            : null,
                      ),
                      title: Text(
                          '${m['first_name'] ?? ''} ${m['last_name'] ?? ''}'.trim()),
                      subtitle: Text(
                          '@${m['username'] ?? ''} • ${m['role'] ?? 'member'}'),
                    )),
                const Divider(),
                if (widget.chat.type != 'private')
                  ListTile(
                    leading: const Icon(Icons.person_add),
                    title: const Text('Добавить участников'),
                    onTap: () {
                      // TODO: Добавить участников
                    },
                  ),
                ListTile(
                  leading: Icon(widget.chat.isMuted
                      ? Icons.notifications
                      : Icons.notifications_off),
                  title: Text(widget.chat.isMuted
                      ? 'Включить звук'
                      : 'Выключить звук'),
                  onTap: () async {
                    if (widget.chat.isMuted) {
                      await ApiService.unmuteChats([widget.chat.id]);
                    } else {
                      await ApiService.muteChats([widget.chat.id]);
                    }
                    if (mounted) Navigator.pop(context, true);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.archive_outlined),
                  title: const Text('В архив'),
                  onTap: () async {
                    await ApiService.archiveChats([widget.chat.id]);
                    if (mounted) {
                      Navigator.pop(context);
                      Navigator.pop(context);
                    }
                  },
                ),
                if (widget.chat.type != 'private')
                  ListTile(
                    leading: const Icon(Icons.exit_to_app, color: Colors.red),
                    title: const Text('Покинуть чат',
                        style: TextStyle(color: Colors.red)),
                    onTap: () async {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('Покинуть чат?'),
                          actions: [
                            TextButton(
                                onPressed: () => Navigator.pop(ctx, false),
                                child: const Text('Отмена')),
                            TextButton(
                                onPressed: () => Navigator.pop(ctx, true),
                                child: const Text('Покинуть')),
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
}