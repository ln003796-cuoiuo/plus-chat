import 'user.dart';

enum MessageType {
  text,
  photo,
  video,
  voice,
  videoNote,
  file,
  location,
  contact,
  poll,
  sticker,
  gift;

  static MessageType fromString(String? value) {
    switch (value) {
      case 'photo':
        return MessageType.photo;
      case 'video':
        return MessageType.video;
      case 'voice':
        return MessageType.voice;
      case 'video_note':
        return MessageType.videoNote;
      case 'file':
        return MessageType.file;
      case 'location':
        return MessageType.location;
      case 'contact':
        return MessageType.contact;
      case 'poll':
        return MessageType.poll;
      case 'sticker':
        return MessageType.sticker;
      case 'gift':
        return MessageType.gift;
      default:
        return MessageType.text;
    }
  }

  String get label {
    switch (this) {
      case MessageType.text:
        return 'Текст';
      case MessageType.photo:
        return '📷 Фото';
      case MessageType.video:
        return '🎥 Видео';
      case MessageType.voice:
        return '🎤 Голосовое';
      case MessageType.videoNote:
        return '📹 Видео-кружок';
      case MessageType.file:
        return '📄 Файл';
      case MessageType.location:
        return '📍 Геолокация';
      case MessageType.contact:
        return '👤 Контакт';
      case MessageType.poll:
        return '📊 Опрос';
      case MessageType.sticker:
        return '🎨 Стикер';
      case MessageType.gift:
        return '🎁 Подарок';
    }
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

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'file_type': fileType,
      'file_url': fileUrl,
      'thumbnail_url': thumbnailUrl,
      'file_name': fileName,
      'file_size': fileSize,
      'mime_type': mimeType,
      'width': width,
      'height': height,
      'duration': duration,
    };
  }

  // Размер файла в читаемом виде
  String get fileSizeFormatted {
    if (fileSize == null) return '';
    final size = fileSize!;
    if (size < 1024) return '$size Б';
    if (size < 1024 * 1024) return '${(size / 1024).toStringAsFixed(1)} КБ';
    if (size < 1024 * 1024 * 1024) {
      return '${(size / (1024 * 1024)).toStringAsFixed(1)} МБ';
    }
    return '${(size / (1024 * 1024 * 1024)).toStringAsFixed(1)} ГБ';
  }

  // Длительность в формате MM:SS
  String get durationFormatted {
    if (duration == null) return '';
    final d = duration!;
    final min = d ~/ 60;
    final sec = d % 60;
    return '${min.toString().padLeft(2, '0')}:${sec.toString().padLeft(2, '0')}';
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

  // Локальные поля (не из API)
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

  factory Message.fromJson(Map<String, dynamic> json) {
    User? sender;
    if (json['sender_id'] != null) {
      sender = User(
        id: json['sender_id'],
        firstName: json['sender_first_name'] ?? '',
        lastName: json['sender_last_name'],
        avatarUrl: json['sender_avatar'],
        username: json['sender_username'],
      );
    }

    Message? replyTo;
    if (json['reply_to'] != null) {
      replyTo = Message.fromJson(json['reply_to']);
    }

    List<MessageAttachment> attachments = [];
    if (json['attachments'] != null && json['attachments'] is List) {
      attachments = (json['attachments'] as List)
          .map((a) => MessageAttachment.fromJson(a))
          .toList();
    }

    List<MessageReaction> reactions = [];
    if (json['reactions'] != null && json['reactions'] is List) {
      reactions = (json['reactions'] as List)
          .map((r) => MessageReaction.fromJson(r))
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
      createdAt: json['created_at'] ?? '',
      attachments: attachments,
      reactions: reactions,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'chat_id': chatId,
      'sender_id': senderId,
      'reply_to_message_id': replyToMessageId,
      'type': type.name,
      'content': content,
      'edited': edited,
      'edited_at': editedAt,
      'deleted_for_all': deletedForAll,
      'views_count': viewsCount,
      'forwards_count': forwardsCount,
      'is_pinned': isPinned,
      'created_at': createdAt,
      'attachments': attachments.map((a) => a.toJson()).toList(),
    };
  }

  // Проверка, прочитано ли сообщение
  bool isReadBy(String userId) {
    // В реальной реализации нужно получать из API
    return false;
  }

  // Время в формате HH:MM
  String get timeFormatted {
    try {
      final dt = DateTime.parse(createdAt);
      return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return '';
    }
  }

  // Дата в формате ДД.ММ.ГГГГ
  String get dateFormatted {
    try {
      final dt = DateTime.parse(createdAt);
      return '${dt.day.toString().padLeft(2, '0')}.${dt.month.toString().padLeft(2, '0')}.${dt.year}';
    } catch (_) {
      return '';
    }
  }

  // Дата и время вместе
  String get dateTimeFormatted => '$dateFormatted $timeFormatted';

  // Относительное время ("только что", "5 мин назад")
  String get relativeTime {
    try {
      final dt = DateTime.parse(createdAt);
      final diff = DateTime.now().difference(dt);

      if (diff.inSeconds < 60) return 'только что';
      if (diff.inMinutes < 60) return '${diff.inMinutes} мин назад';
      if (diff.inHours < 24) return '${diff.inHours} ч назад';
      if (diff.inDays < 7) return '${diff.inDays} дн назад';
      return dateFormatted;
    } catch (_) {
      return '';
    }
  }

  // Есть ли вложения
  bool get hasAttachments => attachments.isNotEmpty;

  // Главное вложение (для превью)
  MessageAttachment? get mainAttachment =>
      attachments.isNotEmpty ? attachments.first : null;

  // Копирование с изменением полей (для локальных состояний)
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
}