import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:open_file/open_file.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UpdateInfo {
  final bool needsUpdate;
  final bool forceUpdate;
  final String currentVersion;
  final int currentBuild;
  final String latestVersion;
  final int latestBuild;
  final String downloadUrl;
  final String changelog;
  final String? releaseDate;

  UpdateInfo({
    required this.needsUpdate,
    required this.forceUpdate,
    required this.currentVersion,
    required this.currentBuild,
    required this.latestVersion,
    required this.latestBuild,
    required this.downloadUrl,
    required this.changelog,
    this.releaseDate,
  });

  factory UpdateInfo.fromJson(Map<String, dynamic> json) {
    return UpdateInfo(
      needsUpdate: json['needs_update'] ?? false,
      forceUpdate: json['force_update'] ?? false,
      currentVersion: json['current_version'] ?? '0.0.0',
      currentBuild: json['current_build'] ?? 0,
      latestVersion: json['latest_version'] ?? '0.0.0',
      latestBuild: json['latest_build'] ?? 0,
      downloadUrl: json['download_url'] ?? '',
      changelog: json['changelog'] ?? '',
      releaseDate: json['release_date'],
    );
  }
}

class UpdateService {
  static const String _checkUrl = 'https://xn--80avljg2a1c.xn--p1ai/api/update/check';
  static const String _lastCheckKey = 'last_update_check';
  static const int _checkIntervalHours = 24;

  static Future<UpdateInfo?> checkForUpdate() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final buildNumber = int.tryParse(packageInfo.buildNumber) ?? 1;

      final response = await http.get(
        Uri.parse('$_checkUrl?build=$buildNumber&version=${packageInfo.version}'),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['data'] != null) {
          return UpdateInfo.fromJson(data['data']);
        }
      }
    } catch (e) {
      print('Ошибка проверки обновления: $e');
    }
    return null;
  }

  static Future<bool> shouldCheck() async {
    final prefs = await SharedPreferences.getInstance();
    final lastCheck = prefs.getInt(_lastCheckKey) ?? 0;
    final now = DateTime.now().millisecondsSinceEpoch;
    final hoursPassed = (now - lastCheck) / (1000 * 60 * 60);
    return hoursPassed >= _checkIntervalHours;
  }

  static Future<void> markChecked() async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now().millisecondsSinceEpoch;
    await prefs.setInt(_lastCheckKey, now);
  }

  static Future<String?> downloadApk(String url, Function(double)? onProgress) async {
    try {
      if (await Permission.requestInstallPackages.isDenied) {
        final status = await Permission.requestInstallPackages.request();
        if (!status.isGranted) {
          return null;
        }
      }

      if (await Permission.storage.isDenied) {
        await Permission.storage.request();
      }

      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/pluschat_update.apk');

      final response = await http.Client().send(
        http.Request('GET', Uri.parse(url)),
      );

      final totalBytes = response.contentLength ?? 0;
      int receivedBytes = 0;

      final sink = file.openWrite();

      await response.stream.listen(
        (chunk) {
          sink.add(chunk);
          receivedBytes += chunk.length;
          if (totalBytes > 0 && onProgress != null) {
            onProgress(receivedBytes / totalBytes);
          }
        },
        onDone: () async {
          await sink.flush();
          await sink.close();
        },
        onError: (e) {
          sink.close();
          throw e;
        },
      ).asFuture();

      return file.path;
    } catch (e) {
      print('Ошибка скачивания APK: $e');
      return null;
    }
  }

  static Future<void> installApk(String path) async {
    await OpenFile.open(path);
  }

  static void showUpdateDialog(BuildContext context, UpdateInfo info) {
    showDialog(
      context: context,
      barrierDismissible: !info.forceUpdate,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.system_update, color: Theme.of(context).primaryColor),
            const SizedBox(width: 8),
            const Text('Доступно обновление'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Версия ${info.latestVersion} (build ${info.latestBuild})'),
            const SizedBox(height: 12),
            const Text('Что нового:', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(info.changelog),
            if (info.forceUpdate) ...[
              const SizedBox(height: 12),
              const Text(
                'Это обновление обязательно для продолжения работы',
                style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
              ),
            ],
          ],
        ),
        actions: [
          if (!info.forceUpdate)
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Позже'),
            ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await _downloadAndInstall(context, info.downloadUrl);
            },
            child: const Text('Обновить'),
          ),
        ],
      ),
    );
  }

  static Future<void> _downloadAndInstall(BuildContext context, String url) async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) {
          double progress = 0;
          Future.delayed(Duration.zero, () async {
            final path = await downloadApk(url, (p) {
              setState(() => progress = p);
            });
            if (path != null && context.mounted) {
              Navigator.pop(ctx);
              await installApk(path);
            } else if (context.mounted) {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Ошибка скачивания')),
              );
            }
          });
          return AlertDialog(
            title: const Text('Скачивание обновления'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                LinearProgressIndicator(value: progress),
                const SizedBox(height: 8),
                Text('${(progress * 100).toInt()}%'),
              ],
            ),
          );
        },
      ),
    );
  }
}