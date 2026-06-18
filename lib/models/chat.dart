import 'user.dart';

enum ChatType {
  private,
  group,
  channel;

  static ChatType fromString(String? value) {
    switch (value) {
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
        return 'Личный чат';
      case ChatType.group:
        return 'Группа';
      case ChatType.channel:
        return 'Канал';
    }
  }
}

enum MemberRole {
  owner,
  admin,
  moderator,
  member;

  static MemberRole fromString(String? value) {
    switch (value) {
      case 'owner':
        return MemberRole.owner;
      case 'admin':
        return MemberRole.admin;
      case 'moderator':
        return MemberRole.moderator;
      default:
        return MemberRole.member;
    }
  }
}

class ChatMember {
  final User user;
  final MemberRole role;
  final String joinedAt;

  ChatMember({
    required this.user,
    required this.role,
    required this.joinedAt,
  });

  factory ChatMember.fromJson(Map<String, dynamic> json) {
    return ChatMember(
      user: User.fromJson(json),
      role: MemberRole.fromString(json['role']),
      joinedAt: json['joined_at'] ?? '',
    );
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
  final int maxMembers;
  final bool isVerified;
  final String createdAt;

  // Для личных чатов — собеседник
  final User? companion;

  // Для групповых — участники
  final List<ChatMember> members;

  // Метаданные для списка чатов
  final String? lastMessage;
  final String? lastMessageAt;
  final int unreadCount;
  final bool isMuted;
  final MemberRole? myRole;

  Chat({
    required this.id,
    required this.type,
    this.title,
    this.description,
    this.avatarUrl,
    this.createdBy,
    this.isPublic = false,
    this.inviteLink,
    this.maxMembers = 500,
    this.isVerified = false,
    required this.createdAt,
    this.companion,
    this.members = const [],
    this.lastMessage,
    this.lastMessageAt,
    this.unreadCount = 0,
    this.isMuted = false,
    this.myRole,
  });

  factory Chat.fromJson(Map<String, dynamic> json) {
    // Парсим собеседника для личных чатов
    User? companion;
    if (json['companion'] != null) {
      companion = User.fromJson(json['companion']);
    }

    // Парсим участников
    List<ChatMember> members = [];
    if (json['members'] != null && json['members'] is List) {
      members = (json['members'] as List)
          .map((m) => ChatMember.fromJson(m))
          .toList();
    }

    return Chat(
      id: json['id'] ?? '',
      type: ChatType.fromString(json['type']),
      title: json['title'],
      description: json['description'],
      avatarUrl: json['avatar_url'],
      createdBy: json['created_by'],
      isPublic: json['is_public'] == true,
      inviteLink: json['invite_link'],
      maxMembers: json['max_members'] ?? 500,
      isVerified: json['is_verified'] == true,
      createdAt: json['created_at'] ?? '',
      companion: companion,
      members: members,
      lastMessage: json['last_message'],
      lastMessageAt: json['last_message_at'],
      unreadCount: json['unread_count'] ?? 0,
      isMuted: json['muted_until'] != null,
      myRole: json['role'] != null ? MemberRole.fromString(json['role']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.name,
      'title': title,
      'description': description,
      'avatar_url': avatarUrl,
      'created_by': createdBy,
      'is_public': isPublic,
      'invite_link': inviteLink,
      'max_members': maxMembers,
      'is_verified': isVerified,
      'created_at': createdAt,
      'companion': companion?.toJson(),
      'members': members.map((m) => {
        ...m.user.toJson(),
        'role': m.role.name,
        'joined_at': m.joinedAt,
      }).toList(),
      'last_message': lastMessage,
      'last_message_at': lastMessageAt,
      'unread_count': unreadCount,
    };
  }

  // Отображаемое имя чата
  String get displayName {
    if (type == ChatType.private) {
      return companion?.displayName ?? 'Личный чат';
    }
    return title ?? 'Без названия';
  }

  // Первая буква для аватара
  String get initial {
    final name = displayName;
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }

  // Онлайн ли собеседник (для личных чатов)
  bool get isCompanionOnline => companion?.isOnline ?? false;

  // Количество участников
  int get membersCount => members.length;

  // Форматированное время последнего сообщения
  String get lastMessageTime {
    if (lastMessageAt == null) return '';
    try {
      final dt = DateTime.parse(lastMessageAt!);
      final now = DateTime.now();
      final diff = now.difference(dt);

      if (diff.inMinutes < 1) return 'только что';
      if (diff.inHours < 1) return '${diff.inMinutes} мин';
      if (diff.inDays < 1) {
        return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
      }
      if (diff.inDays < 7) {
        const days = ['пн', 'вт', 'ср', 'чт', 'пт', 'сб', 'вс'];
        return days[dt.weekday - 1];
      }
      return '${dt.day.toString().padLeft(2, '0')}.${dt.month.toString().padLeft(2, '0')}.${dt.year}';
    } catch (_) {
      return '';
    }
  }

  Chat copyWith({
    String? title,
    String? avatarUrl,
    String? lastMessage,
    String? lastMessageAt,
    int? unreadCount,
    User? companion,
  }) {
    return Chat(
      id: id,
      type: type,
      title: title ?? this.title,
      description: description,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      createdBy: createdBy,
      isPublic: isPublic,
      inviteLink: inviteLink,
      maxMembers: maxMembers,
      isVerified: isVerified,
      createdAt: createdAt,
      companion: companion ?? this.companion,
      members: members,
      lastMessage: lastMessage ?? this.lastMessage,
      lastMessageAt: lastMessageAt ?? this.lastMessageAt,
      unreadCount: unreadCount ?? this.unreadCount,
      isMuted: isMuted,
      myRole: myRole,
    );
  }
}