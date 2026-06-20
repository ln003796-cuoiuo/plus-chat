enum ChatType {
  private,
  group,
  channel;

  static ChatType fromString(String? type) {
    switch (type) {
      case 'group':
        return ChatType.group;
      case 'channel':
        return ChatType.channel;
      default:
        return ChatType.private;
    }
  }

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

class Chat {
  final String id;
  final ChatType type;
  final String? title;
  final String? description;
  final String? avatarUrl;
  final String? createdBy;
  final bool isPublic;
  final String? inviteLink;
  final int membersCount;
  final int unreadCount;
  final String? lastMessage;
  final String? lastMessageType;
  final String? lastMessageAt;
  final bool isMuted;
  final String? mutedUntil;
  final bool isArchived;
  final bool isFavorite;
  final bool hasPinned;
  final String? myRole;
  final String? companionId;
  final String? companionFirstName;
  final String? companionLastName;
  final String? companionUsername;
  final String? companionAvatar;
  final bool isCompanionOnline;
  final String? companionLastSeen;

  Chat({
    required this.id,
    required this.type,
    this.title,
    this.description,
    this.avatarUrl,
    this.createdBy,
    this.isPublic = false,
    this.inviteLink,
    this.membersCount = 0,
    this.unreadCount = 0,
    this.lastMessage,
    this.lastMessageType,
    this.lastMessageAt,
    this.isMuted = false,
    this.mutedUntil,
    this.isArchived = false,
    this.isFavorite = false,
    this.hasPinned = false,
    this.myRole,
    this.companionId,
    this.companionFirstName,
    this.companionLastName,
    this.companionUsername,
    this.companionAvatar,
    this.isCompanionOnline = false,
    this.companionLastSeen,
  });

  String get displayName {
    if (type == ChatType.private) {
      final name = '${companionFirstName ?? ''} ${companionLastName ?? ''}'.trim();
      return name.isNotEmpty ? name : (companionUsername ?? 'Пользователь');
    }
    return title ?? 'Без названия';
  }

  String get initial {
    final name = displayName;
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }

  String get lastMessageTimeFormatted {
    if (lastMessageAt == null) return '';
    try {
      final dt = DateTime.parse(lastMessageAt!);
      final now = DateTime.now();
      final diff = now.difference(dt);
      if (diff.inDays == 0) {
        return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
      } else if (diff.inDays == 1) {
        return 'Вчера';
      } else if (diff.inDays < 7) {
        return '${diff.inDays} дн.';
      } else {
        return '${dt.day.toString().padLeft(2, '0')}.${dt.month.toString().padLeft(2, '0')}';
      }
    } catch (_) {
      return '';
    }
  }

  factory Chat.fromJson(Map<String, dynamic> json) {
    return Chat(
      id: json['id'] ?? '',
      type: ChatType.fromString(json['type']),
      title: json['title'],
      description: json['description'],
      avatarUrl: json['avatar_url'],
      createdBy: json['created_by'],
      isPublic: json['is_public'] == 1 || json['is_public'] == true,
      inviteLink: json['invite_link'],
      membersCount: json['members_count'] ?? 0,
      unreadCount: json['unread_count'] ?? 0,
      lastMessage: json['last_message'],
      lastMessageType: json['last_message_type'],
      lastMessageAt: json['last_message_at'],
      isMuted: json['is_muted'] == 1 || json['is_muted'] == true,
      mutedUntil: json['muted_until'],
      isArchived: json['is_archived'] == 1 || json['is_archived'] == true,
      isFavorite: json['is_favorite'] == 1 || json['is_favorite'] == true,
      hasPinned: json['has_pinned'] == 1 || json['has_pinned'] == true,
      myRole: json['my_role'],
      companionId: json['companion']?['id'],
      companionFirstName: json['companion']?['first_name'],
      companionLastName: json['companion']?['last_name'],
      companionUsername: json['companion']?['username'],
      companionAvatar: json['companion']?['avatar_url'],
      isCompanionOnline: json['companion']?['is_online'] == true,
      companionLastSeen: json['companion']?['last_seen'],
    );
  }
}