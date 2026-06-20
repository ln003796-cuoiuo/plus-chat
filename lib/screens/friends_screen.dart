import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/user.dart';
import '../widgets/user_tile.dart';
import 'user_profile_screen.dart';

class FriendsScreen extends StatefulWidget {
  const FriendsScreen({super.key});

  @override
  State<FriendsScreen> createState() => _FriendsScreenState();
}

class _FriendsScreenState extends State<FriendsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<User> _friends = [];
  List<User> _incomingRequests = [];
  List<User> _outgoingRequests = [];
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
      final friends = await ApiService.getFriends();
      final requests = await ApiService.getFriendRequests();
      final contacts = await ApiService.getContacts();

      final incoming = (requests['incoming'] as List? ?? [])
          .map((r) => User.fromJson(r as Map<String, dynamic>))
          .toList();
      final outgoing = (requests['outgoing'] as List? ?? [])
          .map((r) => User.fromJson(r as Map<String, dynamic>))
          .toList();

      if (mounted) {
        setState(() {
          _friends = friends;
          _incomingRequests = incoming;
          _outgoingRequests = outgoing;
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
          tabs: [
            Tab(text: 'Друзья (${_friends.length})'),
            Tab(text: 'Запросы (${_incomingRequests.length})'),
            Tab(text: 'Контакты (${_contacts.length})'),
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
            Text('У вас пока нет друзей',
                style: TextStyle(color: Colors.grey[600], fontSize: 16)),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () => Navigator.pushNamed(context, '/search'),
              icon: const Icon(Icons.person_add),
              label: const Text('Найти друзей'),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: _friends.length,
      itemBuilder: (context, index) {
        final friend = _friends[index];
        return UserTile(
          user: friend,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => UserProfileScreen(userId: friend.id),
              ),
            );
          },
          trailing: PopupMenuButton<String>(
            onSelected: (value) async {
              if (value == 'remove') {
                await ApiService.removeFriend(friend.id);
                _loadData();
              }
            },
            itemBuilder: (ctx) => [
              const PopupMenuItem(
                value: 'remove',
                child: Row(
                  children: [
                    Icon(Icons.person_remove, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Удалить из друзей',
                        style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildRequestsList() {
    return ListView(
      children: [
        if (_incomingRequests.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text('Входящие запросы',
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[700])),
          ),
          ..._incomingRequests.map((user) => ListTile(
                leading: CircleAvatar(
                  backgroundImage: user.avatarUrl != null
                      ? NetworkImage(user.avatarUrl!)
                      : null,
                  child: user.avatarUrl == null
                      ? Text(user.initials)
                      : null,
                ),
                title: Text(user.displayName),
                subtitle: Text('@${user.username ?? 'username'}'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.check, color: Colors.green),
                      onPressed: () async {
                        await ApiService.acceptFriendRequest(user.id);
                        _loadData();
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.red),
                      onPressed: () async {
                        await ApiService.rejectFriendRequest(user.id);
                        _loadData();
                      },
                    ),
                  ],
                ),
              )),
        ],
        if (_outgoingRequests.isNotEmpty) ...[
          const Divider(),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text('Исходящие запросы',
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[700])),
          ),
          ..._outgoingRequests.map((user) => ListTile(
                leading: CircleAvatar(
                  backgroundImage: user.avatarUrl != null
                      ? NetworkImage(user.avatarUrl!)
                      : null,
                  child: user.avatarUrl == null
                      ? Text(user.initials)
                      : null,
                ),
                title: Text(user.displayName),
                subtitle: Text('@${user.username ?? 'username'}'),
                trailing: TextButton(
                  onPressed: () async {
                    await ApiService.cancelFriendRequest(user.id);
                    _loadData();
                  },
                  child: const Text('Отменить'),
                ),
              )),
        ],
        if (_incomingRequests.isEmpty && _outgoingRequests.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.mail_outline,
                      size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text('Нет запросов в друзья',
                      style:
                          TextStyle(color: Colors.grey[600], fontSize: 16)),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildContactsList() {
    if (_contacts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.contacts_outlined,
                size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text('Список контактов пуст',
                style: TextStyle(color: Colors.grey[600], fontSize: 16)),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: _contacts.length,
      itemBuilder: (context, index) {
        final contact = _contacts[index];
        return UserTile(
          user: contact,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => UserProfileScreen(userId: contact.id),
              ),
            );
          },
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