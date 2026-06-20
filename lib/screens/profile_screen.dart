import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../models/user.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  User? _user;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final user = await ApiService.getMe();
      if (mounted) {
        setState(() {
          _user = user;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Профиль'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _user == null
              ? const Center(child: Text('Ошибка загрузки профиля'))
              : SingleChildScrollView(
                  child: Column(
                    children: [
                      const SizedBox(height: 24),
                      // Аватар
                      CircleAvatar(
                        radius: 60,
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        backgroundImage: _user!.avatarUrl != null
                            ? NetworkImage(_user!.avatarUrl!)
                            : null,
                        child: _user!.avatarUrl == null
                            ? Text(
                                _user!.firstName[0].toUpperCase(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 48,
                                  fontWeight: FontWeight.bold,
                                ),
                              )
                            : null,
                      ),
                      const SizedBox(height: 16),
                      // Имя
                      Text(
                        '${_user!.firstName} ${_user!.lastName}',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '@${_user!.username}',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.green,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          'В сети',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      // О себе
                      if (_user!.bio != null && _user!.bio!.isNotEmpty)
                        Container(
                          margin: const EdgeInsets.symmetric(horizontal: 16),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'О себе',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(_user!.bio!),
                            ],
                          ),
                        ),
                      const SizedBox(height: 24),
                      // Статистика
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Row(
                          children: [
                            Expanded(
                              child: _buildStatCard('Друзья', '0'),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildStatCard('Подписчики', '0'),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildStatCard('Контакты', '0'),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      const Divider(),
                      // Подарки и стикеры
                      ListTile(
                        leading: const Icon(Icons.card_giftcard_outlined),
                        title: const Text('Подарки'),
                        subtitle: const Text('12 получено'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () {
                          // TODO: Экран подарков
                        },
                      ),
                      ListTile(
                        leading: const Icon(Icons.emoji_emotions_outlined),
                        title: const Text('Стикеры'),
                        subtitle: const Text('5 паков'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () {
                          // TODO: Экран стикеров
                        },
                      ),
                      const Divider(),
                    ],
                  ),
                ),
    );
  }

  Widget _buildStatCard(String label, String value) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }
}