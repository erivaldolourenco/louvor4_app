import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:dio/dio.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../network/api_client.dart';
import '../storage/token_storage.dart';
import '../ui/app_feedback.dart';

class PushNotificationService {
  PushNotificationService._();

  static final PushNotificationService instance = PushNotificationService._();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  final TokenStorage _tokenStorage = TokenStorage();
  StreamSubscription<String>? _tokenRefreshSubscription;
  bool _isInitialized = false;
  bool _isLocalNotificationsInitialized = false;

  static const String _androidChannelId = 'louvor4_default_channel';
  static const String _androidChannelName = 'Notificacoes';
  static const String _androidChannelDescription =
      'Canal padrao de notificacoes do Louvor4';

  Future<void> initialize() async {
    if (_isInitialized || kIsWeb) return;
    _isInitialized = true;

    try {
      await _initializeLocalNotifications();

      await _messaging.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );

      final settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      if (settings.authorizationStatus == AuthorizationStatus.denied) {
        if (kDebugMode) {
          print('Permissão de notificação negada.');
        }
        return;
      }

      await _registerCurrentDeviceToken();

      _tokenRefreshSubscription ??= _messaging.onTokenRefresh.listen((
        token,
      ) async {
        await _registerDeviceToken(token);
      });

      FirebaseMessaging.onMessage.listen((message) {
        unawaited(_showForegroundNotification(message));

        if (kDebugMode) {
          print('Push foreground recebida: ${message.messageId}');
          print('Título: ${message.notification?.title}');
          print('Body: ${message.notification?.body}');
          print('Data: ${message.data}');
        }
      });
    } catch (e) {
      if (kDebugMode) {
        print('Falha ao inicializar notificações: $e');
      }
    }
  }

  Future<void> _initializeLocalNotifications() async {
    if (_isLocalNotificationsInitialized) return;

    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );

    const settings = InitializationSettings(android: androidSettings);

    await _localNotifications.initialize(settings);

    if (Platform.isAndroid) {
      final androidImplementation = _localNotifications
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();

      await androidImplementation?.requestNotificationsPermission();
      await androidImplementation?.createNotificationChannel(
        const AndroidNotificationChannel(
          _androidChannelId,
          _androidChannelName,
          description: _androidChannelDescription,
          importance: Importance.high,
        ),
      );
    }

    _isLocalNotificationsInitialized = true;
  }

  Future<void> _showForegroundNotification(RemoteMessage message) async {
    if (!_isLocalNotificationsInitialized || !Platform.isAndroid) return;

    final title =
        message.notification?.title ?? message.data['title']?.toString();
    final body = message.notification?.body ?? message.data['body']?.toString();

    if ((title == null || title.isEmpty) && (body == null || body.isEmpty)) {
      return;
    }

    final details = const NotificationDetails(
      android: AndroidNotificationDetails(
        _androidChannelId,
        _androidChannelName,
        channelDescription: _androidChannelDescription,
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
      ),
    );

    final id =
        message.messageId?.hashCode ??
        DateTime.now().millisecondsSinceEpoch ~/ 1000;
    await _localNotifications.show(
      id,
      title ?? 'Louvor4',
      body ?? '',
      details,
      payload: message.data.isEmpty ? null : message.data.toString(),
    );
  }

  Future<void> syncTokenNow() async {
    if (kIsWeb) return;
    await _registerCurrentDeviceToken();
  }

  Future<void> _registerCurrentDeviceToken() async {
    final token = await _messaging.getToken();
    if (token == null || token.isEmpty) return;
    await _registerDeviceToken(token);
  }

  Future<void> _registerDeviceToken(String token) async {
    const registerPath = String.fromEnvironment(
      'DEVICE_REGISTER_PATH',
      defaultValue: '/notifications/device-register',
    );
    final deviceId = await _getOrCreateDeviceId();

    try {
      await ApiClient.dio.post(
        registerPath,
        data: {'fcmToken': token, 'platform': _platform, 'deviceId': deviceId},
      );

      if (kDebugMode) {
        AppFeedback.showSuccess('Dispositivo registrado para notificações.');
        print('Device token registrado com sucesso em $registerPath');
      }
    } on DioException catch (e) {
      final message = _extractApiErrorMessage(e);
      AppFeedback.showError(message);

      if (kDebugMode) {
        print(
          'Falha ao registrar device token: '
          '${e.response?.statusCode} $message',
        );
      }
    }
  }

  Future<String> _getOrCreateDeviceId() async {
    final existing = await _tokenStorage.getDeviceId();
    if (existing != null && existing.isNotEmpty) return existing;

    final random = Random.secure();
    final buffer = StringBuffer('and-');
    for (var i = 0; i < 16; i++) {
      buffer.write(random.nextInt(16).toRadixString(16));
    }

    final generated = buffer.toString();
    await _tokenStorage.saveDeviceId(generated);
    return generated;
  }

  String _extractApiErrorMessage(DioException e) {
    final data = e.response?.data;
    if (data is Map<String, dynamic>) {
      final msg =
          data['message'] ?? data['error'] ?? data['detail'] ?? data['title'];
      if (msg != null && msg.toString().trim().isNotEmpty) {
        return msg.toString();
      }
    }
    if (data is String && data.trim().isNotEmpty) return data;
    return 'Falha ao registrar dispositivo para notificações.';
  }

  String get _platform {
    if (kIsWeb) return 'WEB';
    if (Platform.isAndroid) return 'ANDROID';
    if (Platform.isIOS) return 'IOS';
    return 'UNKNOWN';
  }
}
