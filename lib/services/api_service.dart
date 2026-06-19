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
    try {
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
        default:
          response = await http.post(uri, headers: headers, body: jsonEncode(body));
      }
    } catch (e) {
      return {'success': false, 'error': 'Ошибка сети: $e'};
    }

    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
      return {'success': false, 'error': 'Неверный формат ответа'};
    } catch (e) {
      return {'success': false, 'error': 'Не удалось разобрать ответ'};
    }
  }

  // ============================================
  // РЕГИСТРАЦИЯ (/register/register)
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

  // ============================================
  // ВХОД ПО ПАРОЛЮ (/login/login)
  // ============================================

  // Вход по паролю (/login/login)
 static Future<Map<String, dynamic>> login({
   required String email,
   required String password,
 }) async {
   final data = await _request('POST', '/login/login', auth: false, body: {
     'type': 'password',
     'identifier': email,
     'password': password,
   });

   if (data['success'] == true && data['access_token'] != null) {
     await _saveAuthData(data);
   }

   return data;  // ✅ Обязательно возвращаем data
 }

  // ============================================
  // ВХОД ПО КОДУ (запрос)
  // ============================================

  static Future<Map<String, dynamic>> loginWithCodeRequest({
    required String identifier,
  }) {
    return _request('POST', '/login/login', auth: false, body: {
      'type': 'code',
      'identifier': identifier,
    });
  }

  // ============================================
  // ВХОД ПО КОДУ (подтверждение)
  // ============================================

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

  // ============================================
  // ВЕРИФИКАЦИЯ EMAIL (/login/verify)
  // ============================================

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

  // ============================================
  // ПОВТОРНАЯ ОТПРАВКА КОДА (/login/resend-code)
  // ============================================

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
  // ВЫХОД
  // ============================================

  static Future<void> logout() async {
    await AuthService.logout();
  }

  // ============================================
  // ПОЛЬЗОВАТЕЛЬ
  // ============================================

  // Получить текущего пользователя
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
     firstName: firstName ?? 'Пользователь',  // ✅ Required параметр
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
  static Future<User?> getUserById(String userId) async {
    final res = await _request('GET', '/user/$userId');
    if (res['success'] == true && res['user'] != null) {
      return User.fromJson(res['user']);
    }
    return null;
  }

  // ============================================
  // ЧАТЫ
  // ============================================

  /// Получить список чатов
  static Future<List<Chat>> getChats() async {
    final res = await _request('GET', '/chats');
    if (res['success'] == true && res['chats'] != null) {
      return (res['chats'] as List)
          .map((c) => Chat.fromJson(c as Map<String, dynamic>))
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
  // СООБЩЕНИЯ
  // ============================================

  /// Получить историю сообщений чата
  static Future<List<Message>> getMessages(String chatId, {int limit = 50}) async {
    final res = await _request('GET', '/messages/$chatId?limit=$limit');
    if (res['success'] == true && res['messages'] != null) {
      return (res['messages'] as List)
          .map((m) => Message.fromJson(m as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  /// Отправить сообщение
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
    if (replyTo != null) {
      body['reply_to'] = replyTo;
    }

    final res = await _request('POST', '/messages/send', body: body);
    if (res['success'] == true && res['message'] != null) {
      return Message.fromJson(res['message']);
    }
    return null;
  }

  /// Пометить сообщение как прочитанное (id - int, как в модели Message)
  static Future<Map<String, dynamic>> markAsRead(int messageId) {
    return _request('PUT', '/messages/$messageId/read');
  }

  /// Редактировать сообщение (id - int)
  static Future<Map<String, dynamic>> editMessage(int messageId, String newContent) {
    return _request('PUT', '/messages/$messageId', body: {
      'content': newContent,
    });
  }

  /// Удалить сообщение (id - int)
  static Future<Map<String, dynamic>> deleteMessage(int messageId, {bool forAll = false}) {
    return _request('DELETE', '/messages/$messageId?for_all=$forAll');
  }

  /// Добавить/убрать реакцию (id - int)
  static Future<Map<String, dynamic>> toggleReaction(int messageId, String emoji) {
    return _request('POST', '/messages/$messageId/react', body: {
      'emoji': emoji,
    });
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