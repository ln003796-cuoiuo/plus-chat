import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/user.dart';
import '../models/chat.dart';
import '../models/message.dart';
import 'auth_service.dart';

class ApiService {
  static const String _baseUrl = 'https://плюсчат.рф/api';

  /// Основной метод запроса
  static Future<Map<String, dynamic>> _request(
    String method,
    String endpoint, {
    Map<String, dynamic>? body,
  }) async {
    final token = await AuthService.getToken();
    final headers = <String, String>{
      'Content-Type': 'application/json; charset=utf-8',
      'Accept': 'application/json',
    };
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }

    final uri = Uri.parse('$_baseUrl$endpoint');

    try {
      http.Response response;
      switch (method.toUpperCase()) {
        case 'GET':
          response = await http.get(uri, headers: headers);
          break;
        case 'POST':
          response = await http.post(uri, headers: headers, body: jsonEncode(body));
          break;
        case 'PUT':
          response = await http.put(uri, headers: headers, body: jsonEncode(body));
          break;
        case 'DELETE':
          response = await http.delete(uri, headers: headers);
          break;
        default:
          response = await http.post(uri, headers: headers, body: jsonEncode(body));
      }

      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
      return {'success': false, 'error': 'Неверный формат ответа'};
    } catch (e) {
      return {'success': false, 'error': 'Ошибка сети: $e'};
    }
  }

  // ============================================
  // АВТОРИЗАЦИЯ
  // ============================================

  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) {
    return _request('POST', '/login/login', body: {
      'type': 'password',
      'identifier': email,
      'password': password,
    });
  }

  static Future<Map<String, dynamic>> loginWithCodeRequest({
    required String identifier,
  }) {
    return _request('POST', '/login/login', body: {
      'type': 'code',
      'identifier': identifier,
    });
  }

  static Future<Map<String, dynamic>> verifyEmail({
    required String email,
    required String code,
  }) {
    return _request('POST', '/login/verify', body: {
      'email': email,
      'code': code,
    });
  }

  static Future<Map<String, dynamic>> resendCode({
    required String email,
    required String type,
  }) {
    return _request('POST', '/login/resend-code', body: {
      'email': email,
      'type': type,
    });
  }

  static Future<Map<String, dynamic>> register({
    required String firstName,
    required String lastName,
    required String username,
    required String email,
    required String password,
  }) {
    return _request('POST', '/register/register', body: {
      'first_name': firstName,
      'last_name': lastName,
      'username': username,
      'email': email,
      'password': password,
    });
  }

  // ============================================
  // ПРОФИЛЬ
  // ============================================

  static Future<User?> getMe() async {
    final res = await _request('GET', '/user/me');
    if (res['success'] == true && res['user'] != null) {
      return User.fromJson(res['user'] as Map<String, dynamic>);
    }
    return null;
  }

  static Future<User?> getUserProfile({String? userId, String? username}) async {
    var endpoint = '/user/profile?';
    if (userId != null) endpoint += 'user_id=$userId';
    if (username != null) endpoint += 'username=$username';
    final res = await _request('GET', endpoint);
    if (res['success'] == true && res['user'] != null) {
      return User.fromJson(res['user'] as Map<String, dynamic>);
    }
    return null;
  }

  static Future<List<User>> searchUsers(String query, {int limit = 20}) async {
    final res = await _request('GET', '/user/search?q=${Uri.encodeComponent(query)}&limit=$limit');
    if (res['success'] == true && res['users'] != null) {
      return (res['users'] as List).map((u) => User.fromJson(u as Map<String, dynamic>)).toList();
    }
    return [];
  }

  static Future<Map<String, dynamic>> checkUsername(String username) {
    return _request('GET', '/user/username?username=$username');
  }

  static Future<Map<String, dynamic>> setupProfile({
    required String username,
    required String firstName,
    String? lastName,
    String? bio,
  }) {
    return _request('POST', '/user/setup', body: {
      'username': username,
      'first_name': firstName,
      'last_name': lastName ?? '',
      'bio': bio ?? '',
    });
  }

  static Future<Map<String, dynamic>> updateSettings(Map<String, dynamic> data) {
    return _request('PUT', '/user/settings', body: data);
  }

  static Future<Map<String, dynamic>> sendHeartbeat() {
    return _request('POST', '/user/online');
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

    final res = await _request('GET', endpoint);
    if (res['success'] == true && res['chats'] != null) {
      return (res['chats'] as List)
          .map((c) => Chat.fromJson(c as Map<String, dynamic>))
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
    return _request('GET', '/chats/info?chat_id=$chatId');
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
    return _request('DELETE', '/chats/delete', body: {'chat_id': chatId});
  }

  static Future<Map<String, dynamic>> updateChatInfo(String chatId, Map<String, dynamic> data) {
    return _request('PUT', '/chats/update', body: {'chat_id': chatId, ...data});
  }

  static Future<Map<String, dynamic>> updateChatSettings(String chatId, Map<String, dynamic> data) {
    return _request('PUT', '/chats/settings', body: {'chat_id': chatId, ...data});
  }

  static Future<List<Map<String, dynamic>>> getChatMembers(String chatId) async {
    final res = await _request('GET', '/chats/members?chat_id=$chatId');
    if (res['success'] == true && res['members'] != null) {
      return (res['members'] as List).map((m) => m as Map<String, dynamic>).toList();
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

  // Действия с чатами
  static Future<Map<String, dynamic>> archiveChat(String chatId) {
    return _request('POST', '/chats/actions/archive', body: {'chat_ids': [chatId]});
  }

  static Future<Map<String, dynamic>> unarchiveChat(String chatId) {
    return _request('POST', '/chats/actions/unarchive', body: {'chat_ids': [chatId]});
  }

  static Future<Map<String, dynamic>> muteChat(String chatId, {int duration = 0}) {
    return _request('POST', '/chats/actions/mute', body: {
      'chat_ids': [chatId],
      'duration': duration,
    });
  }

  static Future<Map<String, dynamic>> unmuteChat(String chatId) {
    return _request('POST', '/chats/actions/unmute', body: {'chat_ids': [chatId]});
  }

  static Future<Map<String, dynamic>> favoriteChat(String chatId) {
    return _request('POST', '/chats/actions/favorite', body: {'chat_ids': [chatId]});
  }

  static Future<Map<String, dynamic>> unfavoriteChat(String chatId) {
    return _request('POST', '/chats/actions/unfavorite', body: {'chat_ids': [chatId]});
  }

  static Future<Map<String, dynamic>> markChatRead(String chatId) {
    return _request('POST', '/chats/actions/mark-read', body: {'chat_ids': [chatId]});
  }

  // ============================================
  // СООБЩЕНИЯ
  // ============================================

  static Future<List<Message>> getMessages(String chatId, {int limit = 50, int? before}) async {
    var endpoint = '/messages/list?chat_id=$chatId&limit=$limit';
    if (before != null) endpoint += '&before=$before';

    final res = await _request('GET', endpoint);
    if (res['success'] == true && res['messages'] != null) {
      return (res['messages'] as List)
          .map((m) => Message.fromJson(m as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  static Future<Message?> sendMessage({
    required String chatId,
    required String content,
    String type = 'text',
    String? replyTo,
  }) async {
    final body = <String, dynamic>{
      'chat_id': chatId,
      'content': content,
      'type': type,
    };
    if (replyTo != null) body['reply_to'] = replyTo;

    final res = await _request('POST', '/messages/send', body: body);
    if (res['success'] == true && res['message'] != null) {
      return Message.fromJson(res['message']);
    }
    return null;
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
    final res = await _request('GET', '/messages/search?chat_id=$chatId&q=${Uri.encodeComponent(query)}');
    if (res['success'] == true && res['messages'] != null) {
      return (res['messages'] as List)
          .map((m) => Message.fromJson(m as Map<String, dynamic>))
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

  static Future<List<User>> getFriends({int limit = 50}) async {
    final res = await _request('GET', '/friends/list?limit=$limit');
    if (res['success'] == true && res['friends'] != null) {
      return (res['friends'] as List).map((f) => User.fromJson(f as Map<String, dynamic>)).toList();
    }
    return [];
  }

  static Future<Map<String, dynamic>> getFriendRequests() async {
    final res = await _request('GET', '/friends/requests?type=all');
    if (res['success'] == true) return res;
    return {'incoming': [], 'outgoing': []};
  }

  static Future<List<User>> getContacts({int limit = 50}) async {
    final res = await _request('GET', '/friends/contacts/list?limit=$limit');
    if (res['success'] == true && res['contacts'] != null) {
      return (res['contacts'] as List).map((c) => User.fromJson(c as Map<String, dynamic>)).toList();
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
    final res = await _request('GET', '/friends/status?user_id=$userId');
    if (res['success'] == true) return res;
    return {'friendship_status': 'none'};
  }

  static Future<Map<String, dynamic>> getFriendsCount() async {
    final res = await _request('GET', '/friends/count');
    if (res['success'] == true) return res;
    return {'friends': 0, 'incoming_requests': 0, 'outgoing_requests': 0, 'contacts': 0};
  }

  static Future<List<User>> getFriendSuggestions({int limit = 20}) async {
    final res = await _request('GET', '/friends/suggestions?limit=$limit');
    if (res['success'] == true && res['suggestions'] != null) {
      return (res['suggestions'] as List).map((s) => User.fromJson(s as Map<String, dynamic>)).toList();
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
  // GIF (GIPHY)
  // ============================================

  static Future<List<Map<String, dynamic>>> getTrendingGifs({int limit = 25}) async {
    final res = await _request('GET', '/gifs/trending?limit=$limit');
    if (res['success'] == true && res['gifs'] != null) {
      return (res['gifs'] as List).map((g) => g as Map<String, dynamic>).toList();
    }
    return [];
  }

  static Future<List<Map<String, dynamic>>> searchGifs(String query, {int limit = 25}) async {
    final res = await _request('GET', '/gifs/search?q=${Uri.encodeComponent(query)}&limit=$limit');
    if (res['success'] == true && res['gifs'] != null) {
      return (res['gifs'] as List).map((g) => g as Map<String, dynamic>).toList();
    }
    return [];
  }

  // ============================================
  // СТИКЕРЫ
  // ============================================

  static Future<List<Map<String, dynamic>>> getStickerPacks() async {
    final res = await _request('GET', '/stickers/packs');
    if (res['success'] == true && res['packs'] != null) {
      return (res['packs'] as List).map((p) => p as Map<String, dynamic>).toList();
    }
    return [];
  }

  static Future<Map<String, dynamic>> getStickerPack(int packId) async {
    final res = await _request('GET', '/stickers/pack?id=$packId');
    if (res['success'] == true) return res;
    return {'pack': null, 'stickers': []};
  }

  static Future<List<Map<String, dynamic>>> getInstalledPacks() async {
    final res = await _request('GET', '/stickers/installed');
    if (res['success'] == true && res['packs'] != null) {
      return (res['packs'] as List).map((p) => p as Map<String, dynamic>).toList();
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
    if (category != null) url += '&category=$category';
    final res = await _request('GET', url);
    if (res['success'] == true && res['gifts'] != null) {
      return (res['gifts'] as List).map((g) => g as Map<String, dynamic>).toList();
    }
    return [];
  }

  static Future<List<Map<String, dynamic>>> getGiftCategories() async {
    final res = await _request('GET', '/gifts/categories');
    if (res['success'] == true && res['categories'] != null) {
      return (res['categories'] as List).map((c) => c as Map<String, dynamic>).toList();
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
    final res = await _request('GET', '/gifts/received');
    if (res['success'] == true && res['gifts'] != null) {
      return (res['gifts'] as List).map((g) => g as Map<String, dynamic>).toList();
    }
    return [];
  }

  static Future<List<Map<String, dynamic>>> getSentGifts() async {
    final res = await _request('GET', '/gifts/sent');
    if (res['success'] == true && res['gifts'] != null) {
      return (res['gifts'] as List).map((g) => g as Map<String, dynamic>).toList();
    }
    return [];
  }
}