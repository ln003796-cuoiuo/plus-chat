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

  String get label {
    switch (this) {
      case MessageType.text:
        return 'Текст';
      case MessageType.voice:
        return '🎤 Голосовое';
      case MessageType.video:
        return '🎥 Видео';
      case MessageType.photo:
        return '📷 Фото';
      case MessageType.file:
        return '📄 Файл';
      case MessageType.gif:
        return '🎞️ GIF';
      case MessageType.sticker:
        return ' Стикер';
      case MessageType.gift:
        return '🎁 Подарок';
      case MessageType.location:
        return '📍 Геолокация';
      case MessageType.contact:
        return '👤 Контакт';
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
      count: json['count'] ?? 0,
      hasMyReaction: json['has_my_reaction'] == true,
    );
  }
}

class Message {
  final int id;
  final String chatId;
  final String senderId;
  final User? sender;
  final int? replyToMessageId;
  final Message? replyToMessage;
  final MessageType type;
  final String content;
  final bool edited;
  final String? editedAt;
  final bool deletedForAll;
  final int viewsCount;
  final int forwardsCount;
  final bool isPinned;
  final String createdAt;
  final List<MessageAttachment> attachments;
  final List<MessageReaction> reactions;
  final bool isSending;
  final bool isFailed;

  Message({
    required this.id,
    required this.chatId,
    required this.senderId,
    this.sender,
    this.replyToMessageId,
    this.replyToMessage,
    this.type = MessageType.text,
    required this.content,
    this.edited = false,
    this.editedAt,
    this.deletedForAll = false,
    this.viewsCount = 0,
    this.forwardsCount = 0,
    this.isPinned = false,
    required this.createdAt,
    this.attachments = const [],
    this.reactions = const [],
    this.isSending = false,
    this.isFailed = false,
  });

  bool get hasAttachments => attachments.isNotEmpty;
  MessageAttachment? get mainAttachment => attachments.isNotEmpty ? attachments.first : null;

  String get timeFormatted {
    try {
      final dt = DateTime.parse(createdAt);
      return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return '';
    }
  }

  Message copyWith({
    int? id,
    String? content,
    bool? edited,
    bool? isSending,
    bool? isFailed,
    List<MessageReaction>? reactions,
  }) {
    return Message(
      id: id ?? this.id,
      chatId: chatId,
      senderId: senderId,
      sender: sender,
      replyToMessageId: replyToMessageId,
      replyToMessage: replyToMessage,
      type: type,
      content: content ?? this.content,
      edited: edited ?? this.edited,
      editedAt: editedAt,
      deletedForAll: deletedForAll,
      viewsCount: viewsCount,
      forwardsCount: forwardsCount,
      isPinned: isPinned,
      createdAt: createdAt,
      attachments: attachments,
      reactions: reactions ?? this.reactions,
      isSending: isSending ?? this.isSending,
      isFailed: isFailed ?? this.isFailed,
    );
  }

  factory Message.fromJson(Map<String, dynamic> json) {
    User? sender;
    if (json['sender_id'] != null) {
      sender = User(
        id: json['sender_id'],
        firstName: json['sender_first_name'] ?? '',
        lastName: json['sender_last_name'] ?? '',
        avatarUrl: json['sender_avatar'],
        username: json['sender_username'] ?? '',
        email: '',
      );
    }

    Message? replyTo;
    if (json['reply_to'] != null && json['reply_to'] is Map) {
      replyTo = Message.fromJson(json['reply_to']);
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
      id: json['id'] ?? 0,
      chatId: json['chat_id'] ?? '',
      senderId: json['sender_id'] ?? '',
      sender: sender,
      replyToMessageId: json['reply_to_message_id'],
      replyToMessage: replyTo,
      type: MessageType.fromString(json['type']),
      content: json['content'] ?? '',
      edited: json['edited'] == true,
      editedAt: json['edited_at'],
      deletedForAll: json['deleted_for_all'] == true,
      viewsCount: json['views_count'] ?? 0,
      forwardsCount: json['forwards_count'] ?? 0,
      isPinned: json['is_pinned'] == true,
      createdAt: json['created_at'] ?? DateTime.now().toIso8601String(),
      attachments: attachments,
      reactions: reactions,
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
      id: json['id'] ?? 0,
      fileType: json['file_type'] ?? 'file',
      fileUrl: json['file_url'] ?? '',
      thumbnailUrl: json['thumbnail_url'],
      fileName: json['file_name'],
      fileSize: json['file_size'],
      mimeType: json['mime_type'],
      width: json['width'],
      height: json['height'],
      duration: json['duration'],
    );
  }
}