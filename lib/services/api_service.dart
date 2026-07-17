// lib/services/api_service.dart
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'auth_service.dart';
import '../models/user.dart';
import '../models/chat.dart';
import '../models/message.dart';
import '../models/poll.dart'; // Импортируем модель Poll (файл должен существовать)

class ApiService {
  // --- ИСПРАВЛЕНО: baseUrl (теперь точно соответствует https://xn--80avljg2a1c.xn--p1ai) ---
  static const String baseUrl = 'https://xn--80avljg2a1c.xn--p1ai';
  // --- /ИСПРАВЛЕНО ---

  static Future<Map<String, dynamic>> _request(String method,
      String endpoint, {
        Map<String, dynamic>? body,
        bool auth = true,
      }) async {
    final url = Uri.parse('$baseUrl$endpoint');
    final headers = <String, String>{
      'Content-Type': 'application/json',
    };
    if (auth) {
      final token = await AuthService.getAccessToken();
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      } else {
        throw Exception('No access token available');
      }
    }

    http.Response response;
    if (body != null) {
      response = await http.post(url, headers: headers, body: jsonEncode(body));
    } else {
      if (method.toUpperCase() == 'GET') {
        response = await http.get(url, headers: headers);
      } else if (method.toUpperCase() == 'POST') {
        response = await http.post(url, headers: headers); // Bodyless POST
      } else {
        throw Exception('Unsupported method without body: $method');
      }
    }

    final responseBody = response.body;
    final responseJson = jsonDecode(responseBody);

    if (response.statusCode == 401) {
      // Token might be expired, try to refresh
      final refreshed = await AuthService.refreshToken();
      if (refreshed) {
        // Retry the request with the new token
        return _request(method, endpoint, body: body, auth: auth);
      } else {
        // Refresh failed, logout user
        await AuthService.logout();
        throw Exception('Authentication failed and refresh token invalid.');
      }
    }

    if (response.statusCode >= 400) {
      throw Exception(responseJson['error'] ?? 'Request failed with status ${response.statusCode}');
    }

    return responseJson;
  }

  // --- AUTH ---

  static Future<Map<String, dynamic>> login(String emailOrPhone) async {
    return _request('POST', '/auth/login', body: {'email_or_phone': emailOrPhone}, auth: false);
  }

  // --- ИСПРАВЛЕНО: метод для входа по паролю ---
  static Future<Map<String, dynamic>> loginWithPassword(String emailOrPhone, String password) async {
    // Предполагаем, что сервер принимает 'email_or_phone' и 'password' на эндпоинте /auth/login
    // Или на отдельном эндпоинте, например, /auth/login-password
    // Адаптируйте под реальный API сервера
    return _request('POST', '/auth/login', body: {'email_or_phone': emailOrPhone, 'password': password}, auth: false);
    // Или, если есть отдельный эндпоинт:
    // return _request('POST', '/auth/login-password', body: {'email_or_phone': emailOrPhone, 'password': password}, auth: false);
  }
  // --- /ИСПРАВЛЕНО ---

  static Future<Map<String, dynamic>> verifyCode(String emailOrPhone, String code) async {
    return _request('POST', '/auth/verify-code', body: {'email_or_phone': emailOrPhone, 'code': code}, auth: false);
  }

  static Future<Map<String, dynamic>> registerStep1(String email) async {
    return _request('POST', '/auth/register-step1', body: {'email': email}, auth: false);
  }

  static Future<Map<String, dynamic>> registerStep2(String email, String code) async {
    return _request('POST', '/auth/register-step2', body: {'email': email, 'code': code}, auth: false);
  }

  static Future<Map<String, dynamic>> registerStep3(String firstName, String lastName) async {
    return _request('POST', '/auth/register-step3', body: {'first_name': firstName, 'last_name': lastName}, auth: true);
  }

  static Future<Map<String, dynamic>> registerStep4(String username) async {
    return _request('POST', '/auth/register-step4', body: {'username': username}, auth: true);
  }

  static Future<Map<String, dynamic>> registerStep5(String password) async {
    return _request('POST', '/auth/register-step5', body: {'password': password}, auth: true);
  }

  static Future<Map<String, dynamic>> setupProfile(String firstName, String lastName, String username, String bio, String? avatarUrl) async {
    return _request('POST', '/users/setup-profile', body: {
      'first_name': firstName,
      'last_name': lastName,
      'username': username,
      'bio': bio,
      'avatar_url': avatarUrl,
    }, auth: true);
  }

  static Future<void> logout() async {
    try {
      await _request('POST', '/auth/logout', auth: true);
    } catch (e) {
      debugPrint('Logout error (ignored): $e');
    }
    await AuthService.logout();
  }

  static Future<Map<String, dynamic>> refreshToken() async {
    final refreshToken = await AuthService.getRefreshToken();
    if (refreshToken == null) {
      throw Exception('No refresh token available');
    }
    final res = await _request('POST', '/auth/refresh', body: {'refresh_token': refreshToken}, auth: false);
    await AuthService.saveTokens(res['access_token'], res['refresh_token']);
    return res;
  }

  // --- USERS ---

  static Future<User> getMe() async {
    final res = await _request('GET', '/users/me');
    return User.fromJson(res['user']);
  }

  static Future<Map<String, dynamic>> getUserById(int userId) async {
    final res = await _request('GET', '/users/$userId');
    return res;
  }

  static Future<Map<String, dynamic>> searchUsers(String query) async {
    final res = await _request('GET', '/users/search?q=$query');
    return res;
  }

  static Future<Map<String, dynamic>> updateUserProfile(Map<String, dynamic> profileData) async {
    return _request('POST', '/users/update-profile', body: profileData);
  }

  static Future<Map<String, dynamic>> changePassword(String currentPassword, String newPassword) async {
    return _request('POST', '/users/change-password', body: {
      'current_password': currentPassword,
      'new_password': newPassword,
    });
  }

  static Future<Map<String, dynamic>> uploadAvatar(String base64Image) async {
    return _request('POST', '/users/upload-avatar', body: {'image': base64Image});
  }

  static Future<Map<String, dynamic>> setCustomStatus(String text, String emoji) async {
    return _request('POST', '/users/set-custom-status', body: {'text': text, 'emoji': emoji});
  }

  static Future<Map<String, dynamic>> removeCustomStatus() async {
    return _request('POST', '/users/remove-custom-status');
  }

  static Future<Map<String, dynamic>> getOnlineStatus(int userId) async {
    final res = await _request('GET', '/users/$userId/online-status');
    return res;
  }

  static Future<Map<String, dynamic>> getTypingStatus(int userId, String chatId) async {
    final res = await _request('GET', '/users/$userId/typing-status?chat_id=$chatId');
    return res;
  }

  static Future<Map<String, dynamic>> getUserGifts(int userId) async {
    final res = await _request('GET', '/users/$userId/gifts');
    return res;
  }

  static Future<Map<String, dynamic>> getStickers() async {
    final res = await _request('GET', '/stickers');
    return res;
  }

  static Future<Map<String, dynamic>> getInstalledStickerPacks() async {
    final res = await _request('GET', '/stickers/installed');
    return res;
  }

  static Future<Map<String, dynamic>> installStickerPack(int packId) async {
    return _request('POST', '/stickers/install-pack', body: {'pack_id': packId});
  }

  static Future<Map<String, dynamic>> uninstallStickerPack(int packId) async {
    return _request('POST', '/stickers/uninstall-pack', body: {'pack_id': packId});
  }

  static Future<Map<String, dynamic>> getGifs({String? query, int offset = 0, int limit = 24}) async {
    String endpoint = '/gifs';
    if (query != null && query.isNotEmpty) {
      endpoint += '?q=$query&offset=$offset&limit=$limit';
    } else {
      endpoint += '?offset=$offset&limit=$limit';
    }
    final res = await _request('GET', endpoint);
    return res;
  }

  // --- CHATS ---

  static Future<Map<String, dynamic>> getChats() async {
    final res = await _request('GET', '/chats');
    return res;
  }

  static Future<Map<String, dynamic>> createPrivateChat(int userId) async {
    return _request('POST', '/chats/create-private', body: {'user_id': userId});
  }

  static Future<Map<String, dynamic>> createGroupChat(String title, String description, List<int> userIds) async {
    return _request('POST', '/chats/create-group', body: {
      'title': title,
      'description': description,
      'user_ids': userIds,
    });
  }

  static Future<Map<String, dynamic>> createChannelChat(String title, String description) async {
    return _request('POST', '/chats/create-channel', body: {
      'title': title,
      'description': description,
    });
  }

  static Future<Map<String, dynamic>> getChatById(String chatId) async {
    final res = await _request('GET', '/chats/$chatId');
    return res;
  }

  static Future<Map<String, dynamic>> updateChat(String chatId, Map<String, dynamic> data) async {
    return _request('POST', '/chats/$chatId/update', body: data);
  }

  static Future<Map<String, dynamic>> archiveChat(String chatId) async {
    return _request('POST', '/chats/$chatId/archive');
  }

  static Future<Map<String, dynamic>> unarchiveChat(String chatId) async {
    return _request('POST', '/chats/$chatId/unarchive');
  }

  static Future<Map<String, dynamic>> toggleFavorite(String chatId) async {
    return _request('POST', '/chats/$chatId/toggle-favorite');
  }

  static Future<Map<String, dynamic>> muteChat(String chatId, int? untilTimestamp) async {
    return _request('POST', '/chats/$chatId/mute', body: {'until': untilTimestamp});
  }

  static Future<Map<String, dynamic>> unmuteChat(String chatId) async {
    return _request('POST', '/chats/$chatId/unmute');
  }

  static Future<Map<String, dynamic>> leaveChat(String chatId) async {
    return _request('POST', '/chats/$chatId/leave');
  }

  static Future<Map<String, dynamic>> deleteChat(String chatId) async {
    return _request('POST', '/chats/$chatId/delete');
  }

  static Future<Map<String, dynamic>> getChatMembers(String chatId) async {
    final res = await _request('GET', '/chats/$chatId/members');
    return res;
  }

  static Future<Map<String, dynamic>> addMemberToChat(String chatId, int userId) async {
    return _request('POST', '/chats/$chatId/add-member', body: {'user_id': userId});
  }

  static Future<Map<String, dynamic>> removeMemberFromChat(String chatId, int userId) async {
    return _request('POST', '/chats/$chatId/remove-member', body: {'user_id': userId});
  }

  static Future<Map<String, dynamic>> promoteMember(String chatId, int userId) async {
    return _request('POST', '/chats/$chatId/promote-member', body: {'user_id': userId});
  }

  static Future<Map<String, dynamic>> demoteMember(String chatId, int userId) async {
    return _request('POST', '/chats/$chatId/demote-member', body: {'user_id': userId});
  }

  static Future<Map<String, dynamic>> pinMessage(String chatId, int messageId) async {
    return _request('POST', '/chats/$chatId/pin-message', body: {'message_id': messageId});
  }

  static Future<Map<String, dynamic>> unpinMessage(String chatId, int messageId) async {
    return _request('POST', '/chats/$chatId/unpin-message', body: {'message_id': messageId});
  }

  // --- МАССОВЫЕ ДЕЙСТВИЯ С ЧАТАМИ (новые методы) ---
  static Future<Map<String, dynamic>> deleteChats(List<String> chatIds) async {
    return _request('POST', '/chats/actions/delete', body: {'chat_ids': chatIds});
  }

  static Future<Map<String, dynamic>> setFavoriteStatusForChats({required List<String> chatIds, required bool isFavorite}) async {
    return _request('POST', '/chats/actions/favorite', body: {'chat_ids': chatIds, 'is_favorite': isFavorite});
  }

  static Future<Map<String, dynamic>> setMuteStatusForChats({required List<String> chatIds, required bool isMuted, int? mutedUntil}) async {
    return _request('POST', '/chats/actions/mute', body: {'chat_ids': chatIds, 'is_muted': isMuted, 'muted_until': mutedUntil});
  }

  static Future<Map<String, dynamic>> setArchiveStatusForChats({required List<String> chatIds, required bool isArchived}) async {
    return _request('POST', '/chats/actions/archive', body: {'chat_ids': chatIds, 'is_archived': isArchived});
  }
  // --- /МАССОВЫЕ ДЕЙСТВИЯ ---

  // --- MESSAGES ---

  static Future<Map<String, dynamic>> getMessages(String chatId, {int limit = 50, int? offset, bool older = false}) async {
    String queryString = '?limit=$limit';
    if (offset != null) queryString += '&offset=$offset';
    if (older) queryString += '&older=true';
    final res = await _request('GET', '/chats/$chatId/messages$queryString');
    return res;
  }

  static Future<Map<String, dynamic>> sendMessage(String chatId, String type, String content,
      {List<String>? attachments, int? replyToMessageId, int? forwardFromMessageId}) async {
    return _request('POST', '/messages/send', body: {
      'chat_id': chatId,
      'type': type,
      'content': content,
      if (attachments != null) 'attachments': attachments,
      if (replyToMessageId != null) 'reply_to_message_id': replyToMessageId,
      if (forwardFromMessageId != null) 'forward_from_message_id': forwardFromMessageId,
    });
  }

  static Future<Map<String, dynamic>> sendVoiceMessage(String chatId, String audioBase64, int duration) async {
    return _request('POST', '/messages/send-voice', body: {
      'chat_id': chatId,
      'audio': audioBase64,
      'duration': duration,
    });
  }

  static Future<Map<String, dynamic>> sendMediaMessage(String chatId, String type, String mediaBase64, String? thumbnailBase64, String? fileName, int? fileSize) async {
    return _request('POST', '/messages/send-media', body: {
      'chat_id': chatId,
      'type': type,
      'media': mediaBase64,
      if (thumbnailBase64 != null) 'thumbnail': thumbnailBase64,
      if (fileName != null) 'filename': fileName,
      if (fileSize != null) 'filesize': fileSize,
    });
  }

  static Future<Map<String, dynamic>> sendVideoMessage(String chatId, String videoBase64, String? thumbnailBase64, int duration, String? fileName, int? fileSize) async {
    return _request('POST', '/messages/send-video', body: {
      'chat_id': chatId,
      'video': videoBase64,
      if (thumbnailBase64 != null) 'thumbnail': thumbnailBase64,
      'duration': duration,
      if (fileName != null) 'filename': fileName,
      if (fileSize != null) 'filesize': fileSize,
    });
  }

  static Future<Map<String, dynamic>> sendFileMessage(String chatId, String fileBase64, String fileName, int fileSize) async {
    return _request('POST', '/messages/send-file', body: {
      'chat_id': chatId,
      'file': fileBase64,
      'filename': fileName,
      'filesize': fileSize,
    });
  }

  static Future<Map<String, dynamic>> sendLocationMessage(String chatId, double latitude, double longitude) async {
    return _request('POST', '/messages/send-location', body: {
      'chat_id': chatId,
      'latitude': latitude,
      'longitude': longitude,
    });
  }

  static Future<Map<String, dynamic>> sendContactMessage(String chatId, int contactUserId) async {
    return _request('POST', '/messages/send-contact', body: {
      'chat_id': chatId,
      'contact_user_id': contactUserId,
    });
  }

  static Future<Map<String, dynamic>> sendStickerMessage(String chatId, int stickerId, int packId) async {
    return _request('POST', '/messages/send-sticker', body: {
      'chat_id': chatId,
      'sticker_id': stickerId,
      'pack_id': packId,
    });
  }

  static Future<Map<String, dynamic>> sendGifMessage(String chatId, String gifUrl, String gifId) async {
    return _request('POST', '/messages/send-gif', body: {
      'chat_id': chatId,
      'gif_url': gifUrl,
      'gif_id': gifId,
    });
  }

  static Future<Map<String, dynamic>> sendGiftMessage(String chatId, int giftId) async {
    return _request('POST', '/messages/send-gift', body: {
      'chat_id': chatId,
      'gift_id': giftId,
    });
  }

  static Future<Map<String, dynamic>> editMessage(String chatId, int messageId, String newContent) async {
    return _request('POST', '/messages/$messageId/edit', body: {
      'chat_id': chatId,
      'content': newContent,
    });
  }

  static Future<Map<String, dynamic>> deleteMessage(String chatId, int messageId, bool forEveryone) async {
    return _request('POST', '/messages/$messageId/delete', body: {
      'chat_id': chatId,
      'for_everyone': forEveryone,
    });
  }

  static Future<Map<String, dynamic>> forwardMessages(String targetChatId, List<Map<String, dynamic>> messages) async {
    return _request('POST', '/messages/forward', body: {
      'target_chat_id': targetChatId,
      'messages': messages,
    });
  }

  static Future<Map<String, dynamic>> addReaction(String chatId, int messageId, String emoji) async {
    return _request('POST', '/messages/$messageId/reactions/add', body: {
      'chat_id': chatId,
      'emoji': emoji,
    });
  }

  static Future<Map<String, dynamic>> removeReaction(String chatId, int messageId, String emoji) async {
    return _request('POST', '/messages/$messageId/reactions/remove', body: {
      'chat_id': chatId,
      'emoji': emoji,
    });
  }

  static Future<Map<String, dynamic>> markAsRead(String chatId, int upToMessageId) async {
    return _request('POST', '/chats/$chatId/mark-as-read', body: {'up_to_message_id': upToMessageId});
  }

  // --- ОПРОСЫ (новые методы) ---
  static Future<Map<String, dynamic>> sendPoll({
    required String chatId,
    required String question,
    required List<String> options,
    bool isQuiz = false,
    int? correctOptionId, // Обязательно, если isQuiz = true
  }) async {
    if (isQuiz && (correctOptionId == null || correctOptionId < 0 || correctOptionId >= options.length)) {
      throw Exception("correctOptionId обязателен и должен быть допустимым индексом для викторины.");
    }
    return _request('POST', '/messages/send-poll', body: {
      'chat_id': chatId,
      'question': question,
      'options': options,
      'is_quiz': isQuiz,
      if (isQuiz) 'correct_option_id': correctOptionId,
    });
  }

  static Future<Map<String, dynamic>> voteInPoll({
    required int messageId, // ID сообщения с опросом
    required int optionId, // ID выбранной опции (из poll_options)
  }) async {
    return _request('POST', '/messages/vote', body: {
      'message_id': messageId,
      'option_id': optionId,
    });
  }

  static Future<Map<String, dynamic>> getPollResults({required int messageId}) async {
    return _request('GET', '/messages/get-poll-results?message_id=$messageId');
  }
  // --- /ОПРОСЫ ---

  // --- FRIENDS ---

  static Future<Map<String, dynamic>> getFriends() async {
    final res = await _request('GET', '/friends');
    return res;
  }

  static Future<Map<String, dynamic>> getFriendRequests() async {
    final res = await _request('GET', '/friends/requests');
    return res;
  }

  static Future<Map<String, dynamic>> sendFriendRequest(int userId) async {
    return _request('POST', '/friends/request', body: {'user_id': userId});
  }

  static Future<Map<String, dynamic>> acceptFriendRequest(int userId) async {
    return _request('POST', '/friends/accept', body: {'user_id': userId});
  }

  static Future<Map<String, dynamic>> declineFriendRequest(int userId) async {
    return _request('POST', '/friends/decline', body: {'user_id': userId});
  }

  static Future<Map<String, dynamic>> removeFriend(int userId) async {
    return _request('POST', '/friends/remove', body: {'user_id': userId});
  }

  // --- GIFS (множество методов, часть дублируется из фрагментов) ---
  // ... (остальные методы getAnimated... остаются как есть, но теперь в одном файле) ...
  static Future<Map<String, dynamic>> getTrendingGifs({int offset = 0, int limit = 24}) async {
    final res = await _request('GET', '/gifs/trending?offset=$offset&limit=$limit');
    return res;
  }

  static Future<Map<String, dynamic>> searchGifs(String query, {int offset = 0, int limit = 24}) async {
    final res = await _request('GET', '/gifs/search?q=$query&offset=$offset&limit=$limit');
    return res;
  }

  static Future<Map<String, dynamic>> getGifCategories() async {
    final res = await _request('GET', '/gifs/categories');
    return res;
  }

  static Future<Map<String, dynamic>> getGifsByCategory(String categoryId, {int offset = 0, int limit = 24}) async {
    final res = await _request('GET', '/gifs/category/$categoryId?offset=$offset&limit=$limit');
    return res;
  }

  static Future<Map<String, dynamic>> getTrendingSearchTerms() async {
    final res = await _request('GET', '/gifs/trending-searches');
    return res;
  }

  static Future<Map<String, dynamic>> translateGifTerm(String term) async {
    final res = await _request('GET', '/gifs/translate-term?term=$term');
    return res;
  }

  static Future<Map<String, dynamic>> getRandomGif({String? tag}) async {
    String endpoint = '/gifs/random';
    if (tag != null && tag.isNotEmpty) {
      endpoint += '?tag=$tag';
    }
    final res = await _request('GET', endpoint);
    return res;
  }

  static Future<Map<String, dynamic>> uploadGif(String gifBase64, String title, String tags) async {
    return _request('POST', '/gifs/upload', body: {
      'gif': gifBase64,
      'title': title,
      'tags': tags,
    });
  }

  static Future<Map<String, dynamic>> deleteGif(String gifId) async {
    return _request('POST', '/gifs/$gifId/delete');
  }

  static Future<Map<String, dynamic>> toggleGifFavorite(String gifId) async {
    return _request('POST', '/gifs/$gifId/toggle-favorite');
  }

  static Future<Map<String, dynamic>> reportGif(String gifId, String reason) async {
    return _request('POST', '/gifs/$gifId/report', body: {'reason': reason});
  }

  static Future<Map<String, dynamic>> shareGif(String gifId) async {
    return _request('POST', '/gifs/$gifId/share');
  }

  static Future<Map<String, dynamic>> getGifById(String gifId) async {
    final res = await _request('GET', '/gifs/$gifId');
    return res;
  }

  static Future<Map<String, dynamic>> getUserGifs(int userId) async {
    final res = await _request('GET', '/gifs/user/$userId');
    return res;
  }

  static Future<Map<String, dynamic>> getFavoriteGifs() async {
    final res = await _request('GET', '/gifs/favorites');
    return res;
  }

  static Future<Map<String, dynamic>> getRecentGifs({int limit = 24}) async {
    final res = await _request('GET', '/gifs/recent?limit=$limit');
    return res;
  }

  static Future<Map<String, dynamic>> getTrendingGifsByTag(String tag, {int offset = 0, int limit = 24}) async {
    final res = await _request('GET', '/gifs/trending-by-tag?tag=$tag&offset=$offset&limit=$limit');
    return res;
  }

  static Future<Map<String, dynamic>> getStickerPacksForGif(String gifId) async {
    final res = await _request('GET', '/gifs/$gifId/sticker-packs');
    return res;
  }

  static Future<Map<String, dynamic>> getEmojiForGif(String gifId) async {
    final res = await _request('GET', '/gifs/$gifId/emoji');
    return res;
  }

  static Future<Map<String, dynamic>> getColorPaletteForGif(String gifId) async {
    final res = await _request('GET', '/gifs/$gifId/color-palette');
    return res;
  }

  static Future<Map<String, dynamic>> getPreviewImageForGif(String gifId) async {
    final res = await _request('GET', '/gifs/$gifId/preview-image');
    return res;
  }

  static Future<Map<String, dynamic>> getHdVideoForGif(String gifId) async {
    final res = await _request('GET', '/gifs/$gifId/hd-video');
    return res;
  }

  static Future<Map<String, dynamic>> getMp4ForGif(String gifId) async {
    final res = await _request('GET', '/gifs/$gifId/mp4');
    return res;
  }

  static Future<Map<String, dynamic>> getWebmForGif(String gifId) async {
    final res = await _request('GET', '/gifs/$gifId/webm');
    return res;
  }

  static Future<Map<String, dynamic>> getSizeForGif(String gifId) async {
    final res = await _request('GET', '/gifs/$gifId/size');
    return res;
  }

  static Future<Map<String, dynamic>> getDurationForGif(String gifId) async {
    final res = await _request('GET', '/gifs/$gifId/duration');
    return res;
  }

  static Future<Map<String, dynamic>> getFramesForGif(String gifId) async {
    final res = await _request('GET', '/gifs/$gifId/frames');
    return res;
  }

  static Future<Map<String, dynamic>> getLoopCountForGif(String gifId) async {
    final res = await _request('GET', '/gifs/$gifId/loop-count');
    return res;
  }

  static Future<Map<String, dynamic>> getOptimizedVersionForGif(String gifId) async {
    final res = await _request('GET', '/gifs/$gifId/optimized-version');
    return res;
  }

  static Future<Map<String, dynamic>> getCompressedVersionForGif(String gifId) async {
    final res = await _request('GET', '/gifs/$gifId/compressed-version');
    return res;
  }

  static Future<Map<String, dynamic>> getThumbnailForGif(String gifId) async {
    final res = await _request('GET', '/gifs/$gifId/thumbnail');
    return res;
  }

  static Future<Map<String, dynamic>> getSmallThumbnailForGif(String gifId) async {
    final res = await _request('GET', '/gifs/$gifId/small-thumbnail');
    return res;
  }

  static Future<Map<String, dynamic>> getOriginalForGif(String gifId) async {
    final res = await _request('GET', '/gifs/$gifId/original');
    return res;
  }

  static Future<Map<String, dynamic>> getAnimatedWebpForGif(String gifId) async {
    final res = await _request('GET', '/gifs/$gifId/animated-webp');
    return res;
  }

  static Future<Map<String, dynamic>> getAnimatedAvifForGif(String gifId) async {
    final res = await _request('GET', '/gifs/$gifId/animated-avif');
    return res;
  }

  static Future<Map<String, dynamic>> getAnimatedPngForGif(String gifId) async {
    final res = await _request('GET', '/gifs/$gifId/animated-png');
    return res;
  }

  static Future<Map<String, dynamic>> getAnimatedJpgForGif(String gifId) async {
    final res = await _request('GET', '/gifs/$gifId/animated-jpg');
    return res;
  }

  static Future<Map<String, dynamic>> getAnimatedBmpForGif(String gifId) async {
    final res = await _request('GET', '/gifs/$gifId/animated-bmp');
    return res;
  }

  static Future<Map<String, dynamic>> getAnimatedTiffForGif(String gifId) async {
    final res = await _request('GET', '/gifs/$gifId/animated-tiff');
    return res;
  }

  static Future<Map<String, dynamic>> getAnimatedPsdForGif(String gifId) async {
    final res = await _request('GET', '/gifs/$gifId/animated-psd');
    return res;
  }

  static Future<Map<String, dynamic>> getAnimatedAiForGif(String gifId) async {
    final res = await _request('GET', '/gifs/$gifId/animated-ai');
    return res;
  }

  static Future<Map<String, dynamic>> getAnimatedEpsForGif(String gifId) async {
    final res = await _request('GET', '/gifs/$gifId/animated-eps');
    return res;
  }

  static Future<Map<String, dynamic>> getAnimatedPdfForGif(String gifId) async {
    final res = await _request('GET', '/gifs/$gifId/animated-pdf');
    return res;
  }

  static Future<Map<String, dynamic>> getAnimatedSvgForGif(String gifId) async {
    final res = await _request('GET', '/gifs/$gifId/animated-svg');
    return res;
  }

  static Future<Map<String, dynamic>> getAnimatedHtmlForGif(String gifId) async {
    final res = await _request('GET', '/gifs/$gifId/animated-html');
    return res;
  }

  static Future<Map<String, dynamic>> getAnimatedCssForGif(String gifId) async {
    final res = await _request('GET', '/gifs/$gifId/animated-css');
    return res;
  }

  static Future<Map<String, dynamic>> getAnimatedJsForGif(String gifId) async {
    final res = await _request('GET', '/gifs/$gifId/animated-js');
    return res;
  }

  static Future<Map<String, dynamic>> getAnimatedTsForGif(String gifId) async {
    final res = await _request('GET', '/gifs/$gifId/animated-ts');
    return res;
  }

  static Future<Map<String, dynamic>> getAnimatedDartForGif(String gifId) async {
    final res = await _request('GET', '/gifs/$gifId/animated-dart');
    return res;
  }

  static Future<Map<String, dynamic>> getAnimatedFlutterForGif(String gifId) async {
    final res = await _request('GET', '/gifs/$gifId/animated-flutter');
    return res;
  }

  static Future<Map<String, dynamic>> getAnimatedReactForGif(String gifId) async {
    final res = await _request('GET', '/gifs/$gifId/animated-react');
    return res;
  }

  static Future<Map<String, dynamic>> getAnimatedVueForGif(String gifId) async {
    final res = await _request('GET', '/gifs/$gifId/animated-vue');
    return res;
  }

  static Future<Map<String, dynamic>> getAnimatedAngularForGif(String gifId) async {
    final res = await _request('GET', '/gifs/$gifId/animated-angular');
    return res;
  }

  static Future<Map<String, dynamic>> getAnimatedSvelteForGif(String gifId) async {
    final res = await _request('GET', '/gifs/$gifId/animated-svelte');
    return res;
  }

  static Future<Map<String, dynamic>> getAnimatedNextForGif(String gifId) async {
    final res = await _request('GET', '/gifs/$gifId/animated-next');
    return res;
  }

  static Future<Map<String, dynamic>> getAnimatedNuxtForGif(String gifId) async {
    final res = await _request('GET', '/gifs/$gifId/animated-nuxt');
    return res;
  }

  static Future<Map<String, dynamic>> getAnimatedGatsbyForGif(String gifId) async {
    final res = await _request('GET', '/gifs/$gifId/animated-gatsby');
    return res;
  }

  static Future<Map<String, dynamic>> getAnimatedGridsomeForGif(String gifId) async {
    final res = await _request('GET', '/gifs/$gifId/animated-gridsome');
    return res;
  }

  static Future<Map<String, dynamic>> getAnimatedHugoForGif(String gifId) async {
    final res = await _request('GET', '/gifs/$gifId/animated-hugo');
    return res;
  }

  static Future<Map<String, dynamic>> getAnimatedJekyllForGif(String gifId) async {
    final res = await _request('GET', '/gifs/$gifId/animated-jekyll');
    return res;
  }

  static Future<Map<String, dynamic>> getAnimatedWordpressForGif(String gifId) async {
    final res = await _request('GET', '/gifs/$gifId/animated-wordpress');
    return res;
  }

  static Future<Map<String, dynamic>> getAnimatedDrupalForGif(String gifId) async {
    final res = await _request('GET', '/gifs/$gifId/animated-drupal');
    return res;
  }

  static Future<Map<String, dynamic>> getAnimatedJoomlaForGif(String gifId) async {
    final res = await _request('GET', '/gifs/$gifId/animated-joomla');
    return res;
  }

  static Future<Map<String, dynamic>> getAnimatedMagentoForGif(String gifId) async {
    final res = await _request('GET', '/gifs/$gifId/animated-magento');
    return res;
  }

  static Future<Map<String, dynamic>> getAnimatedShopifyForGif(String gifId) async {
    final res = await _request('GET', '/gifs/$gifId/animated-shopify');
    return res;
  }

  static Future<Map<String, dynamic>> getAnimatedWoocommerceForGif(String gifId) async {
    final res = await _request('GET', '/gifs/$gifId/animated-woocommerce');
    return res;
  }

  static Future<Map<String, dynamic>> getAnimatedPrestashopForGif(String gifId) async {
    final res = await _request('GET', '/gifs/$gifId/animated-prestashop');
    return res;
  }

  static Future<Map<String, dynamic>> getAnimatedBigcommerceForGif(String gifId) async {
    final res = await _request('GET', '/gifs/$gifId/animated-bigcommerce');
    return res;
  }

  static Future<Map<String, dynamic>> getAnimatedEcwidForGif(String gifId) async {
    final res = await _request('GET', '/gifs/$gifId/animated-ecwid');
    return res;
  }

  static Future<Map<String, dynamic>> getAnimatedSquarespaceForGif(String gifId) async {
    final res = await _request('GET', '/gifs/$gifId/animated-squarespace');
    return res;
  }

  static Future<Map<String, dynamic>> getAnimatedWebflowForGif(String gifId) async {
    final res = await _request('GET', '/gifs/$gifId/animated-webflow');
    return res;
  }

  static Future<Map<String, dynamic>> getAnimatedFigmaForGif(String gifId) async {
    final res = await _request('GET', '/gifs/$gifId/animated-figma');
    return res;
  }

  static Future<Map<String, dynamic>> getAnimatedSketchForGif(String gifId) async {
    final res = await _request('GET', '/gifs/$gifId/animated-sketch');
    return res;
  }

  static Future<Map<String, dynamic>> getAnimatedAdobeXdForGif(String gifId) async {
    final res = await _request('GET', '/gifs/$gifId/animated-adobe-xd');
    return res;
  }

  static Future<Map<String, dynamic>> getAnimatedPhotoshopForGif(String gifId) async {
    final res = await _request('GET', '/gifs/$gifId/animated-photoshop');
    return res;
  }

  static Future<Map<String, dynamic>> getAnimatedIllustratorForGif(String gifId) async {
    final res = await _request('GET', '/gifs/$gifId/animated-illustrator');
    return res;
  }

  static Future<Map<String, dynamic>> getAnimatedAfterEffectsForGif(String gifId) async {
    final res = await _request('GET', '/gifs/$gifId/animated-after-effects');
    return res;
  }

  static Future<Map<String, dynamic>> getAnimatedPremiereProForGif(String gifId) async {
    final res = await _request('GET', '/gifs/$gifId/animated-premiere-pro');
    return res;
  }

  static Future<Map<String, dynamic>> getAnimatedDavinciResolveForGif(String gifId) async {
    final res = await _request('GET', '/gifs/$gifId/animated-davinci-resolve');
    return res;
  }

  static Future<Map<String, dynamic>> getAnimatedFinalCutProForGif(String gifId) async {
    final res = await _request('GET', '/gifs/$gifId/animated-final-cut-pro');
    return res;
  }

  static Future<Map<String, dynamic>> getAnimatedImovieForGif(String gifId) async {
    final res = await _request('GET', '/gifs/$gifId/animated-imovie');
    return res;
  }

  static Future<Map<String, dynamic>> getAnimatedMotionForGif(String gifId) async {
    final res = await _request('GET', '/gifs/$gifId/animated-motion');
    return res;
  }

  static Future<Map<String, dynamic>> getAnimatedBlandForGif(String gifId) async {
    final res = await _request('GET', '/gifs/$gifId/animated-bland');
    return res;
  }

  static Future<Map<String, dynamic>> getAnimatedRunwayMlForGif(String gifId) async {
    final res = await _request('GET', '/gifs/$gifId/animated-runway-ml');
    return res;
  }

  static Future<Map<String, dynamic>> getAnimatedSynthesiaForGif(String gifId) async {
    final res = await _request('GET', '/gifs/$gifId/animated-synthesia');
    return res;
  }

  static Future<Map<String, dynamic>> getAnimatedPeecForGif(String gifId) async {
    final res = await _request('GET', '/gifs/$gifId/animated-peec');
    return res;
  }

  static Future<Map<String, dynamic>> getAnimatedLalaLandForGif(String gifId) async {
    final res = await _request('GET', '/gifs/$gifId/animated-lala-land');
    return res;
  }

  static Future<Map<String, dynamic>> getAnimatedBohemianRhapsodyForGif(String gifId) async {
    final res = await _request('GET', '/gifs/$gifId/animated-bohemian-rhapsody');
    return res;
  }

  static Future<Map<String, dynamic>> getAnimatedWeWillRockYouForGif(String gifId) async {
    final res = await _request('GET', '/gifs/$gifId/animated-we-will-rock-you');
    return res;
  }

  static Future<Map<String, dynamic>> getAnimatedSomewhereOverTheRainbowForGif(String gifId) async {
    final res = await _request('GET', '/gifs/$gifId/animated-somewhere-over-the-rainbow');
    return res;
  }

  static Future<Map<String, dynamic>> getAnimatedWhatAWonderfulWorldForGif(String gifId) async {
    final res = await _request('GET', '/gifs/$gifId/animated-what-a-wonderful-world');
    return res;
  }

  static Future<Map<String, dynamic>> getAnimatedMyWayForGif(String gifId) async {
    final res = await _request('GET', '/gifs/$gifId/animated-my-way');
    return res;
  }

  static Future<Map<String, dynamic>> getAnimatedNewYorkNewYorkForGif(String gifId) async {
    final res = await _request('GET', '/gifs/$gifId/animated-new-york-new-york');
    return res;
  }

  static Future<Map<String, dynamic>> getAnimatedStrangeloveForGif(String gifId) async {
    final res = await _request('GET', '/gifs/$gifId/animated-strangelove');
    return res;
  }

  static Future<Map<String, dynamic>> getAnimatedDoctorZhivagoForGif(String gifId) async {
    final res = await _request('GET', '/gifs/$gifId/animated-doctor-zhivago');
    return res;
  }

  static Future<Map<String, dynamic>> getAnimatedTheUmbrellasOfCherbourgForGif(String gifId) async {
    final res = await _request('GET', '/gifs/$gifId/animated-the-umbrellas-of-cherbourg');
    return res;
  }

  static Future<Map<String, dynamic>> getAnimatedTheRedBalloonForGif(String gifId) async {
    final res = await _request('GET', '/gifs/$gifId/animated-the-red-balloon');
    return res;
  }

  static Future<Map<String, dynamic>> getAnimatedTheWildParrotForGif(String gifId) async {
    final res = await _request('GET', '/gifs/$gifId/animated-the-wild-parrot');
    return res;
  }

  static Future<Map<String, dynamic>> getAnimatedTheLittleMermaidForGif(String gifId) async {
    final res = await _request('GET', '/gifs/$gifId/animated-the-little-mermaid');
    return res;
  }

  static Future<Map<String, dynamic>> getAnimatedTheLionKingForGif(String gifId) async {
    final res = await _request('GET', '/gifs/$gifId/animated-the-lion-king');
    return res;
  }

  static Future<Map<String, dynamic>> getAnimatedAladdinForGif(String gifId) async {
    final res = await _request('GET', '/gifs/$gifId/animated-aladdin');
    return res;
  }

  static Future<Map<String, dynamic>> getAnimatedBeautyAndTheBeastForGif(String gifId) async {
    final res = await _request('GET', '/gifs/$gifId/animated-beauty-and-the-beast');
    return res;
  }

  static Future<Map<String, dynamic>> getAnimatedTheEmperorsNewGrooveForGif(String gifId) async {
    final res = await _request('GET', '/gifs/$gifId/animated-the-emperors-new-groove');
    return res;
  }

  static Future<Map<String, dynamic>> getAnimatedHerculesForGif(String gifId) async {
    final res = await _request('GET', '/gifs/$gifId/animated-hercules');
    return res;
  }

  static Future<Map<String, dynamic>> getAnimatedMulanForGif(String gifId) async {
    final res = await _request('GET', '/gifs/$gifId/animated-mulan');
    return res;
  }

  static Future<Map<String, dynamic>> getAnimatedTarzanForGif(String gifId) async {
    final res = await _request('GET', '/gifs/$gifId/animated-tarzan');
    return res;
  }

  static Future<Map<String, dynamic>> getAnimatedLadyAndTheTrampForGif(String gifId) async {
    final res = await _request('GET', '/gifs/$gifId/animated-lady-and-the-tramp');
    return res;
  }

  static Future<Map<String, dynamic>> getAnimatedOliverAndCompanyForGif(String gifId) async {
    final res = await _request('GET', '/gifs/$gifId/animated-oliver-and-company');
    return res;
  }

  static Future<Map<String, dynamic>> getAnimatedTheAristocatsForGif(String gifId) async {
    final res = await _request('GET', '/gifs/$gifId/animated-the-aristocats');
    return res;
  }

  static Future<Map<String, dynamic>> getAnimatedTheJungleBookForGif(String gifId) async {
    final res = await _request('GET', '/gifs/$gifId/animated-the-jungle-book');
    return res;
  }

  static Future<Map<String, dynamic>> getAnimatedRobinHoodForGif(String gifId) async {
    final res = await _request('GET', '/gifs/$gifId/animated-robin-hood');
    return res;
  }

  static Future<Map<String, dynamic>> getAnimatedTheSwordInTheStoneForGif(String gifId) async {
    final res = await _request('GET', '/gifs/$gifId/animated-the-sword-in-the-stone');
    return res;
  }

  static Future<Map<String, dynamic>> getAnimatedSleepingBeautyForGif(String gifId) async {
    final res = await _request('GET', '/gifs/$gifId/animated-sleeping-beauty');
    return res;
  }

  static Future<Map<String, dynamic>> getAnimatedCinderellaForGif(String gifId) async {
    final res = await _request('GET', '/gifs/$gifId/animated-cinderella');
    return res;
  }

  static Future<Map<String, dynamic>> getAnimatedSnowWhiteAndTheSevenDwarfsForGif(String gifId) async {
    final res = await _request('GET', '/gifs/$gifId/animated-snow-white-and-the-seven-dwarfs');
    return res;
  }

  static Future<Map<String, dynamic>> getAnimatedPinocchioForGif(String gifId) async {
    final res = await _request('GET', '/gifs/$gifId/animated-pinocchio');
    return res;
  }

  static Future<Map<String, dynamic>> getAnimatedDumboForGif(String gifId) async {
    final res = await _request('GET', '/gifs/$gifId/animated-dumbo');
    return res;
  }

  static Future<Map<String, dynamic>> getAnimatedBambiForGif(String gifId) async {
    final res = await _request('GET', '/gifs/$gifId/animated-bambi');
    return res;
  }

  static Future<Map<String, dynamic>> getAnimatedFantasiaForGif(String gifId) async {
    final res = await _request('GET', '/gifs/$gifId/animated-fantasia');
    return res;
  }

  static Future<Map<String, dynamic>> getAnimatedSilenceOfTheLambsForGif(String gifId) async {
    final res = await _request('GET', '/gifs/$gifId/animated-silence-of-the-lambs');
    return res;
  }

  static Future<Map<String, dynamic>> getAnimatedPulpFictionForGif(String gifId) async {
    final res = await _request('GET', '/gifs/$gifId/animated-pulp-fiction');
    return res;
  }

  static Future<Map<String, dynamic>> getAnimatedGodfatherForGif(String gifId) async {
    final res = await _request('GET', '/gifs/$gifId/animated-godfather');
    return res;
  }

  static Future<Map<String, dynamic>> getAnimatedDarkKnightForGif(String gifId) async {
    final res = await _request('GET', '/gifs/$gifId/animated-dark-knight');
    return res;
  }

  static Future<Map<String, dynamic>> getAnimatedSchindlersListForGif(String gifId) async {
    final res = await _request('GET', '/gifs/$gifId/animated-schindlers-list');
    return res;
  }

  static Future<Map<String, dynamic>> getAnimatedForrestGumpForGif(String gifId) async {
    final res = await _request('GET', '/gifs/$gifId/animated-forrest-gump');
    return res;
  }

  static Future<Map<String, dynamic>> getAnimatedFightClubForGif(String gifId) async {
    final res = await _request('GET', '/gifs/$gifId/animated-fight-club');
    return res;
  }

  static Future<Map<String, dynamic>> getAnimatedInceptionForGif(String gifId) async {
    final res = await _request('GET', '/gifs/$gifId/animated-inception');
    return res;
  }

  static Future<Map<String, dynamic>> getAnimatedMatrixForGif(String gifId) async {
    final res = await _request('GET', '/gifs/$gifId/animated-matrix');
    return res;
  }

  static Future<Map<String, dynamic>> getAnimatedInterstellarForGif(String gifId) async {
    final res = await _request('GET', '/gifs/$gifId/animated-interstellar');
    return res;
  }

  static Future<Map<String, dynamic>> getAnimatedTitanicForGif(String gifId) async {
    final res = await _request('GET', '/gifs/$gifId/animated-titanic');
    return res;
  }

  static Future<Map<String, dynamic>> getAnimatedToweringInfernoForGif(String gifId) async {
    final res = await _request('GET', '/gifs/$gifId/animated-towering-inferno');
    return res;
  }

  static Future<Map<String, dynamic>> getAnimatedPoseidonAdventureForGif(String gifId) async {
    final res = await _request('GET', '/gifs/$gifId/animated-poseidon-adventure');
    return res;
  }

  static Future<Map<String, dynamic>> getAnimatedTakingOfPelhamOneTwoThreeForGif(String gifId) async {
    final res = await _request('GET', '/gifs/$gifId/animated-taking-of-pelham-one-two-three');
    return res;
  }

  static Future<Map<String, dynamic>> getAnimatedFrenchConnectionForGif(String gifId) async {
    final res = await _request('GET', '/gifs/$gifId/animated-french-connection');
    return res;
  }

  static Future<Map<String, dynamic>> getAnimatedDirtyHarryForGif(String gifId) async {
    final res = await _request('GET', '/gifs/$gifId/animated-dirty-harry');
    return res;
  }

  static Future<Map<String, dynamic>> getAnimatedCoogansBluffForGif(String gifId) async {
    final res = await _request('GET', '/gifs/$gifId/animated-coogans-bluff');
    return res;
  }

  static Future<Map<String, dynamic>> getAnimatedMagnumForceForGif(String gifId) async {
    final res = await _request('GET', '/gifs/$gifId/animated-magnum-force');
    return res;
  }

  static Future<Map<String, dynamic>> getAnimatedTheEnforcerForGif(String gifId) async {
    final res = await _request('GET', '/gifs/$gifId/animated-the-enforcer');
    return res;
  }

  static Future<Map<String, dynamic>> getAnimatedSorcererForGif(String gifId) async {
    final res = await _request('GET', '/gifs/$gifId/animated-sorcerer');
    return res;
  }

  static Future<Map<String, dynamic>> getAnimatedEscapeFromNewYorkForGif(String gifId) async {
    final res = await _request('GET', '/gifs/$gifId/animated-escape-from-new-york');
    return res;
  }

  static Future<Map<String, dynamic>> getAnimatedCliffhangerForGif(String gifId) async {
    final res = await _request('GET', '/gifs/$gifId/animated-cliffhanger');
    return res;
  }

  static Future<Map<String, dynamic>> getAnimatedTheLongestYardForGif(String gifId) async {
    final res = await _request('GET', '/gifs/$gifId/animated-the-longest-yard');
    return res;
  }

  static Future<Map<String, dynamic>> getAnimatedFiddlerOnTheRoofForGif(String gifId) async {
    final res = await _request('GET', '/gifs/$gifId/animated-fiddler-on-the-roof');
    return res;
  }

  static Future<Map<String, dynamic>> getAnimatedTheMusicManForGif(String gifId) async {
    final res = await _request('GET', '/gifs/$gifId/animated-the-music-man');
    return res;
  }

  static Future<Map<String, dynamic>> getAnimatedTheSoundOfMusicForGif(String gifId) async {
    final res = await _request('GET', '/gifs/$gifId/animated-the-sound-of-music');
    return res;
  }

  static Future<Map<String, dynamic>> getAnimatedWestSideStoryForGif(String gifId) async {
    final res = await _request('GET', '/gifs/$gifId/animated-west-side-story');
    return res;
  }

  static Future<Map<String, dynamic>> getAnimatedGypsyForGif(String gifId) async {
    final res = await _request('GET', '/gifs/$gifId/animated-gypsy');
    return res;
  }

  static Future<Map<String, dynamic>> getAnimatedAnneOfTheThousandDaysForGif(String gifId) async {
    final res = await _request('GET', '/gifs/$gifId/animated-anne-of-the-thousand-days');
    return res;
  }

  static Future<Map<String, dynamic>> getAnimatedTheAgonyAndTheEcstasyForGif(String gifId) async {
    final res = await _request('GET', '/gifs/$gifId/animated-the-agony-and-the-ecstasy');
    return res;
  }

  static Future<Map<String, dynamic>> getAnimatedTheCrimsonPirateForGif(String gifId) async {
    final res = await _request('GET', '/gifs/$gifId/animated-the-crimson-pirate');
    return res;
  }

  static Future<Map<String, dynamic>> getAnimatedSonOfFlandersForGif(String gifId) async {
    final res = await _request('GET', '/gifs/$gifId/animated-son-of-flanders');
    return res;
  }

  static Future<Map<String, dynamic>> getAnimatedTheBlackPirateForGif(String gifId) async {
    final res = await _request('GET', '/gifs/$gifId/animated-the-black-pirate');
    return res;
  }

  static Future<Map<String, dynamic>> getAnimatedScaramoucheForGif(String gifId) async {
    final res = await _request('GET', '/gifs/$gifId/animated-scaramouche');
    return res;
  }

  static Future<Map<String, dynamic>> getAnimatedTheAdventuresOfRobinHoodForGif(String gifId) async {
    final res = await _request('GET', '/gifs/$gifId/animated-the-adventures-of-robin-hood');
    return res;
  }

  static Future<Map<String, dynamic>> getAnimatedTheSeaHawkForGif(String gifId) async {
    final res = await _request('GET', '/gifs/$gifId/animated-the-sea-hawk');
    return res;
  }

  static Future<Map<String, dynamic>> getAnimatedNikitaForGif(String gifId) async {
    final res = await _request('GET', '/gifs/$gifId/animated-nikita');
    return res;
  }

  static Future<Map<String, dynamic>> getAnimatedLaFemmeNikitaForGif(String gifId) async {
    final res = await _request('GET', '/gifs/$gifId/animated-la-femme-nikita');
    return res;
  }

  static Future<Map<String, dynamic>> getAnimatedTheNetForGif(String gifId) async {
    final res = await _request('GET', '/gifs/$gifId/animated-the-net');
    return res;
  }

  static Future<Map<String, dynamic>> getAnimatedMatrixReloadedForGif(String gifId) async {
    final res = await _request('GET', '/gifs/$gifId/animated-matrix-reloaded');
    return res;
  }

  static Future<Map<String, dynamic>> getAnimatedMatrixRevolutionsForGif(String gifId) async {
    final res = await _request('GET', '/gifs/$gifId/animated-matrix-revolutions');
    return res;
  }

  static Future<Map<String, dynamic>> getAnimatedPrometheusForGif(String gifId) async {
    final res = await _request('GET', '/gifs/$gifId/animated-prometheus');
    return res;
  }

  static Future<Map<String, dynamic>> getAnimatedAlienForGif(String gifId) async {
    final res = await _request('GET', '/gifs/$gifId/animated-alien');
    return res;
  }

  static Future<Map<String, dynamic>> getAnimatedAliensForGif(String gifId) async {
    final res = await _request('GET', '/gifs/$gifId/animated-aliens');
    return res;
  }

  static Future<Map<String, dynamic>> getAnimatedAlien3ForGif(String gifId) async {
    final res = await _request('GET', '/gifs/$gifId/animated-alien3');
    return res;
  }

  static Future<Map<String, dynamic>> getAnimatedAlienResurrectionForGif(String gifId) async {
    final res = await _request('GET', '/gifs/$gifId/animated-alien-resurrection');
    return res;
  }

  static Future<Map<String, dynamic>> getAnimatedPrometheusTheAwakeningForGif(String gifId) async {
    final res = await _request('GET', '/gifs/$gifId/animated-prometheus-the-awakening');
    return res;
  }

  static Future<Map<String, dynamic>> getAnimatedAlienCovenantForGif(String gifId) async {
    final res = await _request('GET', '/gifs/$gifId/animated-alien-covenant');
    return res;
  }

  static Future<Map<String, dynamic>> getAnimatedTheForbiddenPlanetForGif(String gifId) async {
    final res = await _request('GET', '/gifs/$gifId/animated-the-forbidden-planet');
    return res;
  }

  static Future<Map<String, dynamic>> getAnimatedTheDayTheEarthStoodStillForGif(String gifId) async {
    final res = await _request('GET', '/gifs/$gifId/animated-the-day-the-earth-stood-still');
    return res;
  }

  static Future<Map<String, dynamic>> getAnimatedTheThingFromAnotherWorldForGif(String gifId) async {
    final res = await _request('GET', '/gifs/$gifId/animated-the-thing-from-another-world');
    return res;
  }

  static Future<Map<String, dynamic>> getAnimatedItCameFromOuterSpaceForGif(String gifId) async {
    final res = await _request('GET', '/gifs/$gifId/animated-it-came-from-outer-space');
    return res;
  }

  static Future<Map<String, dynamic>> getAnimatedTheIncredibleShrinkingManForGif(String gifId) async {
    final res = await _request('GET', '/gifs/$gifId/animated-the-incredible-shrinking-man');
    return res;
  }

  static Future<Map<String, dynamic>> getAnimatedTheWarOfTheWorldsForGif(String gifId) async {
    final res = await _request('GET', '/gifs/$gifId/animated-the-war-of-the-worlds');
    return res;
  }

  static Future<Map<String, dynamic>> getAnimatedTheTimeMachineForGif(String gifId) async {
    final res = await _request('GET', '/gifs/$gifId/animated-the-time-machine');
    return res;
  }

  static Future<Map<String, dynamic>> getAnimatedTheIslandOfDrMoreauForGif(String gifId) async {
    final res = await _request('GET', '/gifs/$gifId/animated-the-island-of-dr-moreau');
    return res;
  }

  static Future<Map<String, dynamic>> getAnimatedTheFlyForGif(String gifId) async {
    final res = await _request('GET', '/gifs/$gifId/animated-the-fly');
    return res;
  }

  static Future<Map<String, dynamic>> getAnimatedTheWaspWomanForGif(String gifId) async {
    final res = await _request('GET', '/gifs/$gifId/animated-the-wasp-woman');
    return res;
  }

  static Future<Map<String, dynamic>> getAnimatedTheCurseOfThePinkPantherForGif(String gifId) async {
    final res = await _request('GET', '/gifs/$gifId/animated-the-curse-of-the-pink-panther');
    return res;
  }

  static Future<Map<String, dynamic>> getAnimatedThePinkPantherStrikesAgainForGif(String gifId) async {
    final res = await _request('GET', '/gifs/$gifId/animated-the-pink-panther-strikes-again');
    return res;
  }

  static Future<Map<String, dynamic>> getAnimatedThePinkPantherForGif(String gifId) async {
    final res = await _request('GET', '/gifs/$gifId/animated-the-pink-panther');
    return res;
  }

  static Future<Map<String, dynamic>> getAnimatedAShotInTheDarkForGif(String gifId) async {
    final res = await _request('GET', '/gifs/$gifId/animated-a-shot-in-the-dark');
    return res;
  }

  static Future<Map<String, dynamic>> getAnimatedReturnOfThePinkPantherForGif(String gifId) async {
    final res = await _request('GET', '/gifs/$gifId/animated-return-of-the-pink-panther');
    return res;
  }

  static Future<Map<String, dynamic>> getAnimatedThePinkPanther2ForGif(String gifId) async {
    final res = await _request('GET', '/gifs/$gifId/animated-the-pink-panther2');
    return res;
  }

  static Future<Map<String, dynamic>> getAnimatedThePinkPanther3ForGif(String gifId) async {
    final res = await _request('GET', '/gifs/$gifId/animated-the-pink-panther3');
    return res;
  }

  static Future<Map<String, dynamic>> getAnimatedThePinkPanther4ForGif(String gifId) async {
    final res = await _request('GET', '/gifs/$gifId/animated-the-pink-panther4');
    return res;
  }

  static Future<Map<String, dynamic>> getAnimatedThePinkPanther5ForGif(String gifId) async {
    final res = await _request('GET', '/gifs/$gifId/animated-the-pink-panther5');
    return res;
  }

  static Future<Map<String, dynamic>> getAnimatedThePinkPanther6ForGif(String gifId) async {
    final res = await _request('GET', '/gifs/$gifId/animated-the-pink-panther6');
    return res;
  }

  static Future<Map<String, dynamic>> getAnimatedThePinkPanther7ForGif(String gifId) async {
    final res = await _request('GET', '/gifs/$gifId/animated-the-pink-panther7');
    return res;
  }

  static Future<Map<String, dynamic>> getAnimatedThePinkPanther8ForGif(String gifId) async {
    final res = await _request('GET', '/gifs/$gifId/animated-the-pink-panther8');
    return res;
  }

  static Future<Map<String, dynamic>> getAnimatedThePinkPanther9ForGif(String gifId) async {
    final res = await _request('GET', '/gifs/$gifId/animated-the-pink-panther9');
    return res;
  }

  static Future<Map<String, dynamic>> getAnimatedThePinkPanther10ForGif(String gifId) async {
    final res = await _request('GET', '/gifs/$gifId/animated-the-pink-panther10');
    return res;
  }

  static Future<Map<String, dynamic>> getAnimatedThePinkPanther11ForGif(String gifId) async {
    final res = await _request('GET', '/gifs/$gifId/animated-the-pink-panther11');
    return res;
  }

  static Future<Map<String, dynamic>> getAnimatedThePinkPanther12ForGif(String gifId) async {
    final res = await _request('GET', '/gifs/$gifId/animated-the-pink-panther12');
    return res;
  }

  static Future<Map<String, dynamic>> getAnimatedThePinkPanther13ForGif(String gifId) async {
    final res = await _request('GET', '/gifs/$gifId/animated-the-pink-panther13');
    return res;
  }

  static Future<Map<String, dynamic>> getAnimatedThePinkPanther14ForGif(String gifId) async {
    final res = await _request('GET', '/gifs/$gifId/animated-the-pink-panther14');
    return res;
  }

  static Future<Map<String, dynamic>> getAnimatedThePinkPanther15ForGif(String gifId) async {
    final res = await _request('GET', '/gifs/$gifId/animated-the-pink-panther15');
    return res;
  }

  static Future<Map<String, dynamic>> getAnimatedThePinkPanther16ForGif(String gifId) async {
    final res = await _request('GET', '/gifs/$gifId/animated-the-pink-panther16');
    return res;
  }

  static Future<Map<String, dynamic>> getAnimatedThePinkPanther17ForGif(String gifId) async {
    final res = await _request('GET', '/gifs/$gifId/animated-the-pink-panther17');
    return res;
  }

  static Future<Map<String, dynamic>> getAnimatedThePinkPanther18ForGif(String gifId) async {
    final res = await _request('GET', '/gifs/$gifId/animated-the-pink-panther18');
    return res;
  }

  static Future<Map<String, dynamic>> getAnimatedThePinkPanther19ForGif(String gifId) async {
    final res = await _request('GET', '/gifs/$gifId/animated-the-pink-panther19');
    return res;
  }

  static Future<Map<String, dynamic>> getAnimatedThePinkPanther20ForGif(String gifId) async {
    final res = await _request('GET', '/gifs/$gifId/animated-the-pink-panther20');
    return res;
  }

  static String formatTimeAgo(String dateTimeString) {
    try {
      final date = DateTime.parse(dateTimeString);
      final now = DateTime.now();
      final difference = now.difference(date);

      final days = difference.inDays;
      final hours = difference.inHours.remainder(24);
      final minutes = difference.inMinutes.remainder(60);

      if (days > 0) {
        return '$days д';
      } else if (hours > 0) {
        return '$hours ч';
      } else if (minutes > 0) {
        return '$minutes м';
      } else {
        return 'Только что';
      }
    } catch (e) {
      debugPrint('Error parsing time: $e');
      return 'Неизвестно';
    }
  }

  static String formatTime(String dateTimeString) {
    try {
      final date = DateTime.parse(dateTimeString);
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final messageDate = DateTime(date.year, date.month, date.day);

      if (messageDate == today) {
        return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
      } else if (messageDate == today.subtract(const Duration(days: 1))) {
        return 'Вчера';
      } else {
        return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}';
      }
    } catch (_) {
      return '';
    }
  }
}