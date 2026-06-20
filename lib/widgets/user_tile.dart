import 'package:flutter/material.dart';
import '../models/user.dart';

class UserTile extends StatelessWidget {
  final User user;
  final VoidCallback onTap;
  final Widget? trailing;
  final String? subtitle;

  const UserTile({
    super.key,
    required this.user,
    required this.onTap,
    this.trailing,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        backgroundImage: user.avatarUrl != null ? NetworkImage(user.avatarUrl!) : null,
        child: user.avatarUrl == null ? Text(user.initial) : null,
      ),
      title: Text(user.displayName),
      subtitle: Text(subtitle ?? '@${user.username}'),
      trailing: trailing ?? (user.isOnline ? const Icon(Icons.circle, color: Colors.green, size: 12) : null),
      onTap: onTap,
    );
  }
}