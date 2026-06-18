import 'package:flutter/material.dart';
import '../models/chat.dart';

/// Виджет для отображения чата в списке
class ChatTile extends StatelessWidget {
  final Chat chat;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  const ChatTile({
    super.key,
    required this.chat,
    required this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      onLongPress: onLongPress,
      leading: _buildAvatar(context),
      title: _buildTitle(context),
      subtitle: _buildSubtitle(context),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    );
  }

  /// Аватар чата
  Widget _buildAvatar(BuildContext context) {
    return Stack(
      children: [
        CircleAvatar(
          radius: 28,
          backgroundColor: Theme.of(context).primaryColor,
          backgroundImage: chat.avatarUrl != null
              ? NetworkImage(chat.avatarUrl!)
              : null,
          child: chat.avatarUrl == null
              ? Text(
                  chat.initial,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                )
              : null,
        ),
        // Индикатор онлайн для личных чатов
        if (chat.type == ChatType.private && chat.isCompanionOnline)
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              width: 14,
              height: 14,
              decoration: BoxDecoration(
                color: Colors.green,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
            ),
          ),
      ],
    );
  }

  /// Заголовок чата (имя + время)
  Widget _buildTitle(BuildContext context) {
    return Row(
      children: [
        // Иконка верификации
        if (chat.isVerified)
          Padding(
            padding: const EdgeInsets.only(right: 4),
            child: Icon(
              Icons.verified,
              size: 16,
              color: Theme.of(context).primaryColor,
            ),
          ),
        // Имя чата
        Expanded(
          child: Text(
            chat.displayName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 16,
            ),
          ),
        ),
        const SizedBox(width: 8),
        // Время последнего сообщения
        Text(
          chat.lastMessageTime,
          style: TextStyle(
            fontSize: 12,
            color: chat.unreadCount > 0
                ? Theme.of(context).primaryColor
                : Colors.grey[600],
          ),
        ),
      ],
    );
  }

  /// Подзаголовок (последнее сообщение + счётчик непрочитанных)
  Widget _buildSubtitle(BuildContext context) {
    return Row(
      children: [
        // Индикатор заглушенного чата
        if (chat.isMuted)
          Padding(
            padding: const EdgeInsets.only(right: 4),
            child: Icon(
              Icons.volume_off,
              size: 14,
              color: Colors.grey[600],
            ),
          ),
        // Текст последнего сообщения
        Expanded(
          child: Text(
            chat.lastMessage ?? 'Нет сообщений',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
            ),
          ),
        ),
        const SizedBox(width: 8),
        // Счётчик непрочитанных
        if (chat.unreadCount > 0)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
            decoration: BoxDecoration(
              color: chat.isMuted ? Colors.grey : Theme.of(context).primaryColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              chat.unreadCount > 99 ? '99+' : '${chat.unreadCount}',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
      ],
    );
  }
}