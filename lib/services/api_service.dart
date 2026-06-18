import 'dart:convert';
import 'package:http/http.dart' as http;
import 'auth_service.dart';
import '../models/user.dart';
import '../models/chat.dart';
import '../models/message.dart';

class ApiService {
  // ⚠️ ЗАМЕНИ на свой домен!
  static const String baseUrl = 'https://твой-сайт.ru/api';

  /// Базовый метод для всех HTTP-запросов
  static Future<Map<String, dynamic>> _request(
    String method,
    String endpoint, {
    Map<String, dynamic>? body,
    bool auth = true,
  }) async {
    final uri = Uri.parse('$baseUrl$endpoint');
    final headers = <String, String>{
      'Content-Type': 'application/json',
    };

    if (auth) {
      final token = await AuthService.getToken();
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }
    }

    http.Response response;
    switch (method) {
      case 'GET':
        response = await http.get(uri, headers: headers);
        break;
      case 'PUT':
        response = await http.put(uri, headers: headers, body: jsonEncode(body));
        break;
      case 'DELETE':
        response = await http.delete(uri, headers: headers);
        break;
      default: // POST
        response = await http.post(uri, headers: headers, body: jsonEncode(body));
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;

    // Если токен истёк, пробуем обновить
    if (response.statusCode == 401 && auth) {
      final refreshed = await _refreshToken();
      if (refreshed) {
        return _request(method, endpoint, body: body, auth: auth);
      }
    }

    return data;
  }

  /// Обновление access token через refresh token
  static Future<bool> _refreshToken() async {
    final refreshToken = await AuthService.getRefreshToken();
    if (refreshToken == null) return false;

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/refresh'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'refresh_token': refreshToken}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        await AuthService.saveTokens(data['access_token'], refreshToken);
        return true;
      }
    } catch (_) {}
    return false;
  }

  // ============================================
  // AUTH
  // ============================================

  static Future<Map<String, dynamic>> register({
    required String email,
    required String password,
    required String firstName,
  }) {
    return _request('POST', '/auth/register', auth: false, body: {
      'email': email,
      'password': password,
      'first_name': firstName,
    });
  }

  static Future<Map<String, dynamic>> verifyEmail({
    required String email,
    required String code,
  }) {
    return _request('POST', '/auth/verify-email', auth: false, body: {
      'email': email,
      'code': code,
    });
  }

  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) {
    return _request('POST', '/auth/login', auth: false, body: {
      'email': email,
      'password': password,
    });
  }

  static Future<Map<String, dynamic>> logout() {
    return _request('POST', '/auth/logout');
  }

  // ============================================
  // USER
  // ============================================

  /// Получить текущего пользователя
  static Future<User?> getMe() async {
    final res = await _request('GET', '/user/me');
    if (res['success'] == true && res['user'] != null) {
      return User.fromJson(res['user']);
    }
    return null;
  }

  /// Первоначальная настройка профиля
  static Future<Map<String, dynamic>> setupProfile({
    required String username,
    required String firstName,
    String? lastName,
  }) {
    return _request('PUT', '/user/setup', body: {
      'username': username,
      'first_name': firstName,
      'last_name': lastName,
    });
  }

  /// Проверка доступности username
  static Future<Map<String, dynamic>> checkUsername(String username) {
    return _request('GET', '/user/check-username?username=$username', auth: false);
  }

  /// Получить профиль другого пользователя
  static Future<User?> getUserById(String userId) async {
    final res = await _request('GET', '/user/$userId');
    if (res['success'] == true && res['user'] != null) {
      return User.fromJson(res['user']);
    }
    return null;
  }

  /// Обновить настройки пользователя
  static Future<Map<String, dynamic>> updateSettings(Map<String, dynamic> settings) {
    return _request('PUT', '/user/settings', body: settings);
  }

  // ============================================
  // CHATS
  // ============================================

  /// Получить список чатов
  static Future<List<Chat>> getChats() async {
    final res = await _request('GET', '/chats');
    if (res['success'] == true && res['chats'] != null) {
      return (res['chats'] as List)
          .map((c) => Chat.fromJson(c))
          .toList();
    }
    return [];
  }

  /// Создать новый чат
  static Future<Map<String, dynamic>> createChat({
    required String type,
    required List<String> members,
    String? title,
  }) {
    return _request('POST', '/chats/create', body: {
      'type': type,
      'members': members,
      'title': title,
    });
  }

  /// Получить информацию о чате
  static Future<Chat?> getChatById(String chatId) async {
    final res = await _request('GET', '/chats/$chatId');
    if (res['success'] == true && res['chat'] != null) {
      return Chat.fromJson(res['chat']);
    }
    return null;
  }

  // ============================================
  // MESSAGES
  // ============================================

  /// Получить историю сообщений чата
  static Future<List<Message>> getMessages(String chatId, {int limit = 50}) async {
    final res = await _request('GET', '/messages/$chatId?limit=$limit');
    if (res['success'] == true && res['messages'] != null) {
      return (res['messages'] as List)
          .map((m) => Message.fromJson(m))
          .toList();
    }
    return [];
  }

  /// Отправить сообщение
  static Future<Message?> sendMessage({
    required String chatId,
    required String content,
    String type = 'text',
    String? replyTo,  // ← ИСПРАВЛЕНО: было int?
  }) async {
    final body = {
      'chat_id': chatId,
      'content': content,
      'type': type,
    };
    if (replyTo != null) body['reply_to'] = replyTo;  // ← Теперь работает!
    
    final res = await _request('POST', '/messages/send', body: body);
    if (res['success'] == true && res['message'] != null) {
      return Message.fromJson(res['message']);
    }
    return null;
  }

  /// Пометить сообщение как прочитанное
  static Future<Map<String, dynamic>> markAsRead(int messageId) {
    return _request('PUT', '/messages/$messageId/read');
  }

  /// Редактировать сообщение
  static Future<Map<String, dynamic>> editMessage(int messageId, String newContent) {
    return _request('PUT', '/messages/$messageId', body: {
      'content': newContent,
    });
  }

  /// Удалить сообщение
  static Future<Map<String, dynamic>> deleteMessage(int messageId, {bool forAll = false}) {
    return _request('DELETE', '/messages/$messageId?for_all=$forAll');
  }

  /// Добавить/убрать реакцию
  static Future<Map<String, dynamic>> toggleReaction(int messageId, String emoji) {
    return _request('POST', '/messages/$messageId/react', body: {
      'emoji': emoji,
    });
  }
}