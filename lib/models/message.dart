import 'user.dart';

enum MessageType {
  text,
  voice,
  video,
  photo,
  file,
  gif,
  sticker,
  gift,
  location,
  contact;

  String get label {
    switch (this) {
      case MessageType.text:
        return 'Текст';
      case MessageType.voice:
        return 'Голосовое';
      case MessageType.video:
        return 'Видео';
      case MessageType.photo:
        return 'Фото';
      case MessageType.file:
        return 'Файл';
      case MessageType.gif:
        return 'GIF';
      case MessageType.sticker:
        return 'Стикер';
      case MessageType.gift:
        return 'Подарок';
      case MessageType.location:
        return 'Геопозиция';
      case MessageType.contact:
        return 'Контакт';
    }
  }

  static MessageType fromString(String? type) {
    switch (type) {
      case 'voice':
        return MessageType.voice;
      case 'video':
        return MessageType.video;
      case 'photo':
        return MessageType.photo;
      case 'file':
        return MessageType.file;
      case 'gif':
        return MessageType.gif;
      case 'sticker':
        return MessageType.sticker;
      case 'gift':
        return MessageType.gift;
      case 'location':
        return MessageType.location;
      case 'contact':
        return MessageType.contact;
      default:
        return MessageType.text;
    }
  }
}

class MessageReaction {
  final String emoji;
  final int count;
  final bool hasMyReaction;

  MessageReaction({
    required this.emoji,
    required this.count,
    this.hasMyReaction = false,
  });

  factory MessageReaction.fromJson(Map<String, dynamic> json) {
    return MessageReaction(
      emoji: json['emoji'] ?? '',
      count: (json['count'] ?? 0) is int
          ? json['count'] ?? 0
          : int.tryParse((json['count'] ?? 0).toString()) ?? 0,
      hasMyReaction: json['has_my_reaction'] == true || json['hasMyReaction'] == true,
    );
  }
}

class MessageAttachment {
  final int id;
  final String fileType;
  final String fileUrl;
  final String? thumbnailUrl;
  final String? fileName;
  final int? fileSize;
  final String? mimeType;
  final int? width;
  final int? height;
  final int? duration;

  MessageAttachment({
    required this.id,
    required this.fileType,
    required this.fileUrl,
    this.thumbnailUrl,
    this.fileName,
    this.fileSize,
    this.mimeType,
    this.width,
    this.height,
    this.duration,
  });

  factory MessageAttachment.fromJson(Map<String, dynamic> json) {
    return MessageAttachment(
      id: (json['id'] ?? 0) is int
          ? json['id'] ?? 0
          : int.tryParse((json['id'] ?? 0).toString()) ?? 0,
      fileType: json['file_type'] ?? json['type'] ?? 'file',
      fileUrl: json['file_url'] ?? json['url'] ?? '',
      thumbnailUrl: json['thumbnail_url'] ?? json['thumbnailUrl'],
      fileName: json['file_name'] ?? json['fileName'],
      fileSize: json['file_size'] ?? json['fileSize'],
      mimeType: json['mime_type'] ?? json['mimeType'],
      width: json['width'],
      height: json['height'],
      duration: json['duration'],
    );
  }
}

class Message {
  final int id;
  final String chatId;
  final String senderId;
  final User? sender;
  final MessageType type;
  final String content;
  final String? fileUrl;
  final String? mimeType;
  final int? fileSize;
  final int? width;
  final int? height;
  final int? duration;
  final int? replyTo;
  final Message? replyToMessage;
  final bool isPinned;
  final bool edited;
  final bool deleted;
  final String createdAt;
  final List<MessageAttachment> attachments;
  final List<MessageReaction> reactions;
  final int viewsCount;
  final int forwardsCount;

  Message({
    required this.id,
    required this.chatId,
    required this.senderId,
    this.sender,
    required this.type,
    required this.content,
    this.fileUrl,
    this.mimeType,
    this.fileSize,
    this.width,
    this.height,
    this.duration,
    this.replyTo,
    this.replyToMessage,
    this.isPinned = false,
    this.edited = false,
    this.deleted = false,
    required this.createdAt,
    this.attachments = const [],
    this.reactions = const [],
    this.viewsCount = 0,
    this.forwardsCount = 0,
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    User? sender;
    if (json['sender'] != null) {
      sender = User.fromJson(json['sender'] as Map<String, dynamic>);
    } else if (json['sender_id'] != null) {
      sender = User(
        id: json['sender_id'].toString(),
        firstName: json['sender_first_name'] ?? '',
        lastName: json['sender_last_name'],
        username: json['sender_username'],
        avatarUrl: json['sender_avatar'],
      );
    }

    Message? replyToMessage;
    if (json['reply_to_message'] != null) {
      replyToMessage = Message.fromJson(json['reply_to_message']);
    }

    List<MessageAttachment> attachments = [];
    if (json['attachments'] != null && json['attachments'] is List) {
      attachments = (json['attachments'] as List)
          .map((a) => MessageAttachment.fromJson(a as Map<String, dynamic>))
          .toList();
    }

    List<MessageReaction> reactions = [];
    if (json['reactions'] != null && json['reactions'] is List) {
      reactions = (json['reactions'] as List)
          .map((r) => MessageReaction.fromJson(r as Map<String, dynamic>))
          .toList();
    }

    return Message(
      id: (json['id'] ?? 0) is int
          ? json['id'] ?? 0
          : int.tryParse((json['id'] ?? 0).toString()) ?? 0,
      chatId: json['chat_id']?.toString() ?? '',
      senderId: json['sender_id']?.toString() ?? '',
      sender: sender,
      type: MessageType.fromString(json['type']),
      content: json['content'] ?? '',
      fileUrl: json['file_url'] ?? json['fileUrl'],
      mimeType: json['mime_type'] ?? json['mimeType'],
      fileSize: json['file_size'] ?? json['fileSize'],
      width: json['width'],
      height: json['height'],
      duration: json['duration'],
      replyTo: json['reply_to'] ?? json['replyTo'],
      replyToMessage: replyToMessage,
      isPinned: json['is_pinned'] == true || json['isPinned'] == true,
      edited: json['edited'] == true || json['is_edited'] == true,
      deleted: json['deleted'] == true || json['is_deleted'] == true,
      createdAt: json['created_at'] ?? json['createdAt'] ?? DateTime.now().toIso8601String(),
      attachments: attachments,
      reactions: reactions,
      viewsCount: (json['views_count'] ?? json['viewsCount'] ?? 0) is int
          ? json['views_count'] ?? json['viewsCount'] ?? 0
          : int.tryParse((json['views_count'] ?? json['viewsCount'] ?? 0).toString()) ?? 0,
      forwardsCount: (json['forwards_count'] ?? json['forwardsCount'] ?? 0) is int
          ? json['forwards_count'] ?? json['forwardsCount'] ?? 0
          : int.tryParse((json['forwards_count'] ?? json['forwardsCount'] ?? 0).toString()) ?? 0,
    );
  }

  bool get hasAttachments => attachments.isNotEmpty;
  bool get isSending => id <= 0;
  bool get isFailed => false;

  String get timeFormatted {
    try {
      final date = DateTime.parse(createdAt);
      return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return '';
    }
  }
}