import 'package:flutter/material.dart';
import '../models/chat.dart';

class ChatTile extends StatelessWidget {
  final Chat chat;
  final VoidCallback onTap;

  const ChatTile({
    super.key,
    required this.chat,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: Colors.grey[200]!,
              width: 1,
            ),
          ),
        ),
        child: Row(
          children: [
            // Аватар
            CircleAvatar(
              radius: 28,
              backgroundColor: chat.type == ChatType.private
                  ? Colors.blue
                  : chat.type == ChatType.group
                      ? Colors.green
                      : Colors.orange,
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
            const SizedBox(width: 12),

            // Информация
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Имя и время
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          chat.displayName,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (chat.lastMessageAt != null)
                        Text(
                          chat.lastMessageTimeFormatted,
                          style: TextStyle(
                            fontSize: 12,
                            color: chat.unreadCount > 0
                                ? Theme.of(context).primaryColor
                                : Colors.grey[600],
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),

                  // Последнее сообщение и счётчик
                  Row(
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
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          constraints: const BoxConstraints(
                              minWidth: 24, minHeight: 24),
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
                            textAlign: TextAlign.center,
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
}