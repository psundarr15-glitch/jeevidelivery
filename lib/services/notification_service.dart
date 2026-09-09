import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';
import 'api_client.dart';

/// Same shape as the customer app's NotificationService, scoped to what
/// partners actually need: "a new order just came in" pushes (see
/// PushNotificationService::sendToAvailablePartners on the backend).
/// Tapping one opens that order's detail screen directly.
class NotificationService {
  static final _messaging = FirebaseMessaging.instance;
  static final _localNotifications = FlutterLocalNotificationsPlugin();

  static const _channelId = 'new_orders';
  static const _channelName = 'New order requests';
  static const _prefsKey = 'push_notifications_enabled';

  /// Whether the Settings screen's toggle is on. Defaults to on.
  static Future<bool> isEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_prefsKey) ?? true;
  }

  /// Turning this off both stops local foreground banners (see
  /// _showForegroundNotification) AND deletes the FCM token — so the
  /// backend's device_tokens lookup no longer includes this device at
  /// all, meaning it stops actually being sent pushes, not just
  /// silencing ones that still arrive. Turning back on gets a fresh
  /// token and re-registers it.
  static Future<void> setEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefsKey, enabled);
    if (enabled) {
      final token = await _messaging.getToken();
      if (token != null) await _registerToken(token);
    } else {
      final token = await _messaging.getToken();
      if (token != null) {
        try {
          await ApiClient.post(ApiConfig.unregisterDeviceToken, {'fcm_token': token});
        } catch (_) {
          // Best-effort — worst case the server still has a stale
          // token and this device just won't show the push locally.
        }
      }
      await _messaging.deleteToken();
    }
  }

  static Future<void> init({required GlobalKey<NavigatorState> navigatorKey}) async {
    await _messaging.requestPermission(alert: true, badge: true, sound: true);

    await _localNotifications.initialize(
      const InitializationSettings(android: AndroidInitializationSettings('@drawable/ic_stat_notify')),
      onDidReceiveNotificationResponse: (response) {
        final orderId = response.payload;
        final nav = navigatorKey.currentState;
        if (nav != null && orderId != null && orderId.isNotEmpty) {
          nav.pushNamed('/order-detail', arguments: int.tryParse(orderId));
        }
      },
    );
    await _localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(const AndroidNotificationChannel(
          _channelId,
          _channelName,
          description: 'Broadcast when a new delivery is available nearby',
          importance: Importance.high,
        ));

    if (await isEnabled()) {
      final token = await _messaging.getToken();
      if (token != null) await _registerToken(token);
    }
    _messaging.onTokenRefresh.listen((token) async {
      if (await isEnabled()) await _registerToken(token);
    });

    FirebaseMessaging.onMessage.listen(_showForegroundNotification);
    FirebaseMessaging.onMessageOpenedApp.listen((message) => _handleTap(message, navigatorKey));

    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) _handleTap(initialMessage, navigatorKey);
  }

  /// Call again right after login, in case there was no auth token yet
  /// when init() ran (app started logged out).
  static Future<void> registerCurrentToken() async {
    if (!await isEnabled()) return;
    final token = await _messaging.getToken();
    if (token != null) await _registerToken(token);
  }

  static Future<void> _registerToken(String token) async {
    try {
      await ApiClient.post(ApiConfig.deviceToken, {'fcm_token': token, 'platform': 'android'});
    } catch (_) {
      // Not logged in yet, or a transient network error - will retry on next launch/refresh.
    }
  }

  static Future<void> _showForegroundNotification(RemoteMessage message) async {
    if (!await isEnabled()) return;
    final title = message.notification?.title ?? 'New order available!';
    final body = message.notification?.body ?? '';
    final orderId = message.data['order_id'];

    await _localNotifications.show(
      message.hashCode,
      title,
      body,
      const NotificationDetails(
        android: AndroidNotificationDetails(_channelId, _channelName, importance: Importance.high, priority: Priority.high),
      ),
      payload: orderId?.toString(),
    );
  }

  static void _handleTap(RemoteMessage message, GlobalKey<NavigatorState> navigatorKey) {
    final orderId = message.data['order_id'];
    final nav = navigatorKey.currentState;
    if (nav == null || orderId == null) return;
    nav.pushNamed('/order-detail', arguments: int.tryParse(orderId.toString()));
  }
}
