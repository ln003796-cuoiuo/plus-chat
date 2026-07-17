// lib/services/auth_service.dart
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart'; // Импортируем User

class AuthService {
  static const String _tokenKey = 'access_token';
  static const String _refreshTokenKey = 'refresh_token';

  // --- ХРАНЕНИЕ ТЕКУЩЕГО ПОЛЬЗОВАТЕЛЯ ---
  static User? _currentUser;
  // --- /ХРАНЕНИЕ ---

  // --- МЕТОДЫ ---
  static Future<bool> isAuthenticated() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_tokenKey);
    return token != null && token.isNotEmpty;
  }

  static Future<String?> getAccessToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  static Future<String?> getRefreshToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_refreshTokenKey);
  }

  static Future<bool> refreshToken() async {
    // Реализуйте логику обновления токена через API
    // ...
    // В случае успеха: await saveTokens(newAccessToken, newRefreshToken);
    // Также обновите _currentUser, если данные пользователя пришли с refresh
    // setCurrentUser(...);
    return false; // Пока возвращаем false
  }

  static Future<void> saveTokens(String accessToken, String refreshToken) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, accessToken);
    await prefs.setString(_refreshTokenKey, refreshToken);
  }

  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_refreshTokenKey);
    setCurrentUser(null); // Сбросить состояние пользователя
  }

  // --- ДОБАВЛЕНО: метод getCurrentUser ---
  static User? getCurrentUser() {
    return _currentUser;
  }

  static void setCurrentUser(User? user) {
    _currentUser = user;
  }
  // --- /ДОБАВЛЕНО ---
  // --- /МЕТОДЫ ---
}