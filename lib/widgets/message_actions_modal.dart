import 'package:flutter/material.dart';
import '../models/message.dart';
import '../services/api_service.dart';

class MessageActionsModal extends StatelessWidget {
  final Message message;
  final bool isMe;
  final String chatId;
  final String? myRole;

  const MessageActionsModal({
    super.key,
    required this.message,
    required this.isMe,
    required this.chatId,
    this.myRole,
  });

  @override
  Widget build(BuildContext context) {
    final isAdmin = myRole == 'owner' || myRole == 'admin' || myRole == 'moderator';

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
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
          if (message.type == MessageType.text)
            ListTile(
              leading: const Icon(Icons.reply),
              title: const Text('Ответить'),
              onTap: () {
                Navigator.pop(context, 'reply');
              },
            ),
          if (isMe && message.type == MessageType.text)
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('Редактировать'),
              onTap: () => Navigator.pop(context, 'edit'),
            ),
          ListTile(
            leading: const Icon(Icons.push_pin),
            title: const Text('Закрепить'),
            onTap: () => Navigator.pop(context, 'pin'),
          ),
          ListTile(
            leading: const Icon(Icons.forward),
            title: const Text('Переслать'),
            onTap: () => Navigator.pop(context, 'forward'),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.delete_outline),
            title: const Text('Удалить у себя'),
            onTap: () => Navigator.pop(context, 'delete_me'),
          ),
          if (isMe || isAdmin)
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('Удалить у всех', style: TextStyle(color: Colors.red)),
              onTap: () => Navigator.pop(context, 'delete_all'),
            ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

/// Показать меню действий
Future<String?> showMessageActionsModal(
  BuildContext context, {
  required Message message,
  required bool isMe,
  required String chatId,
  String? myRole,
}) {
  return showModalBottomSheet<String>(
    context: context,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) => MessageActionsModal(
      message: message,
      isMe: isMe,
      chatId: chatId,
      myRole: myRole,
    ),
  );
}