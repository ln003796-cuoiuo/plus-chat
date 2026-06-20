import 'package:flutter/material.dart';
import '../models/message.dart';

class MessageBubble extends StatelessWidget {
  final Message message;
  final bool isMe;
  final bool showSenderName;
  final VoidCallback? onLongPress;

  const MessageBubble({
    super.key,
    required this.message,
    required this.isMe,
    this.showSenderName = false,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPress: onLongPress,
      child: Container(
        margin: EdgeInsets.only(
          left: isMe ? 64 : 8,
          right: isMe ? 8 : 64,
          top: 4,
          bottom: 4,
        ),
        child: Column(
          crossAxisAlignment:
              isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            // Имя отправителя (для групп)
            if (showSenderName && !isMe)
              Padding(
                padding: const EdgeInsets.only(left: 12, bottom: 4),
                child: Text(
                  message.sender?.displayName ?? 'Пользователь',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _getSenderColor(message.senderId),
                  ),
                ),
              ),

            // Пузырь сообщения
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 8,
              ),
              decoration: BoxDecoration(
                color: _getBackgroundColor(context),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(isMe ? 16 : 4),
                  bottomRight: Radius.circular(isMe ? 4 : 16),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 2,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Ответ на сообщение
                  if (message.replyToMessage != null)
                    _buildReply(context),

                  // Контент сообщения
                  _buildContent(context),

                  // Вложения
                  if (message.hasAttachments) _buildAttachments(context),

                  // Время и статусы
                  _buildFooter(context),

                  // Реакции
                  if (message.reactions.isNotEmpty)
                    _buildReactions(context),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Цвет фона пузыря
  Color _getBackgroundColor(BuildContext context) {
    if (message.isSending) {
      return Colors.grey.withOpacity(0.3);
    }
    if (message.isFailed) {
      return Colors.red.withOpacity(0.1);
    }
    return isMe
        ? const Color(0xFFDCF8C6)
        : Theme.of(context).colorScheme.surfaceVariant;
  }

  /// Цвет имени отправителя
  Color _getSenderColor(String senderId) {
    final colors = [
      Colors.red,
      Colors.blue,
      Colors.green,
      Colors.purple,
      Colors.orange,
      Colors.teal,
      Colors.pink,
      Colors.indigo,
    ];
    final index = senderId.hashCode.abs() % colors.length;
    return colors[index];
  }

  /// Ответ на сообщение
  Widget _buildReply(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border(
          left: BorderSide(
            color: Theme.of(context).primaryColor,
            width: 3,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            message.replyToMessage!.sender?.displayName ?? 'Пользователь',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).primaryColor,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            message.replyToMessage!.content,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey[700],
            ),
          ),
        ],
      ),
    );
  }

  /// Основной контент сообщения
  Widget _buildContent(BuildContext context) {
    // Если это не текст, показываем тип
    if (message.type != MessageType.text && message.content.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(12),
        child: Text(
          message.type.label,
          style: const TextStyle(
            fontStyle: FontStyle.italic,
            color: Colors.grey,
          ),
        ),
      );
    }

    if (message.content.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
      child: SelectableText(
        message.content,
        style: const TextStyle(fontSize: 15, height: 1.4),
      ),
    );
  }

  /// Вложения (фото, видео, файлы)
  Widget _buildAttachments(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 4, 8, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: message.attachments.map((att) {
          return Container(
            margin: const EdgeInsets.only(top: 4),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: Colors.grey[200],
            ),
            child: att.type == 'photo'
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      att.url,
                      width: 200,
                      fit: BoxFit.cover,
                    ),
                  )
                : Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        Icon(
                          att.type == 'video'
                              ? Icons.videocam
                              : Icons.attach_file,
                          size: 24,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            att.name ?? 'Файл',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
          );
        }).toList(),
      ),
    );
  }

  /// Время и статусы
  Widget _buildFooter(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 4, bottom: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Индикатор отправки
          if (message.isSending)
            const SizedBox(
              width: 12,
              height: 12,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),

          // Индикатор ошибки
          if (message.isFailed)
            const Padding(
              padding: EdgeInsets.only(right: 4),
              child: Icon(Icons.error, size: 14, color: Colors.red),
            ),

          // Метка "отредактировано"
          if (message.edited)
            Padding(
              padding: const EdgeInsets.only(right: 4),
              child: Text(
                'ред.',
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey[600],
                ),
              ),
            ),

          // Время
          Text(
            message.timeFormatted,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey[600],
            ),
          ),

          // Статусы доставки (только для своих сообщений)
          if (isMe) ...[
            const SizedBox(width: 4),
            Icon(
              _getStatusIcon(),
              size: 14,
              color: message.viewsCount > 0
                  ? Colors.blue
                  : Colors.grey[600],
            ),
          ],
        ],
      ),
    );
  }

  /// Иконка статуса доставки
  IconData _getStatusIcon() {
    if (message.viewsCount > 0) {
      return Icons.visibility;
    }
    if (message.isSending) {
      return Icons.schedule;
    }
    return Icons.check;
  }

  /// Реакции
  Widget _buildReactions(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Wrap(
        spacing: 4,
        runSpacing: 4,
        children: message.reactions.map((reaction) {
          return Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 8,
              vertical: 4,
            ),
            decoration: BoxDecoration(
              color: reaction.hasMyReaction
                  ? Theme.of(context).primaryColor.withOpacity(0.2)
                  : Colors.grey[200],
              borderRadius: BorderRadius.circular(12),
              border: reaction.hasMyReaction
                  ? Border.all(
                      color: Theme.of(context).primaryColor,
                      width: 1,
                    )
                  : null,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  reaction.emoji,
                  style: const TextStyle(fontSize: 14),
                ),
                const SizedBox(width: 4),
                Text(
                  '${reaction.count}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: reaction.hasMyReaction
                        ? FontWeight.bold
                        : FontWeight.normal,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}