import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_desktop_notifications/flutter_desktop_notifications.dart';

import 'app_logger.dart';

/// 系统通知服务：Android 走原生 MethodChannel，Windows 走 toast。
class NotificationService {
  NotificationService._();

  static final NotificationService instance = NotificationService._();

  static const _aumid = 'TokenKakeibo.TokenKakeibo';
  static const _androidChannel = MethodChannel('token_kakeibo/notifications');

  final WindowsNotification _notifier = WindowsNotification(
    applicationId: _aumid,
  );
  bool _initialized = false;
  bool _androidInitialized = false;

  /// 初始化通知客户端（应用启动时调用一次）。
  Future<void> init() async {
    if (Platform.isAndroid) {
      await _initAndroid();
      return;
    }
    if (_initialized) return;
    try {
      await WindowsNotification.registerAumid(
        aumid: _aumid,
        displayName: 'Token家计薄',
      );
      await _notifier.init();
      _initialized = true;
      AppLogger.i('notification service initialized (aumid=$_aumid)');
    } catch (e) {
      AppLogger.w('notification init failed: $e');
    }
  }

  Future<void> _initAndroid() async {
    if (_androidInitialized) return;
    try {
      await _androidChannel.invokeMethod<void>('init');
      _androidInitialized = true;
      AppLogger.i('android notification service initialized');
    } catch (e) {
      AppLogger.w('android notification init failed: $e');
    }
  }

  /// 发送系统通知。
  Future<void> show({
    required String title,
    required String body,
    String? urgency,
  }) async {
    if (Platform.isAndroid) {
      await _showAndroid(title: title, body: body);
      return;
    }
    if (!_initialized) {
      await init();
    }
    try {
      await _notifier.showNotificationPluginTemplate(
        NotificationMessage.fromPluginTemplate(
          'token_kakeibo_${DateTime.now().millisecondsSinceEpoch}',
          title,
          body,
        ),
      );
      AppLogger.i('notification sent: $title');
    } catch (e) {
      AppLogger.w('notification show failed: $e');
    }
  }

  Future<void> _showAndroid({
    required String title,
    required String body,
  }) async {
    if (!_androidInitialized) {
      await _initAndroid();
    }
    try {
      await _androidChannel.invokeMethod<void>('requestPermission');
      await _androidChannel.invokeMethod<void>('show', {
        'title': title,
        'body': body,
      });
      AppLogger.i('android notification sent: $title');
    } catch (e) {
      AppLogger.w('android notification show failed: $e');
    }
  }
}
