import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/user.dart';

class FriendsScreen extends StatefulWidget {
  const FriendsScreen({super.key});

  @override
  State<FriendsScreen> createState() => _FriendsScreenState();
}

class _FriendsScreenState extends State<FriendsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<User> _friends = [];
  List<User> _requests = [];
  List<User> _contacts = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    try {
      // TODO: Реализовать API для друзей
      // final friends = await ApiService.getFriends();
      // final requests = await ApiService.getFriendRequests();
      // final contacts = await ApiService.getContacts();
      setState(() {
        _friends = [];
        _requests = [];
        _contacts = [];
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Друзья'),
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
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Друзья'),
            Tab(text: 'Запросы'),
            Tab(text: 'Контакты'),
          ],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildFriendsList(),
                _buildRequestsList(),
                _buildContactsList(),
              ],
            ),
    );
  }

  Widget _buildFriendsList() {
    if (_friends.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_outline, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'У вас пока нет друзей',
              style: TextStyle(color: Colors.grey[600], fontSize: 16),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: _friends.length,
      itemBuilder: (context, index) {
        final friend = _friends[index];
        return ListTile(
          leading: CircleAvatar(
            backgroundImage: friend.avatarUrl != null
                ? NetworkImage(friend.avatarUrl!)
                : null,
            child: friend.avatarUrl == null
                ? Text(friend.firstName[0].toUpperCase())
                : null,
          ),
          title: Text('${friend.firstName} ${friend.lastName}'),
          subtitle: Text('@${friend.username}'),
          trailing: FilledButton.tonal(
            onPressed: () {
              // TODO: Открыть чат
            },
            child: const Text('Написать'),
          ),
        );
      },
    );
  }

  Widget _buildRequestsList() {
    if (_requests.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.mail_outline, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'Нет запросов в друзья',
              style: TextStyle(color: Colors.grey[600], fontSize: 16),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: _requests.length,
      itemBuilder: (context, index) {
        final request = _requests[index];
        return ListTile(
          leading: CircleAvatar(
            backgroundImage: request.avatarUrl != null
                ? NetworkImage(request.avatarUrl!)
                : null,
            child: request.avatarUrl == null
                ? Text(request.firstName[0].toUpperCase())
                : null,
          ),
          title: Text('${request.firstName} ${request.lastName}'),
          subtitle: Text('@${request.username}'),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.check, color: Colors.green),
                onPressed: () {
                  // TODO: Принять запрос
                },
              ),
              IconButton(
                icon: const Icon(Icons.close, color: Colors.red),
                onPressed: () {
                  // TODO: Отклонить запрос
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildContactsList() {
    if (_contacts.isEmpty) {
      return Center(
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
      );
    }

    return ListView.builder(
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
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}