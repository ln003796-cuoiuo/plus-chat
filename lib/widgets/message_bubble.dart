import 'package:flutter/material.dart';
import '../models/message.dart';

class MessageBubble extends StatelessWidget {
  final Message message;
  final bool isMe;
  final bool showSenderName;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  const MessageBubble({
    super.key,
    required this.message,
    required this.isMe,
    this.showSenderName = false,
    this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 2, horizontal: 8),
        child: Column(
          crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            if (showSenderName && !isMe && message.sender != null)
              Padding(
                padding: const EdgeInsets.only(left: 12, bottom: 2),
                child: Text(
                  message.sender!.displayName,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _getSenderColor(message.senderId),
                  ),
                ),
              ),
            Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.75,
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
                  if (message.replyToMessage != null) _buildReply(context),
                  _buildContent(context),
                  if (message.hasAttachments) _buildAttachments(context),
                  _buildFooter(context),
                  if (message.reactions.isNotEmpty) _buildReactions(context),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getBackgroundColor(BuildContext context) {
    if (message.isSending) return Colors.grey.withOpacity(0.3);
    if (message.isFailed) return Colors.red.withOpacity(0.1);
    return isMe
        ? const Color(0xFFDCF8C6)
        : Theme.of(context).colorScheme.surfaceVariant;
  }

  Color _getSenderColor(String senderId) {
    final colors = [Colors.red, Colors.blue, Colors.green, Colors.purple, Colors.orange, Colors.teal, Colors.pink, Colors.indigo];
    final index = senderId.hashCode.abs() % colors.length;
    return colors[index];
  }

  Widget _buildReply(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(8, 8, 8, 0),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border(
          left: BorderSide(color: Theme.of(context).primaryColor, width: 3),
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
            style: TextStyle(fontSize: 13, color: Colors.grey[700]),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    if (message.type != MessageType.text &&
        message.content.isEmpty &&
        !message.hasAttachments) {
      return Padding(
        padding: const EdgeInsets.all(12),
        child: Text(
          message.type.label,
          style: const TextStyle(fontStyle: FontStyle.italic, color: Colors.grey),
        ),
      );
    }
    if (message.content.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
      child: SelectableText(
        message.content,
        style: const TextStyle(fontSize: 15, height: 1.4),
      ),
    );
  }

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
            child: att.fileType == 'photo'
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      att.fileUrl,
                      width: 200,
                      fit: BoxFit.cover,
                    ),
                  )
                : Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        Icon(
                          att.fileType == 'video' ? Icons.videocam : Icons.attach_file,
                          size: 24,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            att.fileName ?? 'Файл',
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

  Widget _buildFooter(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 4, bottom: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (message.isSending)
            const SizedBox(
              width: 12,
              height: 12,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          if (message.isFailed)
            const Padding(
              padding: EdgeInsets.only(right: 4),
              child: Icon(Icons.error, size: 14, color: Colors.red),
            ),
          if (message.edited)
            Padding(
              padding: const EdgeInsets.only(right: 4),
              child: Text('ред.', style: TextStyle(fontSize: 10, color: Colors.grey[600])),
            ),
          Text(
            message.timeFormatted,
            style: TextStyle(fontSize: 11, color: Colors.grey[600]),
          ),
          if (isMe) ...[
            const SizedBox(width: 4),
            Icon(
              _getStatusIcon(),
              size: 14,
              color: message.viewsCount > 0 ? Colors.blue : Colors.grey[600],
            ),
          ],
        ],
      ),
    );
  }

  IconData _getStatusIcon() {
    if (message.isSending) return Icons.access_time;
    if (message.isFailed) return Icons.error;
    if (message.id > 0) return Icons.done_all;
    return Icons.done;
  }

  Widget _buildReactions(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(8, 0, 8, 8),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.8),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withOpacity(0.3)),
      ),
      child: Wrap(
        spacing: 4,
        runSpacing: 2,
        children: message.reactions.map((reaction) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: reaction.hasMyReaction
                  ? Theme.of(context).primaryColor.withOpacity(0.2)
                  : Colors.grey.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
              border: reaction.hasMyReaction
                  ? Border.all(color: Theme.of(context).primaryColor, width: 1)
                  : null,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(reaction.emoji, style: const TextStyle(fontSize: 14)),
                const SizedBox(width: 2),
                Text(
                  '${reaction.count}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: reaction.hasMyReaction ? FontWeight.bold : FontWeight.normal,
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