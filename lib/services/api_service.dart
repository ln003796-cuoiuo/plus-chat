import 'dart:convert';
import 'package:http/http.dart' as http;
import 'auth_service.dart';
import '../models/user.dart';
import '../models/chat.dart';
import '../models/message.dart';

class ApiService {
  static const String baseUrl = 'https://xn--80avljg2a1c.xn--p1ai';

  // ============================================
  // БАЗОВЫЙ МЕТОД
  // ============================================
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
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
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

      final data = jsonDecode(response.body);
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return data;
      } else {
        return {
          'success': false,
          'error': data['error'] ?? 'Ошибка ${response.statusCode}',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Ошибка сети: $e',
      };
    }
  }

  // ============================================
  // АВТОРИЗАЦИЯ
  // ============================================

  /// Регистрация
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

  // ============================================
  // ВХОД ПО ПАРОЛЮ (/login/login)
  // ============================================
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

  /// Вход по коду (запрос кода)
  static Future<Map<String, dynamic>> loginWithCodeRequest({
    required String identifier,
  }) {
    return _request('POST', '/login/login', auth: false, body: {
      'type': 'code',
      'identifier': identifier,
    });
  }

  /// Подтверждение email
  static Future<Map<String, dynamic>> verifyEmail({
    required String email,
    required String code,
  }) {
    return _request('POST', '/login/verify', auth: false, body: {
      'email': email,
      'code': code,
    });
  }

  /// Повторная отправка кода
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

  /// Получить текущего пользователя
  /// Получить текущего пользователя
 static Future<User?> getMe() async {
   final userId = await AuthService.getUserId();
   final email = await AuthService.getEmail();
   final username = await AuthService.getUsername();
   final firstName = await AuthService.getFirstName();
   final lastName = await AuthService.getLastName();
   
   if (userId == null) return null;
   
   return User(
     id: userId,
     email: email,
     username: username,
     firstName: firstName ?? 'Пользователь',
     lastName: lastName,
   );
 }

  /// Проверка доступности username
  static Future<Map<String, dynamic>> checkUsername(String username) {
    return _request('GET', '/user/check-username?username=$username', auth: false);
  }

  /// Первоначальная настройка профиля
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

  /// Обновить настройки пользователя
  static Future<Map<String, dynamic>> updateSettings(Map<String, dynamic> settings) {
    return _request('PUT', '/user/settings', body: settings);
  }

  /// Получить профиль другого пользователя
  static Future<User?> getUserProfile(String userId) async {
    final data = await _request('GET', '/user/profile?user_id=$userId');
    if (data['success'] == true && data['user'] != null) {
      return User.fromJson(data['user']);
    }
    return null;
  }

  /// Поиск пользователей
  static Future<List<User>> searchUsers(String query) async {
    final data = await _request('GET', '/user/search?q=$query');
    if (data['success'] == true && data['users'] != null) {
      return (data['users'] as List)
          .map((u) => User.fromJson(u))
          .toList();
    }
    return [];
  }

  /// Heartbeat онлайн
  static Future<void> sendHeartbeat() async {
    await _request('POST', '/user/online');
  }

  // ============================================
  // ЧАТЫ
  // ============================================

  /// Получить список чатов
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

  /// Создать чат
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

  /// Информация о чате
  static Future<Map<String, dynamic>> getChatInfo(String chatId) {
    return _request('GET', '/chats/info?chat_id=$chatId');
  }

  /// Подписаться на чат
  static Future<Map<String, dynamic>> joinChat(String chatId, {String? inviteCode}) {
    return _request('POST', '/chats/join', body: {
      'chat_id': chatId,
      'invite_code': inviteCode ?? '',
    });
  }

  /// Выйти из чата
  static Future<Map<String, dynamic>> leaveChat(String chatId) {
    return _request('POST', '/chats/leave', body: {'chat_id': chatId});
  }

  /// Удалить чат
  static Future<Map<String, dynamic>> deleteChat(String chatId) {
    return _request('DELETE', '/chats/delete', body: {'chat_id': chatId});
  }

  /// Обновить информацию о чате
  static Future<Map<String, dynamic>> updateChatInfo(String chatId, Map<String, dynamic> data) {
    return _request('PUT', '/chats/update', body: {'chat_id': chatId, ...data});
  }

  /// Обновить настройки чата
  static Future<Map<String, dynamic>> updateChatSettings(String chatId, Map<String, dynamic> data) {
    return _request('PUT', '/chats/settings', body: {'chat_id': chatId, ...data});
  }

  /// Получить участников чата
  static Future<List<Map<String, dynamic>>> getChatMembers(String chatId) async {
    final data = await _request('GET', '/chats/members?chat_id=$chatId');
    if (data['success'] == true && data['members'] != null) {
      return (data['members'] as List).cast<Map<String, dynamic>>();
    }
    return [];
  }

  /// Добавить участников
  static Future<Map<String, dynamic>> addMembers(String chatId, List<String> memberIds) {
    return _request('POST', '/chats/add-members', body: {
      'chat_id': chatId,
      'members': memberIds,
    });
  }

  /// Удалить участника
  static Future<Map<String, dynamic>> removeMember(String chatId, String userId) {
    return _request('POST', '/chats/remove-member', body: {
      'chat_id': chatId,
      'user_id': userId,
    });
  }

  /// Создать ссылку-приглашение
  static Future<Map<String, dynamic>> createInviteLink(String chatId) {
    return _request('POST', '/chats/invite', body: {'chat_id': chatId});
  }

  // Действия с чатами
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

  static Future<Map<String, dynamic>> muteChat(String chatId, {int duration = 0}) {
   return muteChats([chatId], duration: duration);
 }

  static Future<Map<String, dynamic>> unmuteChat(String chatId) {
   return unmuteChats([chatId]);
 }
  // ============================================
  // СООБЩЕНИЯ
  // ============================================

  /// Получить историю сообщений
  static Future<List<Message>> getMessages(String chatId, {int limit = 50, int? before}) async {
    var endpoint = '/messages/list?chat_id=$chatId&limit=$limit';
    if (before != null) endpoint += '&before=$before';

    final data = await _request('GET', endpoint);
    if (data['success'] == true && data['messages'] != null) {
      return (data['messages'] as List)
          .map((m) => Message.fromJson(m))
          .toList();
    }
    return [];
  }

  /// Отправить текстовое сообщение
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

  /// Редактировать сообщение
  static Future<Map<String, dynamic>> editMessage(int messageId, String newContent) {
    return _request('PUT', '/messages/edit', body: {
      'message_id': messageId,
      'content': newContent,
    });
  }

  /// Удалить сообщение
  static Future<Map<String, dynamic>> deleteMessage(int messageId, {bool forAll = false}) {
    return _request('DELETE', '/messages/delete', body: {
      'message_id': messageId,
      'for_all': forAll,
    });
  }

  /// Пометить как прочитанное
  static Future<Map<String, dynamic>> markAsRead(int messageId) {
    return _request('PUT', '/messages/read', body: {'message_id': messageId});
  }

  /// Реакция на сообщение
  static Future<Map<String, dynamic>> reactToMessage(int messageId, String emoji) {
    return _request('POST', '/messages/$messageId/react', body: {'emoji': emoji});
  }

  /// Закрепить сообщение
  static Future<Map<String, dynamic>> pinMessage(int messageId, String chatId, {bool unpin = false}) {
    return _request('PUT', '/messages/pin', body: {
      'message_id': messageId,
      'chat_id': chatId,
      'unpin': unpin,
    });
  }

  /// Отправить GIF
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

  /// Отправить стикер
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

  /// Статус "печатает"
  static Future<Map<String, dynamic>> sendTypingStatus(String chatId, bool isTyping) {
    return _request('POST', '/messages/typing', body: {
      'chat_id': chatId,
      'is_typing': isTyping,
    });
  }

  // ============================================
  // ДРУЗЬЯ
  // ============================================

  /// Список друзей
  static Future<List<User>> getFriends({int limit = 50}) async {
    final data = await _request('GET', '/friends/list?limit=$limit');
    if (data['success'] == true && data['friends'] != null) {
      return (data['friends'] as List)
          .map((f) => User.fromJson(f))
          .toList();
    }
    return [];
  }

  /// Запросы в друзья
  static Future<Map<String, dynamic>> getFriendRequests() {
    return _request('GET', '/friends/requests?type=all');
  }

  /// Список контактов
  static Future<List<User>> getContacts({int limit = 50}) async {
    final data = await _request('GET', '/friends/contacts/list?limit=$limit');
    if (data['success'] == true && data['contacts'] != null) {
      return (data['contacts'] as List)
          .map((c) => User.fromJson(c))
          .toList();
    }
    return [];
  }

  /// Отправить запрос в друзья
  static Future<Map<String, dynamic>> sendFriendRequest(String userId, {String? message}) {
    return _request('POST', '/friends/request', body: {
      'user_id': userId,
      'message': message ?? '',
    });
  }

  /// Принять запрос
  static Future<Map<String, dynamic>> acceptFriendRequest(String requestId) {
    return _request('POST', '/friends/accept', body: {'request_id': requestId});
  }

  /// Отклонить запрос
  static Future<Map<String, dynamic>> rejectFriendRequest(String requestId) {
    return _request('POST', '/friends/reject', body: {'request_id': requestId});
  }

  /// Отменить свой запрос
  static Future<Map<String, dynamic>> cancelFriendRequest(String userId) {
    return _request('POST', '/friends/cancel', body: {'user_id': userId});
  }

  /// Удалить из друзей
  static Future<Map<String, dynamic>> removeFriend(String userId) {
    return _request('POST', '/friends/remove', body: {'user_id': userId});
  }

  /// Статус дружбы
  static Future<Map<String, dynamic>> getFriendStatus(String userId) async {
    final data = await _request('GET', '/friends/status?user_id=$userId');
    if (data['success'] == true) return data;
    return {'friendship_status': 'none'};
  }

  /// Счётчики
  static Future<Map<String, dynamic>> getFriendsCount() async {
    final data = await _request('GET', '/friends/count');
    if (data['success'] == true) return data;
    return {'friends': 0, 'incoming_requests': 0, 'outgoing_requests': 0, 'contacts': 0};
  }

  /// Рекомендации
  static Future<List<User>> getFriendSuggestions({int limit = 20}) async {
    final data = await _request('GET', '/friends/suggestions?limit=$limit');
    if (data['success'] == true && data['suggestions'] != null) {
      return (data['suggestions'] as List)
          .map((s) => User.fromJson(s))
          .toList();
    }
    return [];
  }

  /// Заблокировать
  static Future<Map<String, dynamic>> blockUser(String userId) {
    return _request('POST', '/friends/contacts/block', body: {'user_id': userId});
  }

  /// Разблокировать
  static Future<Map<String, dynamic>> unblockUser(String userId) {
    return _request('POST', '/friends/contacts/unblock', body: {'user_id': userId});
  }

  // ============================================
  // GIF (GIPHY)
  // ============================================

  /// Трендовые GIF
  static Future<List<Map<String, dynamic>>> getTrendingGifs({int limit = 25}) async {
    final data = await _request('GET', '/gifs/trending?limit=$limit');
    if (data['success'] == true && data['gifs'] != null) {
      return (data['gifs'] as List).cast<Map<String, dynamic>>();
    }
    return [];
  }

  /// Поиск GIF
  static Future<List<Map<String, dynamic>>> searchGifs(String query, {int limit = 25}) async {
    final data = await _request('GET', '/gifs/search?q=${Uri.encodeComponent(query)}&limit=$limit');
    if (data['success'] == true && data['gifs'] != null) {
      return (data['gifs'] as List).cast<Map<String, dynamic>>();
    }
    return [];
  }

  // ============================================
  // СТИКЕРЫ
  // ============================================

  /// Список паков стикеров
  static Future<List<Map<String, dynamic>>> getStickerPacks() async {
    final data = await _request('GET', '/stickers/packs');
    if (data['success'] == true && data['packs'] != null) {
      return (data['packs'] as List).cast<Map<String, dynamic>>();
    }
    return [];
  }

  /// Содержимое пака
  static Future<Map<String, dynamic>> getStickerPack(int packId) async {
    final data = await _request('GET', '/stickers/pack?id=$packId');
    if (data['success'] == true) return data;
    return {'pack': null, 'stickers': []};
  }

  /// Установленные паки
  static Future<List<Map<String, dynamic>>> getInstalledPacks() async {
    final data = await _request('GET', '/stickers/installed');
    if (data['success'] == true && data['packs'] != null) {
      return (data['packs'] as List).cast<Map<String, dynamic>>();
    }
    return [];
  }

  /// Установить пак
  static Future<Map<String, dynamic>> installPack(int packId) {
    return _request('POST', '/stickers/install', body: {'pack_id': packId});
  }

  /// Удалить пак
  static Future<Map<String, dynamic>> uninstallPack(int packId) {
    return _request('POST', '/stickers/uninstall', body: {'pack_id': packId});
  }

  // ============================================
  // ПОДАРКИ
  // ============================================

  /// Список подарков
  static Future<List<Map<String, dynamic>>> getGifts({String? category, String sort = 'popular'}) async {
    var url = '/gifts/list?sort=$sort';
    if (category != null) url += '&category=$category';
    final data = await _request('GET', url);
    if (data['success'] == true && data['gifts'] != null) {
      return (data['gifts'] as List).cast<Map<String, dynamic>>();
    }
    return [];
  }

  /// Категории подарков
  static Future<List<Map<String, dynamic>>> getGiftCategories() async {
    final data = await _request('GET', '/gifts/categories');
    if (data['success'] == true && data['categories'] != null) {
      return (data['categories'] as List).cast<Map<String, dynamic>>();
    }
    return [];
  }

  /// Отправить подарок
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

  /// Полученные подарки
  static Future<List<Map<String, dynamic>>> getReceivedGifts() async {
    final data = await _request('GET', '/gifts/received');
    if (data['success'] == true && data['gifts'] != null) {
      return (data['gifts'] as List).cast<Map<String, dynamic>>();
    }
    return [];
  }

  /// Отправленные подарки
  static Future<List<Map<String, dynamic>>> getSentGifts() async {
    final data = await _request('GET', '/gifts/sent');
    if (data['success'] == true && data['gifts'] != null) {
      return (data['gifts'] as List).cast<Map<String, dynamic>>();
    }
    return [];
  }

  // ============================================
  // ВСПОМОГАТЕЛЬНЫЙ МЕТОД
  // ============================================
  static Future<void> _saveAuthData(Map<String, dynamic> data) async {
    await AuthService.saveTokens(
      data['access_token']?.toString() ?? '',
      data['refresh_token']?.toString() ?? '',
    );
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