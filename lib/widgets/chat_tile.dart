import 'package:flutter/material.dart';
import '../models/chat.dart';
import '../services/api_service.dart';
import 'user_profile_screen.dart';
import 'chat_info_screen.dart';

class ChatTile extends StatelessWidget {
  final Chat chat;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  final bool isSelected;

  const ChatTile({
    super.key,
    required this.chat,
    required this.onTap,
    this.onLongPress,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? Theme.of(context).primaryColor.withOpacity(0.1)
              : null,
          border: Border(
            bottom: BorderSide(
              color: Colors.grey.withOpacity(0.1),
              width: 1,
            ),
          ),
        ),
        child: Row(
          children: [
            // ✅ Кликабельная аватарка
            GestureDetector(
              onTap: () {
                if (chat.type == 'private' && chat.companionId != null) {
                  // Для ЛС — переход в профиль собеседника
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => UserProfileScreen(userId: chat.companionId!),
                    ),
                  );
                } else {
                  // Для группы/канала — переход в инфо о чате
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ChatInfoScreen(chat: chat),
                    ),
                  );
                }
              },
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: Theme.of(context).colorScheme.primary,
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
                  if (chat.isOnline && chat.type == 'private')
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
              ),
            ),
            const SizedBox(width: 12),
            // Информация о чате
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          chat.displayName,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: chat.isMuted ? Colors.grey : Colors.black87,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (chat.lastMessageAt != null)
                        Text(
                          _formatTime(chat.lastMessageAt!),
                          style: TextStyle(
                            fontSize: 12,
                            color: chat.unreadCount > 0
                                ? Theme.of(context).primaryColor
                                : Colors.grey,
                            fontWeight: chat.unreadCount > 0
                                ? FontWeight.w600
                                : FontWeight.normal,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          chat.lastMessage ?? 'Нет сообщений',
                          style: TextStyle(
                            fontSize: 14,
                            color: chat.isMuted ? Colors.grey : Colors.grey[600],
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (chat.unreadCount > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: chat.isMuted
                                ? Colors.grey
                                : Theme.of(context).primaryColor,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            chat.unreadCount > 99
                                ? '99+'
                                : '${chat.unreadCount}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(String dateTimeStr) {
    try {
      final date = DateTime.parse(dateTimeStr);
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final messageDate = DateTime(date.year, date.month, date.day);

      if (messageDate == today) {
        return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
      } else if (messageDate == today.subtract(const Duration(days: 1))) {
        return 'Вчера';
      } else {
        return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}';
      }
    } catch (_) {
      return '';
    }
  }
}