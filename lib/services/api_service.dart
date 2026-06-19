import 'dart:convert';
import 'package:http/http.dart' as http;
import 'auth_service.dart';
import '../models/user.dart';

class ApiService {
  // ✅ НОВАЯ СТРУКТУРА СЕРВЕРА - без /api, напрямую к папкам
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
      return jsonDecode(response.body) as Map<String, dynamic>;
    } catch (e) {
      return {'success': false, 'error': 'Неверный ответ сервера'};
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
  // ВХОД (/login/login)
  // ============================================

  /// Вход по паролю
  static Future<Map<String, dynamic>> loginWithPassword({
    required String identifier,
    required String password,
  }) async {
    final data = await _request('POST', '/login/login', auth: false, body: {
      'type': 'password',
      'identifier': identifier,
      'password': password,
    });

    if (data['success'] == true && data['access_token'] != null) {
      await AuthService.saveTokens(
        data['access_token'],
        data['refresh_token'],
      );
      if (data['user'] != null && data['user']['id'] != null) {
        await AuthService.saveUserId(data['user']['id']);
      }
    }

    return data;
  }

  /// Запрос кода для входа (без code)
  static Future<Map<String, dynamic>> loginWithCodeRequest({
    required String identifier,
  }) {
    return _request('POST', '/login/login', auth: false, body: {
      'type': 'code',
      'identifier': identifier,
    });
  }

  /// Вход по коду (с code)
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
      await AuthService.saveTokens(
        data['access_token'],
        data['refresh_token'],
      );
      if (data['user'] != null && data['user']['id'] != null) {
        await AuthService.saveUserId(data['user']['id']);
      }
    }

    return data;
  }

  // ============================================
  // ВЕРИФИКАЦИЯ (/login/verify)
  // ============================================

  static Future<Map<String, dynamic>> verifyCode({
    required String email,
    required String code,
  }) async {
    final data = await _request('POST', '/login/verify', auth: false, body: {
      'email': email,
      'code': code,
    });

    if (data['success'] == true && data['access_token'] != null) {
      await AuthService.saveTokens(
        data['access_token'],
        data['refresh_token'],
      );
      if (data['user'] != null && data['user']['id'] != null) {
        await AuthService.saveUserId(data['user']['id']);
      }
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
  // ПОЛЬЗОВАТЕЛЬ
  // ============================================

  /// Получить текущего пользователя
  static Future<User?> getMe() async {
    // TODO: Добавить endpoint /user/me на сервере
    // Пока возвращаем данные из AuthService
    final userId = await AuthService.getUserId();
    if (userId == null) return null;
    
    // Временное решение - возвращаем базового пользователя
    return User(
      id: userId,
      email: '',
      username: 'user',
      firstName: 'Пользователь',
      lastName: '',
    );
  }
}