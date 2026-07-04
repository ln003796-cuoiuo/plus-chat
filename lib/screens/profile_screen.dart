import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/user.dart';
import '../widgets/app_scaffold.dart';

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
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Профиль',
      child: _loading
          ? const Center(child: CircularProgressIndicator())
          : _user == null
              ? const Center(child: Text('Ошибка загрузки профиля'))
              : SingleChildScrollView(
                  child: Column(
                    children: [
                      const SizedBox(height: 24),
                      if (_user!.bannerUrl != null)
                        Container(
                          height: 120,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            image: DecorationImage(
                              image: NetworkImage(_user!.bannerUrl!),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      Stack(
                        alignment: Alignment.bottomCenter,
                        children: [
                          CircleAvatar(
                            radius: 60,
                            backgroundColor: Theme.of(context).colorScheme.primary,
                            backgroundImage: _user!.avatarUrl != null
                                ? NetworkImage(_user!.avatarUrl!)
                                : null,
                            child: _user!.avatarUrl == null
                                ? Text(
                                    _user!.initials,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 48,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  )
                                : null,
                          ),
                          if (_user!.isOnline)
                            Positioned(
                              bottom: 4,
                              right: 4,
                              child: Container(
                                width: 20,
                                height: 20,
                                decoration: BoxDecoration(
                                  color: Colors.green,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white, width: 3),
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _user!.displayName,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '@${_user!.username ?? 'username'}',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        children: [
                          if (_user!.isPremium)
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
                                  Text('Premium',
                                      style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(
                              color: _user!.isOnline ? Colors.green : Colors.grey,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              _user!.isOnline ? 'В сети' : 'Не в сети',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                              ),
                            ),
                          ),
                          if (_user!.customStatusEmoji != null ||
                              _user!.customStatusText != null)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.blue[100],
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '${_user!.customStatusEmoji ?? ''} ${_user!.customStatusText ?? ''}'.trim(),
                                style: const TextStyle(
                                  color: Colors.blue,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 24),
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
                      if (_user!.city != null || _user!.country != null)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.location_on, size: 16, color: Colors.grey),
                              const SizedBox(width: 4),
                              Text(
                                [_user!.city, _user!.country]
                                    .where((e) => e != null && e.isNotEmpty)
                                    .join(', '),
                                style: TextStyle(color: Colors.grey[700]),
                              ),
                            ],
                          ),
                        ),
                      const SizedBox(height: 24),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Row(
                          children: [
                            Expanded(
                              child: _statCard('Подарки', '${_user!.giftsReceivedCount}'),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _statCard('Монеты', '${_user!.plusCoins}'),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _statCard('Отправлено', '${_user!.giftsSentCount}'),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      const Divider(),
                      if (_hasSocialLinks()) ...[
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              'Социальные сети',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                        if (_user!.website != null)
                          _socialTile(Icons.language, 'Сайт', _user!.website!),
                        if (_user!.instagram != null)
                          _socialTile(Icons.camera_alt, 'Instagram', _user!.instagram!),
                        if (_user!.telegram != null)
                          _socialTile(Icons.send, 'Telegram', _user!.telegram!),
                        if (_user!.twitter != null)
                          _socialTile(Icons.flutter_dash, 'Twitter', _user!.twitter!),
                        if (_user!.github != null)
                          _socialTile(Icons.code, 'GitHub', _user!.github!),
                        if (_user!.linkedin != null)
                          _socialTile(Icons.work, 'LinkedIn', _user!.linkedin!),
                        const Divider(),
                      ],
                      ListTile(
                        leading: const Icon(Icons.edit),
                        title: const Text('Редактировать профиль'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Скоро будет доступно')),
                          );
                        },
                      ),
                      ListTile(
                        leading: const Icon(Icons.card_giftcard_outlined),
                        title: const Text('Мои подарки'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () {
                          Navigator.pushNamed(context, '/gifts');
                        },
                      ),
                      ListTile(
                        leading: const Icon(Icons.emoji_emotions_outlined),
                        title: const Text('Стикеры'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () {
                          Navigator.pushNamed(context, '/stickers');
                        },
                      ),
                      const Divider(),
                    ],
                  ),
                ),
    );
  }

  bool _hasSocialLinks() {
    return (_user!.website != null && _user!.website!.isNotEmpty) ||
        (_user!.instagram != null && _user!.instagram!.isNotEmpty) ||
        (_user!.telegram != null && _user!.telegram!.isNotEmpty) ||
        (_user!.twitter != null && _user!.twitter!.isNotEmpty) ||
        (_user!.github != null && _user!.github!.isNotEmpty) ||
        (_user!.linkedin != null && _user!.linkedin!.isNotEmpty);
  }

  Widget _socialTile(IconData icon, String label, String value) {
    return ListTile(
      leading: Icon(icon),
      title: Text(label),
      subtitle: Text(value),
      trailing: const Icon(Icons.open_in_new, size: 16),
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Открытие ссылок скоро будет доступно')),
        );
      },
    );
  }

  Widget _statCard(String label, String value) {
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
              fontSize: 11,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}