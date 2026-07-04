import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/user.dart';
import '../widgets/app_scaffold.dart';

class UserProfileScreen extends StatefulWidget {
  final String userId;
  const UserProfileScreen({super.key, required this.userId});

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  User? _user;
  bool _loading = true;
  String _friendshipStatus = 'none';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final user = await ApiService.getUserProfile(widget.userId);
      final status = await ApiService.getFriendStatus(widget.userId);
      if (mounted) {
        setState(() {
          _user = user;
          _friendshipStatus = status['friendship_status'] ?? 'none';
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
              ? const Center(child: Text('Пользователь не найден'))
              : SingleChildScrollView(
                  child: Column(
                    children: [
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
                              child: const Text('⭐ Premium',
                                  style: TextStyle(color: Colors.white, fontSize: 12)),
                            ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(
                              color: _user!.isOnline ? Colors.green : Colors.grey,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              _user!.isOnline
                                  ? 'В сети'
                                  : (_user!.lastSeen != null
                                      ? 'Был(а) ${_user!.lastSeen}'
                                      : 'Не в сети'),
                              style: const TextStyle(color: Colors.white, fontSize: 12),
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
                          child: Text(_user!.bio!),
                        ),
                      const SizedBox(height: 24),
                      if (_user!.city != null || _user!.country != null)
                        Row(
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
                      const SizedBox(height: 24),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Row(
                          children: [
                            Expanded(child: _statCard('Подарки', '${_user!.giftsReceivedCount}')),
                            const SizedBox(width: 12),
                            Expanded(child: _statCard('Монеты', '${_user!.plusCoins}')),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      const Divider(),
                      _buildActionButtons(),
                      const Divider(),
                    ],
                  ),
                ),
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
          Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          if (_friendshipStatus == 'none')
            FilledButton.icon(
              onPressed: () async {
                final res = await ApiService.sendFriendRequest(widget.userId);
                if (res['success'] == true && mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Запрос отправлен')),
                  );
                  setState(() => _friendshipStatus = 'i_sent_request');
                }
              },
              icon: const Icon(Icons.person_add),
              label: const Text('Добавить в друзья'),
            )
          else if (_friendshipStatus == 'i_sent_request')
            OutlinedButton.icon(
              onPressed: () async {
                await ApiService.cancelFriendRequest(widget.userId);
                if (mounted) setState(() => _friendshipStatus = 'none');
              },
              icon: const Icon(Icons.cancel),
              label: const Text('Отменить запрос'),
            )
          else if (_friendshipStatus == 'i_received_request')
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () async {
                      await ApiService.acceptFriendRequest(widget.userId);
                      if (mounted) setState(() => _friendshipStatus = 'friends');
                    },
                    icon: const Icon(Icons.check),
                    label: const Text('Принять'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      await ApiService.rejectFriendRequest(widget.userId);
                      if (mounted) setState(() => _friendshipStatus = 'none');
                    },
                    icon: const Icon(Icons.close),
                    label: const Text('Отклонить'),
                  ),
                ),
              ],
            )
          else if (_friendshipStatus == 'friends')
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () async {
                      final result = await ApiService.findPrivateChat(widget.userId);
                      if (result['success'] == true && result['chat_id'] != null) {
                        // TODO: Открыть чат
                      }
                    },
                    icon: const Icon(Icons.chat),
                    label: const Text('Написать'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('Удалить из друзей?'),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Отмена')),
                            TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Удалить')),
                          ],
                        ),
                      );
                      if (confirm == true) {
                        await ApiService.removeFriend(widget.userId);
                        if (mounted) setState(() => _friendshipStatus = 'none');
                      }
                    },
                    icon: const Icon(Icons.person_remove),
                    label: const Text('Удалить'),
                  ),
                ),
              ],
            ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Заблокировать?'),
                  content: const Text('Пользователь не сможет писать вам'),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Отмена')),
                    TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Заблокировать')),
                  ],
                ),
              );
              if (confirm == true) {
                await ApiService.blockUser(widget.userId);
                if (mounted) Navigator.pop(context);
              }
            },
            icon: const Icon(Icons.block, color: Colors.red),
            label: const Text('Заблокировать', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}