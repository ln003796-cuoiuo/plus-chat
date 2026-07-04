class Chat {
  final String id;
  final String type;
  final String? title;
  final String? description;
  final String? avatarUrl;
  final String? companionId;
  final String? companionName;
  final String? companionUsername;
  final String? companionAvatarUrl;
  final bool isOnline;
  final String? lastMessage;
  final String? lastMessageAt;
  final String? lastMessageSenderName;
  final int unreadCount;
  final bool isMuted;
  final bool isArchived;
  final bool isFavorite;
  final bool isPinned;
  final int membersCount;

  Chat({
    required this.id,
    required this.type,
    this.title,
    this.description,
    this.avatarUrl,
    this.companionId,
    this.companionName,
    this.companionUsername,
    this.companionAvatarUrl,
    this.isOnline = false,
    this.lastMessage,
    this.lastMessageAt,
    this.lastMessageSenderName,
    this.unreadCount = 0,
    this.isMuted = false,
    this.isArchived = false,
    this.isFavorite = false,
    this.isPinned = false,
    this.membersCount = 0,
  });

  factory Chat.fromJson(Map<String, dynamic> json) {
    final companion = json['companion'] as Map<String, dynamic>?;
    return Chat(
      id: json['id']?.toString() ?? '',
      type: json['type'] ?? 'private',
      title: json['title'],
      description: json['description'],
      avatarUrl: json['avatar_url'] ?? json['avatarUrl'],
      companionId: companion?['id']?.toString(),
      companionName: companion != null
          ? '${companion['first_name'] ?? ''} ${companion['last_name'] ?? ''}'.trim()
          : json['display_name'],
      companionUsername: companion?['username'],
      companionAvatarUrl: companion?['avatar_url'] ?? companion?['avatarUrl'],
      isOnline: companion?['is_online'] == true || companion?['online_status'] == 'online',
      lastMessage: json['last_message'],
      lastMessageAt: json['last_message_at'] ?? json['lastMessageAt'],
      lastMessageSenderName: json['last_message_sender_name'],
      unreadCount: (json['unread_count'] ?? json['unreadCount'] ?? 0) is int
          ? json['unread_count'] ?? json['unreadCount'] ?? 0
          : int.tryParse((json['unread_count'] ?? json['unreadCount'] ?? 0).toString()) ?? 0,
      isMuted: json['is_muted'] == true || json['isMuted'] == true,
      isArchived: json['is_archived'] == true || json['isArchived'] == true,
      isFavorite: json['is_favorite'] == true || json['isFavorite'] == true,
      isPinned: json['is_pinned'] == true || json['isPinned'] == true,
      membersCount: (json['members_count'] ?? json['membersCount'] ?? 0) is int
          ? json['members_count'] ?? json['membersCount'] ?? 0
          : int.tryParse((json['members_count'] ?? json['membersCount'] ?? 0).toString()) ?? 0,
    );
  }

  String get displayName {
    if (type == 'private') {
      return companionName ?? companionUsername ?? 'Пользователь';
    }
    return title ?? 'Без названия';
  }

  String get initial {
    if (type == 'private') {
      if (companionName != null && companionName!.isNotEmpty) {
        final parts = companionName!.split(' ');
        return parts.first.isNotEmpty ? parts.first[0].toUpperCase() : '?';
      }
      if (companionUsername != null && companionUsername!.isNotEmpty) {
        return companionUsername![0].toUpperCase();
      }
      return '?';
    }
    if (title != null && title!.isNotEmpty) {
      return title![0].toUpperCase();
    }
    return '?';
  }

  String get lastMessageTimeFormatted {
    if (lastMessageAt == null) return '';
    try {
      final date = DateTime.parse(lastMessageAt!);
      final now = DateTime.now();
      final diff = now.difference(date);
      if (diff.inDays == 0) {
        return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
      } else if (diff.inDays == 1) {
        return 'Вчера';
      } else if (diff.inDays < 7) {
        const days = ['Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Сб', 'Вс'];
        return days[date.weekday - 1];
      } else {
        return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}';
      }
    } catch (_) {
      return '';
    }
  }

  ChatType get chatType {
    switch (type) {
      case 'group':
        return ChatType.group;
      case 'channel':
        return ChatType.channel;
      default:
        return ChatType.private;
    }
  }
}

enum ChatType {
  private,
  group,
  channel;

  String get label {
    switch (this) {
      case ChatType.private:
        return 'Личный';
      case ChatType.group:
        return 'Группа';
      case ChatType.channel:
        return 'Канал';
    }
  }
}