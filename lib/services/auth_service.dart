// lib/services/auth_service.dart
// --- ДОБАВЛЕНО: импорт User ---
import '../models/user.dart';
// --- /ДОБАВЛЕНО ---
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  static const String _tokenKey = 'access_token';
  static const String _refreshTokenKey = 'refresh_token';

  // --- ДОБАВЛЕНО: метод getCurrentUser ---
  static User? _currentUser; // Приватное поле для хранения текущего пользователя

  static User? getCurrentUser() {
    return _currentUser;
  }

  static void setCurrentUser(User? user) {
    _currentUser = user;
  }
  // --- /ДОБАВЛЕНО ---

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

  // Предполагаем, что refresh токен возвращает и access, и refresh
  static Future<bool> refreshToken() async {
    // Реализуйте логику обновления токена через API
    // ...
    // В случае успеха: await saveTokens(newAccessToken, newRefreshToken);
    // Также обновите _currentUser, если данные пользователя пришли с refresh
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
}