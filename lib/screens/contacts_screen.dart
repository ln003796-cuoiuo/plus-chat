import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/user.dart';
import '../widgets/app_scaffold.dart';
import 'user_profile_screen.dart';

class ContactsScreen extends StatefulWidget {
  const ContactsScreen({super.key});

  @override
  State<ContactsScreen> createState() => _ContactsScreenState();
}

class _ContactsScreenState extends State<ContactsScreen> {
  List<User> _contacts = [];
  bool _loading = true;
  String _filter = 'all';

  @override
  void initState() {
    super.initState();
    _loadContacts();
  }

  Future<void> _loadContacts() async {
    setState(() => _loading = true);
    try {
      final contacts = await ApiService.getContacts(filter: _filter);
      if (mounted) {
        setState(() {
          _contacts = contacts;
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
      title: 'Контакты',
      actions: [
        PopupMenuButton<String>(
          onSelected: (value) {
            setState(() => _filter = value);
            _loadContacts();
          },
          itemBuilder: (ctx) => [
            const PopupMenuItem(value: 'all', child: Text('Все')),
            const PopupMenuItem(value: 'friends', child: Text('Только друзья')),
            const PopupMenuItem(value: 'favorite', child: Text('Избранные')),
            const PopupMenuItem(value: 'blocked', child: Text('Заблокированные')),
          ],
          child: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Icon(Icons.filter_list),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.search),
          onPressed: () => Navigator.pushNamed(context, '/search'),
        ),
      ],
      child: _loading
          ? const Center(child: CircularProgressIndicator())
          : _contacts.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.contacts_outlined,
                          size: 64, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text(
                        'Список контактов пуст',
                        style:
                            TextStyle(color: Colors.grey[600], fontSize: 16),
                      ),
                      const SizedBox(height: 16),
                      FilledButton.icon(
                        onPressed: () => Navigator.pushNamed(context, '/search'),
                        icon: const Icon(Icons.person_add),
                        label: const Text('Добавить контакт'),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  itemCount: _contacts.length,
                  itemBuilder: (context, index) {
                    final contact = _contacts[index];
                    return ListTile(
                      leading: Stack(
                        children: [
                          CircleAvatar(
                            backgroundImage: contact.avatarUrl != null
                                ? NetworkImage(contact.avatarUrl!)
                                : null,
                            child: contact.avatarUrl == null
                                ? Text(contact.initials)
                                : null,
                          ),
                          if (contact.isOnline)
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: Container(
                                width: 12,
                                height: 12,
                                decoration: BoxDecoration(
                                  color: Colors.green,
                                  shape: BoxShape.circle,
                                  border:
                                      Border.all(color: Colors.white, width: 2),
                                ),
                              ),
                            ),
                        ],
                      ),
                      title: Text(contact.displayName),
                      subtitle: Text(
                          '@${contact.username ?? 'username'}${contact.isOnline ? ' • В сети' : ''}'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (contact.isOnline)
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: Colors.green,
                                shape: BoxShape.circle,
                              ),
                            ),
                          const SizedBox(width: 8),
                          IconButton(
                            icon: const Icon(Icons.chat_bubble_outline),
                            onPressed: () async {
                              final result =
                                  await ApiService.findPrivateChat(contact.id);
                              if (result['success'] == true &&
                                  result['chat_id'] != null) {
                                // TODO: Открыть чат
                              }
                            },
                          ),
                        ],
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                UserProfileScreen(userId: contact.id),
                          ),
                        );
                      },
                    );
                  },
                ),
    );
  }
}