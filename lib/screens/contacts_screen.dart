import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/user.dart';

class ContactsScreen extends StatefulWidget {
  const ContactsScreen({super.key});

  @override
  State<ContactsScreen> createState() => _ContactsScreenState();
}

class _ContactsScreenState extends State<ContactsScreen> {
  List<User> _contacts = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadContacts();
  }

  Future<void> _loadContacts() async {
    setState(() => _loading = true);
    try {
      // TODO: Реализовать API
      setState(() {
        _contacts = [];
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Контакты'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => Navigator.pushNamed(context, '/search'),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _contacts.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.contacts_outlined, size: 64, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text(
                        'Список контактов пуст',
                        style: TextStyle(color: Colors.grey[600], fontSize: 16),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  itemCount: _contacts.length,
                  itemBuilder: (context, index) {
                    final contact = _contacts[index];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundImage: contact.avatarUrl != null
                            ? NetworkImage(contact.avatarUrl!)
                            : null,
                        child: contact.avatarUrl == null
                            ? Text(contact.firstName[0].toUpperCase())
                            : null,
                      ),
                      title: Text('${contact.firstName} ${contact.lastName}'),
                      subtitle: Text('@${contact.username}'),
                      trailing: FilledButton.tonal(
                        onPressed: () {
                          // TODO: Открыть чат
                        },
                        child: const Text('Написать'),
                      ),
                    );
                  },
                ),
    );
  }
}