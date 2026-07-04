import 'package:flutter/material.dart';

class CreateChatModal extends StatelessWidget {
  final Function(String chatId) onChatCreated;

  const CreateChatModal({super.key, required this.onChatCreated});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              'Создать',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 24),
          _buildOption(
            context,
            icon: Icons.person,
            color: Colors.blue,
            title: 'Личный чат',
            subtitle: 'Написать одному пользователю',
            onTap: () {
              Navigator.pop(context);
              // TODO: Открыть модалку создания ЛС
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Скоро будет доступно')),
              );
            },
          ),
          _buildOption(
            context,
            icon: Icons.group,
            color: Colors.green,
            title: 'Группа',
            subtitle: 'Создать группу с участниками',
            onTap: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Скоро будет доступно')),
              );
            },
          ),
          _buildOption(
            context,
            icon: Icons.campaign,
            color: Colors.orange,
            title: 'Канал',
            subtitle: 'Создать канал для публикаций',
            onTap: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Скоро будет доступно')),
              );
            },
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildOption(
    BuildContext context, {
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: color.withOpacity(0.1),
        child: Icon(icon, color: color),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(subtitle, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
      onTap: onTap,
    );
  }
}