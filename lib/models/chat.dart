// lib/models/chat.dart
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'user.dart'; // Импортируем User

class Chat {
  final String id;
  final String type; // private, group, channel
  final String? title; // может быть null для приватных чатов
  final String? description;
  final String? avatarUrl;
  // --- ИСПРАВЛЕНО: тип members ---
  final List<User>? members; // может быть null для каналов/ботов?
  // --- /ИСПРАВЛЕНО ---
  final int unreadCount;
  final String lastMessageText;
  final String lastMessageTime;
  final bool isOnline; // для приватных чатов

  // --- ДОБАВЛЕНО: отсутствующие поля ---
  final bool isMuted;
  final bool isArchived;
  final bool isFavorite;
  final String? mutedUntil;
  final int? lastReadMessageId;
  // --- /ДОБАВЛЕНО ---

  Chat({
    required this.id,
    required this.type,
    this.title,
    this.description,
    this.avatarUrl,
    this.members,
    required this.unreadCount,
    required this.lastMessageText,
    required this.lastMessageTime,
    required this.isOnline,
    // --- ИНИЦИАЛИЗАЦИЯ новых полей ---
    this.isMuted = false,
    this.isArchived = false,
    this.isFavorite = false,
    this.mutedUntil,
    this.lastReadMessageId,
    // --- /ИНИЦИАЛИЗАЦИЯ ---
  });

  factory Chat.fromJson(Map<String, dynamic> json) {
    return Chat(
      id: json['id'] as String,
      type: json['type'] as String,
      title: json['title'] as String?,
      description: json['description'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      // --- ИСПРАВЛЕНО: десериализация members ---
      members: (json['members'] as List<dynamic>?)
          ?.map((memberJson) => User.fromJson(memberJson))
          .toList(),
      // --- /ИСПРАВЛЕНО ---
      unreadCount: json['unread_count'] as int? ?? 0,
      lastMessageText: json['last_message_text'] as String? ?? '',
      lastMessageTime: json['last_message_time'] as String? ?? '',
      isOnline: json['is_online'] as bool? ?? false,
      // --- ЧТЕНИЕ новых полей из JSON ---
      isMuted: json['is_muted'] as bool? ?? false,
      isArchived: json['is_archived'] as bool? ?? false,
      isFavorite: json['is_favorite'] as bool? ?? false,
      mutedUntil: json['muted_until'] as String?,
      lastReadMessageId: json['last_read_message_id'] as int?,
      // --- /ЧТЕНИЕ ---
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'title': title,
      'description': description,
      'avatar_url': avatarUrl,
      // --- ИСПРАВЛЕНО: сериализация members ---
      'members': members?.map((member) => member.toJson()).toList(),
      // --- /ИСПРАВЛЕНО ---
      'unread_count': unreadCount,
      'last_message_text': lastMessageText,
      'last_message_time': lastMessageTime,
      'is_online': isOnline,
      // --- ЗАПИСЬ новых полей в JSON ---
      'is_muted': isMuted,
      'is_archived': isArchived,
      'is_favorite': isFavorite,
      'muted_until': mutedUntil,
      'last_read_message_id': lastReadMessageId,
      // --- /ЗАПИСЬ ---
    };
  }

  // --- ДОБАВЛЕНО: метод copyWith ---
  Chat copyWith({
    String? id,
    String? type,
    String? title,
    String? description,
    String? avatarUrl,
    List<User>? members,
    int? unreadCount,
    String? lastMessageText,
    String? lastMessageTime,
    bool? isOnline,
    bool? isMuted,
    bool? isArchived,
    bool? isFavorite,
    String? mutedUntil,
    int? lastReadMessageId,
  }) {
    return Chat(
      id: id ?? this.id,
      type: type ?? this.type,
      title: title ?? this.title,
      description: description ?? this.description,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      members: members ?? this.members,
      unreadCount: unreadCount ?? this.unreadCount,
      lastMessageText: lastMessageText ?? this.lastMessageText,
      lastMessageTime: lastMessageTime ?? this.lastMessageTime,
      isOnline: isOnline ?? this.isOnline,
      isMuted: isMuted ?? this.isMuted,
      isArchived: isArchived ?? this.isArchived,
      isFavorite: isFavorite ?? this.isFavorite,
      mutedUntil: mutedUntil ?? this.mutedUntil,
      lastReadMessageId: lastReadMessageId ?? this.lastReadMessageId,
    );
  }
  // --- /ДОБАВЛЕНО ---

  @override
  String toString() {
    return 'Chat{id: $id, type: $type, title: $title, unreadCount: $unreadCount, lastMessageText: $lastMessageText, isMuted: $isMuted, isArchived: $isArchived, isFavorite: $isFavorite, lastReadMessageId: $lastReadMessageId}';
  }
}