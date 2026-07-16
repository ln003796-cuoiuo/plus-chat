// lib/models/user.dart
import 'dart:convert';
import 'package:flutter/foundation.dart';

class User {
  final String id;
  final String? email;
  final String? username;
  final String firstName;
  final String? lastName;
  final String? middleName;
  final String? nickname;
  final String? bio;
  final String? birthDate;
  final String? avatarUrl;
  final String? avatarThumbUrl;
  final String? avatarColor;
  final String? avatarEmoji;
  final String? bannerUrl;
  final String? country;
  final String? city;
  final String? timezone;
  final String? language;
  final String onlineStatus;
  final String? lastSeen;
  final String? customStatusText;
  final String? customStatusEmoji;
  final String premiumStatus;
  final bool isHidden;
  final int plusCoins;
  final int giftsReceivedCount;
  final int giftsSentCount;
  final int totalGiftsValue;
  final String? createdAt;
  final String? website;
  final String? instagram;
  final String? telegram;
  final String? twitter;
  final String? github;
  final String? linkedin;

  // --- НОВОЕ ПОЛЕ ---
  final int? lastReadMessageId;
  // --- /НОВОЕ ПОЛЕ ---

  User({
    required this.id,
    this.email,
    this.username,
    required this.firstName,
    this.lastName,
    this.middleName,
    this.nickname,
    this.bio,
    this.birthDate,
    this.avatarUrl,
    this.avatarThumbUrl,
    this.avatarColor,
    this.avatarEmoji,
    this.bannerUrl,
    this.country,
    this.city,
    this.timezone,
    this.language,
    this.onlineStatus = 'offline',
    this.lastSeen,
    this.customStatusText,
    this.customStatusEmoji,
    this.premiumStatus = 'free',
    this.isHidden = false,
    this.plusCoins = 0,
    this.giftsReceivedCount = 0,
    this.giftsSentCount = 0,
    this.totalGiftsValue = 0,
    this.createdAt,
    this.website,
    this.instagram,
    this.telegram,
    this.twitter,
    this.github,
    this.linkedin,
    // --- ИНИЦИАЛИЗАЦИЯ НОВОГО ПОЛЯ ---
    this.lastReadMessageId,
    // --- /ИНИЦИАЛИЗАЦИЯ ---
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id']?.toString() ?? '',
      email: json['email'],
      username: json['username'],
      firstName: json['first_name'] ?? json['firstName'] ?? '',
      lastName: json['last_name'] ?? json['lastName'],
      middleName: json['middle_name'] ?? json['middleName'],
      nickname: json['nickname'],
      bio: json['bio'],
      birthDate: json['birth_date'] ?? json['birthDate'],
      avatarUrl: json['avatar_url'] ?? json['avatarUrl'],
      avatarThumbUrl: json['avatar_thumb_url'] ?? json['avatarThumbUrl'],
      avatarColor: json['avatar_color'] ?? json['avatarColor'],
      avatarEmoji: json['avatar_emoji'] ?? json['avatarEmoji'],
      bannerUrl: json['banner_url'] ?? json['bannerUrl'],
      country: json['country'],
      city: json['city'],
      timezone: json['timezone'],
      language: json['language'],
      onlineStatus: json['online_status'] ?? json['is_online'] == true ? 'online' : 'offline',
      lastSeen: json['last_seen'] ?? json['lastSeen'],
      customStatusText: json['custom_status_text'] ?? json['customStatusText'],
      customStatusEmoji: json['custom_status_emoji'] ?? json['customStatusEmoji'],
      premiumStatus: json['premium_status'] != null
        ? json['premium_status']
        : (json['is_premium'] == true ? 'premium' : 'free'),
      isHidden: json['is_hidden'] == true || json['isHidden'] == true,
      plusCoins: (json['plus_coins'] ?? json['plusCoins'] ?? 0) is int
          ? json['plus_coins'] ?? json['plusCoins'] ?? 0
          : int.tryParse((json['plus_coins'] ?? json['plusCoins'] ?? 0).toString()) ?? 0,
      giftsReceivedCount: (json['gifts_received_count'] ?? json['giftsReceivedCount'] ?? 0) is int
          ? json['gifts_received_count'] ?? json['giftsReceivedCount'] ?? 0
          : int.tryParse((json['gifts_received_count'] ?? json['giftsReceivedCount'] ?? 0).toString()) ?? 0,
      giftsSentCount: (json['gifts_sent_count'] ?? json['giftsSentCount'] ?? 0) is int
          ? json['gifts_sent_count'] ?? json['giftsSentCount'] ?? 0
          : int.tryParse((json['gifts_sent_count'] ?? json['giftsSentCount'] ?? 0).toString()) ?? 0,
      totalGiftsValue: (json['total_gifts_value'] ?? json['totalGiftsValue'] ?? 0) is int
          ? json['total_gifts_value'] ?? json['totalGiftsValue'] ?? 0
          : int.tryParse((json['total_gifts_value'] ?? json['totalGiftsValue'] ?? 0).toString()) ?? 0,
      createdAt: json['created_at'] ?? json['createdAt'],
      website: json['website'],
      instagram: json['instagram'],
      telegram: json['telegram'],
      twitter: json['twitter'],
      github: json['github'],
      linkedin: json['linkedin'],
      // --- ЧТЕНИЕ НОВОГО ПОЛЯ ИЗ JSON ---
      lastReadMessageId: json['last_read_message_id'] as int?,
      // --- /ЧТЕНИЕ ---
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'username': username,
      'first_name': firstName,
      'last_name': lastName,
      'middle_name': middleName,
      'nickname': nickname,
      'bio': bio,
      'birth_date': birthDate,
      'avatar_url': avatarUrl,
      'avatar_thumb_url': avatarThumbUrl,
      'avatar_color': avatarColor,
      'avatar_emoji': avatarEmoji,
      'banner_url': bannerUrl,
      'country': country,
      'city': city,
      'timezone': timezone,
      'language': language,
      'online_status': onlineStatus,
      'last_seen': lastSeen,
      'custom_status_text': customStatusText,
      'custom_status_emoji': customStatusEmoji,
      'premium_status': premiumStatus,
      'plus_coins': plusCoins,
      'gifts_received_count': giftsReceivedCount,
      'gifts_sent_count': giftsSentCount,
      'total_gifts_value': totalGiftsValue,
      'created_at': createdAt,
      'website': website,
      'instagram': instagram,
      'telegram': telegram,
      'twitter': twitter,
      'github': github,
      'linkedin': linkedin,
      // --- ЗАПИСЬ НОВОГО ПОЛЯ В JSON ---
      'last_read_message_id': lastReadMessageId,
      // --- /ЗАПИСЬ ---
    };
  }

  String get displayName {
    final parts = [firstName, lastName].where((p) => p != null && p.isNotEmpty);
    return parts.isEmpty ? (username ?? 'Пользователь') : parts.join(' ');
  }

  String get initials {
    final first = firstName.isNotEmpty ? firstName[0].toUpperCase() : '';
    final last = (lastName?.isNotEmpty ?? false) ? lastName![0].toUpperCase() : '';
    return (first + last).isEmpty ? '?' : first + last;
  }

  bool get isOnline => onlineStatus == 'online';
  bool get isPremium => premiumStatus != 'free';

  // --- ОБНОВЛЁН МЕТОД copyWith ---
  User copyWith({
    String? id,
    String? email,
    String? username,
    String? firstName,
    String? lastName,
    String? bio,
    String? avatarUrl,
    String? onlineStatus,
    int? plusCoins,
    // --- ДОБАВЛЕН ПАРАМЕТР ---
    int? lastReadMessageId,
    // --- /ДОБАВЛЕН ПАРАМЕТР ---
  }) {
    return User(
      id: id ?? this.id,
      email: email ?? this.email,
      username: username ?? this.username,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      bio: bio ?? this.bio,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      onlineStatus: onlineStatus ?? this.onlineStatus,
      plusCoins: plusCoins ?? this.plusCoins,
      // --- ПЕРЕДАЁМ НОВОЕ ЗНАЧЕНИЕ ---
      lastReadMessageId: lastReadMessageId ?? this.lastReadMessageId,
      // --- /ПЕРЕДАЁМ ---
      middleName: middleName,
      nickname: nickname,
      birthDate: birthDate,
      avatarThumbUrl: avatarThumbUrl,
      avatarColor: avatarColor,
      avatarEmoji: avatarEmoji,
      bannerUrl: bannerUrl,
      country: country,
      city: city,
      timezone: timezone,
      language: language,
      lastSeen: lastSeen,
      customStatusText: customStatusText,
      customStatusEmoji: customStatusEmoji,
      premiumStatus: premiumStatus,
      giftsReceivedCount: giftsReceivedCount,
      giftsSentCount: giftsSentCount,
      totalGiftsValue: totalGiftsValue,
      createdAt: createdAt,
      website: website,
      instagram: instagram,
      telegram: telegram,
      twitter: twitter,
      github: github,
      linkedin: linkedin,
    );
  }
  // --- /ОБНОВЛЁН МЕТОД ---
}