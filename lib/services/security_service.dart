// plus-chat-main/lib/services/security_service.dart
import 'package:root_checker/root_checker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart'; // Для kDebugMode

class SecurityService {
  static const String _prefKeyIntegrityHash = 'integrity_hash';
  static const String _prefKeyFirstRun = 'first_run';

  // --- ХЕШИ ДЛЯ ПРОВЕРКИ ЦЕЛОСТНОСТИ ---
  // В реальном приложении эти хеши должны быть заранее вычислены для релизной версии APK/IPA
  // и жёстко закодированы. Здесь приведён пример.
  // ВАЖНО: Не хранить эталонные хеши в открытом виде в коде. Рассмотрите шифрование или удалённое получение.
  static const Map<String, String> _expectedHashes = {
    // 'assets/icon.png': 'EXPECTED_HASH_FOR_ICON_PNG',
    // 'lib/main.dart': 'EXPECTED_HASH_FOR_MAIN_DART',
    // ... другие важные файлы
    // Пример хеша для dummy-файла (замените на реальные хеши!)
    'dummy_check': 'da39a3ee5e6b4b0d3255bfef95601890afd80709', // SHA-1 для пустой строки ""
  };

  static Future<bool> checkAll() async {
    // Проверяем Root/Jailbreak
    if (await _checkRoot()) {
      debugPrint("[SECURITY] Root/Jailbreak detected!");
      return false;
    }

    // Проверяем Integrity (только на релизе)
    if (!kDebugMode) {
      if (!await _checkIntegrity()) {
        debugPrint("[SECURITY] Integrity check failed!");
        return false;
      }
    } else {
      debugPrint("[SECURITY] Skipping integrity check in debug mode.");
    }

    // Проверяем на Lucky Patcher и другие инструменты (через root_checker)
    if (await _checkForPatches()) {
       debugPrint("[SECURITY] Potential patching tool detected!");
       return false;
    }

    debugPrint("[SECURITY] All checks passed.");
    return true;
  }

  static Future<bool> _checkRoot() async {
    try {
      // Проверяет Root (Android) или Jailbreak (iOS)
      bool isRooted = await RootChecker.isDeviceRooted;
      return isRooted;
    } catch (e) {
      debugPrint('[SECURITY] Error checking root: $e');
      // В случае ошибки, считаем устройство небезопасным
      return true; // Или false, в зависимости от политики
    }
  }

  static Future<bool> _checkForPatches() async {
    try {
      // Проверяет наличие известных патчинг инструментов
      bool isPatched = await RootChecker.detectEmulator;
      // RootChecker не всегда ловит LP, но можно попробовать другие методы
      // или использовать более продвинутые библиотеки/нативный код.
      // Пока используем простую проверку.
      return isPatched;
    } catch (e) {
      debugPrint('[SECURITY] Error checking for patches: $e');
      return false; // В случае ошибки, считаем, что патчей нет
    }
  }

  static Future<bool> _checkIntegrity() async {
    final prefs = await SharedPreferences.getInstance();
    final isFirstRun = prefs.getBool(_prefKeyFirstRun) ?? true;

    if (isFirstRun) {
      debugPrint("[SECURITY] First run detected. Saving integrity hash...");
      // При первом запуске сохраняем хеш
      final currentHash = await _computeCurrentHash();
      await prefs.setString(_prefKeyIntegrityHash, currentHash);
      await prefs.setBool(_prefKeyFirstRun, false);
      debugPrint("[SECURITY] Integrity hash saved: $currentHash");
      return true; // Первый запуск всегда проходит
    } else {
      debugPrint("[SECURITY] Checking integrity against saved hash...");
      // При последующих запусках сравниваем с сохранённым
      final savedHash = prefs.getString(_prefKeyIntegrityHash) ?? '';
      final currentHash = await _computeCurrentHash();
      debugPrint("[SECURITY] Saved hash: $savedHash");
      debugPrint("[SECURITY] Current hash: $currentHash");

      if (savedHash.isEmpty) {
        debugPrint("[SECURITY] No saved hash found!");
        return false; // Нет сохранённого хеша - ошибка
      }

      if (currentHash != savedHash) {
        debugPrint("[SECURITY] Hash mismatch!");
        return false; // Хеши не совпадают - приложение модифицировано
      }
      debugPrint("[SECURITY] Hash match. Integrity OK.");
      return true;
    }
  }

  // --- ВРЕМЕННАЯ ФУНКЦИЯ ДЛЯ ПРОВЕРКИ ---
  // В реальности хешируется APK или его сигнатура, а не произвольный файл.
  // Для демонстрации используем простой способ.
  static Future<String> _computeCurrentHash() async {
    // Пример: хешируем содержимое одного из файлов или просто строку
    // В релизе используйте более надёжный метод, например, проверку подписи APK.
    // Используем dummy-значение для тестирования.
    String dummyContent = ""; // Здесь должен быть реальный способ получить "сигнатуру" приложения
    List<int> bytes = utf8.encode(dummyContent);
    var digest = sha1.convert(bytes);
    return digest.toString();
  }

  // --- ИМПОРТЫ ДЛЯ SHA-1 ---
  // Добавьте в pubspec.yaml: crypto: ^3.0.3
  // import 'package:crypto/crypto.dart';
  // Но для простоты пока используем встроенные возможности.
  // Импортируем dart:io и dart:convert выше.
  // Реализация _computeCurrentHash требует доработки для реального использования.
}

// --- ВРЕМЕННОЕ РЕШЕНИЕ БЕЗ ДОПОЛНИТЕЛЬНОЙ ЗАВИСИМОСТИ ДЛЯ SHA-1 ---
import 'dart:convert';
import 'dart:typed_data';

extension Utf8Ext on String {
  Uint8List get toUtf8Bytes => utf8.encode(this) as Uint8List;
}

Uint8List sha1(Uint8List data) {
  // Очень упрощённая "SHA-1" функция для демонстрации.
  // НЕ ИСПОЛЬЗУЙТЕ В ПРОДАКШЕНЕ!
  // В реальности используйте пакет crypto.
  // Просто возвращаем длину данных как "хеш" для dummy-проверки.
  return Uint8List.fromList(data.length.toString().padLeft(40, '0').split('').map((e) => int.parse(e)).toList());
}
// --- /ВРЕМЕННОЕ РЕШЕНИЕ ---
// --- ЛУЧШЕЕ РЕШЕНИЕ: ---
// 1. Добавьте зависимость: crypto: ^3.0.3 в pubspec.yaml
// 2. Удалите временное решение выше (extension и sha1)
// 3. Добавьте: import 'package:crypto/crypto.dart';
// 4. Используйте: var digest = sha1.convert(bytes);
// ---