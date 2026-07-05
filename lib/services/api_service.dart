import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'auth_service.dart';
import '../models/user.dart';
import '../models/chat.dart';
import '../models/message.dart';

class ApiService {
  static const String baseUrl = 'https://xn--80avljg2a1c.xn--p1ai';

  static Future<Map<String, dynamic>> _request(
    String method,
    String endpoint, {
    Map<String, dynamic>? body,
    bool auth = true,
  }) async {
    final url = Uri.parse('$baseUrl$endpoint');
    final headers = <String, String>{
      'Content-Type': 'application/json; charset=utf-8',
      'Accept': 'application/json',
    };

    if (auth) {
      final token = await AuthService.getToken();
      
      // ✅ Логирование для отладки
      if (kDebugMode) {
        print('[API] $method $endpoint');
        print('[API] Token: ${token != null ? '${token.substring(0, 20)}...' : 'NULL'}');
      }
      
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      } else {
        if (kDebugMode) {
          print('[API] ⚠️ Token is null or empty!');
        }
      }
    }

    try {
      http.Response response;
      switch (method.toUpperCase()) {
        case 'GET':
          response = await http.get(url, headers: headers);
          break;
        case 'POST':
          response = await http.post(
            url,
            headers: headers,
            body: body != null ? jsonEncode(body) : null,
          );
          break;
        case 'PUT':
          response = await http.put(
            url,
            headers: headers,
            body: body != null ? jsonEncode(body) : null,
          );
          break;
        case 'DELETE':
          response = await http.delete(url, headers: headers);
          break;
        default:
          throw Exception('Неподдерживаемый метод: $method');
      }

      if (kDebugMode) {
        print('[API] Response ${response.statusCode}: ${response.body.substring(0, response.body.length > 200 ? 200 : response.body.length)}...');
      }

      final data = jsonDecode(response.body);
      
      // ✅ Если 401 — чистим токен
      if (response.statusCode == 401) {
        if (kDebugMode) {
          print('[API] ⚠️ 401 Unauthorized — clearing tokens');
        }
        await AuthService.logout();
        return {
          'success': false,
          'error': 'Сессия истекла. Войдите снова',
        };
      }
      
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return data;
      } else {
        return {
          'success': false,
          'error': data['error'] ?? 'Ошибка ${response.statusCode}',
        };
      }
    } catch (e) {
      if (kDebugMode) {
        print('[API] ❌ Error: $e');
      }
      return {
        'success': false,
        'error': 'Ошибка сети: $e',
      };
    }
  }

  // ============================================
  // АВТОРИЗАЦИЯ
  // ============================================
  static Future<Map<String, dynamic>> register({
    required String firstName,
    required String lastName,
    String? middleName,
    required String username,
    required String email,
    required String password,
  }) {
    return _request('POST', '/register/register', auth: false, body: {
      'first_name': firstName,
      'last_name': lastName,
      'middle_name': middleName ?? '',
      'username': username,
      'email': email,
      'password': password,
    });
  }

  static Future<Map<String, dynamic>> login({
    required String identifier,
    required String password,
  }) async {
    final data = await _request('POST', '/login/login', auth: false, body: {
      'type': 'password',
      'identifier': identifier,
      'password': password,
    });
    if (data['success'] == true && data['access_token'] != null) {
      await _saveAuthData(data);
    }
    return data;
  }

  static Future<Map<String, dynamic>> loginWithCodeRequest({
    required String identifier,
  }) {
    return _request('POST', '/login/login', auth: false, body: {
      'type': 'code',
      'identifier': identifier,
    });
  }

  static Future<Map<String, dynamic>> loginWithCodeVerify({
    required String identifier,
    required String code,
  }) async {
    final data = await _request('POST', '/login/login', auth: false, body: {
      'type': 'code',
      'identifier': identifier,
      'code': code,
    });
    if (data['success'] == true && data['access_token'] != null) {
      await _saveAuthData(data);
    }
    return data;
  }

  static Future<Map<String, dynamic>> verifyEmail({
    required String email,
    required String code,
  }) async {
    final data = await _request('POST', '/login/verify', auth: false, body: {
      'email': email,
      'code': code,
    });
    if (data['success'] == true && data['access_token'] != null) {
      await _saveAuthData(data);
    }
    return data;
  }

  static Future<Map<String, dynamic>> resendCode({
    required String email,
    required String type,
  }) {
    return _request('POST', '/login/resend-code', auth: false, body: {
      'email': email,
      'type': type,
    });
  }

  // ============================================
  // ПОЛЬЗОВАТЕЛЬ
  // ============================================
  static Future<User?> getMe() async {
    final data = await _request('GET', '/user/me');
    if (data['success'] == true && data['user'] != null) {
      return User.fromJson(data['user']);
    }
    final userId = await AuthService.getUserId();
    if (userId == null) return null;
    return User(
      id: userId,
      email: await AuthService.getEmail(),
      username: await AuthService.getUsername(),
      firstName: await AuthService.getFirstName() ?? 'Пользователь',
      lastName: await AuthService.getLastName(),
    );
  }

  static Future<Map<String, dynamic>> checkUsername(String username) {
    return _request('GET', '/user/username?username=${Uri.encodeComponent(username)}', auth: false);
  }

  static Future<Map<String, dynamic>> setupProfile({
    required String username,
    required String firstName,
    String? lastName,
  }) async {
    final data = await _request('PUT', '/user/setup', body: {
      'username': username,
      'first_name': firstName,
      'last_name': lastName,
    });
    if (data['success'] == true) {
      await AuthService.saveUserInfo(
        email: await AuthService.getEmail() ?? '',
        username: username,
        firstName: firstName,
        lastName: lastName ?? '',
      );
    }
    return data;
  }

  static Future<Map<String, dynamic>> updateSettings(Map<String, dynamic> settings) {
    return _request('PUT', '/user/settings', body: settings);
  }

  static Future<User?> getUserProfile(String userId) async {
    final data = await _request('GET', '/user/profile?user_id=${Uri.encodeComponent(userId)}');
    if (data['success'] == true && data['user'] != null) {
      return User.fromJson(data['user']);
    }
    return null;
  }

  // ✅ ИСПРАВЛЕНО: URL-кодирование параметров
  static Future<List<User>> searchUsers(String query, {String type = 'all'}) async {
    final encodedQuery = Uri.encodeComponent(query);
    final data = await _request('GET', '/user/search?q=$encodedQuery&type=$type');
    if (data['success'] == true && data['users'] != null) {
      return (data['users'] as List)
          .map((u) => User.fromJson(u))
          .toList();
    }
    return [];
  }

  // ✅ ИСПРАВЛЕНО: URL-кодирование параметров
  static Future<List<User>> searchUsersByName({
    String? firstName,
    String? lastName,
    String? middleName,
  }) async {
    final params = <String>[];
    if (firstName != null && firstName.isNotEmpty) {
      params.add('first_name=${Uri.encodeComponent(firstName)}');
    }
    if (lastName != null && lastName.isNotEmpty) {
      params.add('last_name=${Uri.encodeComponent(lastName)}');
    }
    if (middleName != null && middleName.isNotEmpty) {
      params.add('middle_name=${Uri.encodeComponent(middleName)}');
    }
    
    final url = '/user/search-by-name?${params.join('&')}';
    final data = await _request('GET', url);
    if (data['success'] == true && data['users'] != null) {
      return (data['users'] as List)
          .map((u) => User.fromJson(u))
          .toList();
    }
    return [];
  }

  static Future<void> sendHeartbeat() async {
    await _request('POST', '/user/online');
  }

  // ============================================
  // ЧАТЫ
  // ============================================
  static Future<List<Chat>> getChats({
    bool archived = false,
    bool favorites = false,
    String? type,
    int limit = 50,
    int offset = 0,
  }) async {
    var endpoint = '/chats/list?limit=$limit&offset=$offset';
    if (archived) endpoint += '&archived=1';
    if (favorites) endpoint += '&favorites=1';
    if (type != null) endpoint += '&type=$type';

    final data = await _request('GET', endpoint);
    if (data['success'] == true && data['chats'] != null) {
      return (data['chats'] as List)
          .map((c) => Chat.fromJson(c))
          .toList();
    }
    return [];
  }

  static Future<Map<String, dynamic>> createChat({
    required String type,
    String? title,
    String? description,
    bool isPublic = false,
    List<String>? members,
  }) {
    return _request('POST', '/chats/create', body: {
      'type': type,
      'title': title ?? '',
      'description': description ?? '',
      'is_public': isPublic ? 1 : 0,
      'members': members ?? [],
    });
  }

  static Future<Map<String, dynamic>> getChatInfo(String chatId) {
    return _request('GET', '/chats/info?chat_id=${Uri.encodeComponent(chatId)}');
  }

  static Future<Map<String, dynamic>> findPrivateChat(String userId) {
    return _request('GET', '/chats/find-private?user_id=${Uri.encodeComponent(userId)}');
  }

  static Future<Map<String, dynamic>> joinChat(String chatId, {String? inviteCode}) {
    return _request('POST', '/chats/join', body: {
      'chat_id': chatId,
      'invite_code': inviteCode ?? '',
    });
  }

  static Future<Map<String, dynamic>> leaveChat(String chatId) {
    return _request('POST', '/chats/leave', body: {'chat_id': chatId});
  }

  static Future<Map<String, dynamic>> deleteChat(String chatId) {
    return _request('POST', '/chats/actions/delete', body: {'chat_ids': [chatId]});
  }

  static Future<Map<String, dynamic>> updateChatInfo(String chatId, Map<String, dynamic> data) {
    return _request('PUT', '/chats/update', body: {'chat_id': chatId, ...data});
  }

  static Future<Map<String, dynamic>> updateChatSettings(String chatId, Map<String, dynamic> data) {
    return _request('PUT', '/chats/settings', body: {'chat_id': chatId, ...data});
  }

  static Future<List<Map<String, dynamic>>> getChatMembers(String chatId) async {
    final data = await _request('GET', '/chats/members?chat_id=${Uri.encodeComponent(chatId)}');
    if (data['success'] == true && data['members'] != null) {
      return (data['members'] as List).cast<Map<String, dynamic>>();
    }
    return [];
  }

  static Future<Map<String, dynamic>> addMembers(String chatId, List<String> memberIds) {
    return _request('POST', '/chats/add-members', body: {
      'chat_id': chatId,
      'members': memberIds,
    });
  }

  static Future<Map<String, dynamic>> removeMember(String chatId, String userId) {
    return _request('POST', '/chats/remove-member', body: {
      'chat_id': chatId,
      'user_id': userId,
    });
  }

  static Future<Map<String, dynamic>> createInviteLink(String chatId) {
    return _request('POST', '/chats/invite', body: {'chat_id': chatId});
  }

  static Future<Map<String, dynamic>> archiveChats(List<String> chatIds) {
    return _request('POST', '/chats/actions/archive', body: {'chat_ids': chatIds});
  }

  static Future<Map<String, dynamic>> unarchiveChats(List<String> chatIds) {
    return _request('POST', '/chats/actions/unarchive', body: {'chat_ids': chatIds});
  }

  static Future<Map<String, dynamic>> muteChats(List<String> chatIds, {int duration = 0}) {
    return _request('POST', '/chats/actions/mute', body: {
      'chat_ids': chatIds,
      'duration': duration,
    });
  }

  static Future<Map<String, dynamic>> unmuteChats(List<String> chatIds) {
    return _request('POST', '/chats/actions/unmute', body: {'chat_ids': chatIds});
  }

  static Future<Map<String, dynamic>> favoriteChats(List<String> chatIds) {
    return _request('POST', '/chats/actions/favorite', body: {'chat_ids': chatIds});
  }

  static Future<Map<String, dynamic>> unfavoriteChats(List<String> chatIds) {
    return _request('POST', '/chats/actions/unfavorite', body: {'chat_ids': chatIds});
  }

  static Future<Map<String, dynamic>> markChatsRead(List<String> chatIds) {
    return _request('POST', '/chats/actions/mark-read', body: {'chat_ids': chatIds});
  }

  // ============================================
  // СООБЩЕНИЯ
  // ============================================
  static Future<List<Message>> getMessages(String chatId, {int limit = 50, int? before}) async {
    var endpoint = '/messages/list?chat_id=${Uri.encodeComponent(chatId)}&limit=$limit';
    if (before != null) endpoint += '&before=$before';

    final data = await _request('GET', endpoint);
    if (data['success'] == true && data['messages'] != null) {
      return (data['messages'] as List)
          .map((m) => Message.fromJson(m))
          .toList();
    }
    return [];
  }

  static Future<Map<String, dynamic>> sendMessage({
    required String chatId,
    required String content,
    String type = 'text',
    String? replyTo,
  }) {
    final body = <String, dynamic>{
      'chat_id': chatId,
      'content': content,
      'type': type,
    };
    if (replyTo != null) body['reply_to'] = replyTo;
    return _request('POST', '/messages/send', body: body);
  }

  static Future<Map<String, dynamic>> editMessage(int messageId, String newContent) {
    return _request('PUT', '/messages/edit', body: {
      'message_id': messageId,
      'content': newContent,
    });
  }

  static Future<Map<String, dynamic>> deleteMessage(int messageId, {bool forAll = false}) {
    return _request('DELETE', '/messages/delete', body: {
      'message_id': messageId,
      'for_all': forAll,
    });
  }

  static Future<Map<String, dynamic>> markAsRead(int messageId) {
    return _request('PUT', '/messages/read', body: {'message_id': messageId});
  }

  static Future<Map<String, dynamic>> reactToMessage(int messageId, String emoji) {
    return _request('POST', '/messages/react', body: {
      'message_id': messageId,
      'emoji': emoji,
    });
  }

  static Future<Map<String, dynamic>> pinMessage(int messageId, String chatId, {bool unpin = false}) {
    return _request('PUT', '/messages/pin', body: {
      'message_id': messageId,
      'chat_id': chatId,
      'unpin': unpin,
    });
  }

  static Future<Map<String, dynamic>> sendGif({
    required String chatId,
    required String gifUrl,
    String? gifId,
    int? width,
    int? height,
    String? replyTo,
  }) {
    final body = <String, dynamic>{
      'chat_id': chatId,
      'gif_url': gifUrl,
    };
    if (gifId != null) body['gif_id'] = gifId;
    if (width != null) body['width'] = width;
    if (height != null) body['height'] = height;
    if (replyTo != null) body['reply_to'] = replyTo;
    return _request('POST', '/messages/send-gif', body: body);
  }

  static Future<Map<String, dynamic>> sendSticker({
    required String chatId,
    required String stickerUrl,
    String? stickerId,
    String? emoji,
    String? replyTo,
  }) {
    final body = <String, dynamic>{
      'chat_id': chatId,
      'sticker_url': stickerUrl,
    };
    if (stickerId != null) body['sticker_id'] = stickerId;
    if (emoji != null) body['emoji'] = emoji;
    if (replyTo != null) body['reply_to'] = replyTo;
    return _request('POST', '/messages/send-sticker', body: body);
  }

  static Future<Map<String, dynamic>> sendTypingStatus(String chatId, bool isTyping) {
    return _request('POST', '/messages/typing', body: {
      'chat_id': chatId,
      'is_typing': isTyping,
    });
  }

  static Future<List<Message>> searchMessages(String chatId, String query) async {
    final encodedQuery = Uri.encodeComponent(query);
    final data = await _request('GET', '/messages/search?chat_id=${Uri.encodeComponent(chatId)}&q=$encodedQuery');
    if (data['success'] == true && data['messages'] != null) {
      return (data['messages'] as List)
          .map((m) => Message.fromJson(m))
          .toList();
    }
    return [];
  }

  static Future<Map<String, dynamic>> forwardMessage(int messageId, String targetChatId) {
    return _request('POST', '/messages/forward', body: {
      'message_id': messageId,
      'target_chat_id': targetChatId,
    });
  }

  // ============================================
  // ДРУЗЬЯ
  // ============================================
  static Future<List<User>> getFriends({int limit = 50, String? q}) async {
    var url = '/friends/list?limit=$limit';
    if (q != null && q.isNotEmpty) url += '&q=${Uri.encodeComponent(q)}';
    final data = await _request('GET', url);
    if (data['success'] == true && data['friends'] != null) {
      return (data['friends'] as List)
          .map((f) => User.fromJson(f))
          .toList();
    }
    return [];
  }

  static Future<Map<String, dynamic>> getFriendRequests() {
    return _request('GET', '/friends/requests?type=all');
  }

  static Future<List<User>> getContacts({int limit = 50, String? q, String? filter}) async {
    var url = '/friends/contacts/list?limit=$limit';
    if (q != null && q.isNotEmpty) url += '&q=${Uri.encodeComponent(q)}';
    if (filter != null) url += '&filter=$filter';
    final data = await _request('GET', url);
    if (data['success'] == true && data['contacts'] != null) {
      return (data['contacts'] as List)
          .map((c) => User.fromJson(c))
          .toList();
    }
    return [];
  }

  static Future<Map<String, dynamic>> sendFriendRequest(String userId, {String? message}) {
    return _request('POST', '/friends/request', body: {
      'user_id': userId,
      'message': message ?? '',
    });
  }

  static Future<Map<String, dynamic>> acceptFriendRequest(String requestId) {
    return _request('POST', '/friends/accept', body: {'request_id': requestId});
  }

  static Future<Map<String, dynamic>> rejectFriendRequest(String requestId) {
    return _request('POST', '/friends/reject', body: {'request_id': requestId});
  }

  static Future<Map<String, dynamic>> cancelFriendRequest(String userId) {
    return _request('POST', '/friends/cancel', body: {'user_id': userId});
  }

  static Future<Map<String, dynamic>> removeFriend(String userId) {
    return _request('POST', '/friends/remove', body: {'user_id': userId});
  }

  static Future<Map<String, dynamic>> getFriendStatus(String userId) async {
    final data = await _request('GET', '/friends/status?user_id=${Uri.encodeComponent(userId)}');
    if (data['success'] == true) return data;
    return {'friendship_status': 'none'};
  }

  static Future<Map<String, dynamic>> getFriendsCount() async {
    final data = await _request('GET', '/friends/count');
    if (data['success'] == true) return data;
    return {'friends': 0, 'incoming_requests': 0, 'outgoing_requests': 0, 'contacts': 0};
  }

  static Future<List<User>> getFriendSuggestions({int limit = 20}) async {
    final data = await _request('GET', '/friends/suggestions?limit=$limit');
    if (data['success'] == true && data['suggestions'] != null) {
      return (data['suggestions'] as List)
          .map((s) => User.fromJson(s))
          .toList();
    }
    return [];
  }

  static Future<Map<String, dynamic>> blockUser(String userId) {
    return _request('POST', '/friends/contacts/block', body: {'user_id': userId});
  }

  static Future<Map<String, dynamic>> unblockUser(String userId) {
    return _request('POST', '/friends/contacts/unblock', body: {'user_id': userId});
  }

  // ============================================
  // GIF
  // ============================================
  static Future<List<Map<String, dynamic>>> getTrendingGifs({int limit = 25}) async {
    final data = await _request('GET', '/gifs/trending?limit=$limit');
    if (data['success'] == true && data['gifs'] != null) {
      return (data['gifs'] as List).cast<Map<String, dynamic>>();
    }
    return [];
  }

  static Future<List<Map<String, dynamic>>> searchGifs(String query, {int limit = 25}) async {
    final encodedQuery = Uri.encodeComponent(query);
    final data = await _request('GET', '/gifs/search?q=$encodedQuery&limit=$limit');
    if (data['success'] == true && data['gifs'] != null) {
      return (data['gifs'] as List).cast<Map<String, dynamic>>();
    }
    return [];
  }

  // ============================================
  // СТИКЕРЫ
  // ============================================
  static Future<List<Map<String, dynamic>>> getStickerPacks() async {
    final data = await _request('GET', '/stickers/packs');
    if (data['success'] == true && data['packs'] != null) {
      return (data['packs'] as List).cast<Map<String, dynamic>>();
    }
    return [];
  }

  static Future<Map<String, dynamic>> getStickerPack(int packId) async {
    final data = await _request('GET', '/stickers/pack?id=$packId');
    if (data['success'] == true) return data;
    return {'pack': null, 'stickers': []};
  }

  static Future<List<Map<String, dynamic>>> getInstalledPacks() async {
    final data = await _request('GET', '/stickers/installed');
    if (data['success'] == true && data['packs'] != null) {
      return (data['packs'] as List).cast<Map<String, dynamic>>();
    }
    return [];
  }

  static Future<Map<String, dynamic>> installPack(int packId) {
    return _request('POST', '/stickers/install', body: {'pack_id': packId});
  }

  static Future<Map<String, dynamic>> uninstallPack(int packId) {
    return _request('POST', '/stickers/uninstall', body: {'pack_id': packId});
  }

  // ============================================
  // ПОДАРКИ
  // ============================================
  static Future<List<Map<String, dynamic>>> getGifts({String? category, String sort = 'popular'}) async {
    var url = '/gifts/list?sort=$sort';
    if (category != null) url += '&category=${Uri.encodeComponent(category)}';
    final data = await _request('GET', url);
    if (data['success'] == true && data['gifts'] != null) {
      return (data['gifts'] as List).cast<Map<String, dynamic>>();
    }
    return [];
  }

  static Future<List<Map<String, dynamic>>> getGiftCategories() async {
    final data = await _request('GET', '/gifts/categories');
    if (data['success'] == true && data['categories'] != null) {
      return (data['categories'] as List).cast<Map<String, dynamic>>();
    }
    return [];
  }

  static Future<Map<String, dynamic>> sendGift({
    required int giftId,
    required String receiverId,
    String? message,
    bool isAnonymous = false,
  }) {
    final body = <String, dynamic>{
      'gift_id': giftId,
      'receiver_id': receiverId,
      'is_anonymous': isAnonymous,
    };
    if (message != null && message.isNotEmpty) body['message'] = message;
    return _request('POST', '/gifts/send', body: body);
  }

  static Future<List<Map<String, dynamic>>> getReceivedGifts() async {
    final data = await _request('GET', '/gifts/received');
    if (data['success'] == true && data['gifts'] != null) {
      return (data['gifts'] as List).cast<Map<String, dynamic>>();
    }
    return [];
  }

  static Future<List<Map<String, dynamic>>> getSentGifts() async {
    final data = await _request('GET', '/gifts/sent');
    if (data['success'] == true && data['gifts'] != null) {
      return (data['gifts'] as List).cast<Map<String, dynamic>>();
    }
    return [];
  }

  // ============================================
  // ВСПОМОГАТЕЛЬНЫЙ
  // ============================================
  static Future<void> _saveAuthData(Map<String, dynamic> data) async {
    if (data['access_token'] != null) {
      await AuthService.saveTokens(
        data['access_token'].toString(),
        data['refresh_token']?.toString() ?? '',
      );
    }
    if (data['user'] != null) {
      final user = data['user'];
      if (user['id'] != null) {
        await AuthService.saveUserId(user['id'].toString());
      }
      await AuthService.saveUserInfo(
        email: user['email']?.toString() ?? '',
        username: user['username']?.toString() ?? '',
        firstName: user['first_name']?.toString() ?? '',
        lastName: user['last_name']?.toString() ?? '',
      );
    }
  }
}