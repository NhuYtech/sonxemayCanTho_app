import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  static Future<void> initialize() async {
    // Khởi tạo local notifications
    const initializationSettingsAndroid = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const initializationSettingsIOS = DarwinInitializationSettings();
    const initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await _notifications.initialize(initializationSettings);

    // Cấu hình FCM
    await _messaging.requestPermission(alert: true, badge: true, sound: true);

    // Xử lý tin nhắn khi app ở foreground
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Xử lý tin nhắn khi app ở background
    FirebaseMessaging.onBackgroundMessage(_handleBackgroundMessage);
  }

  // Xử lý tin nhắn khi app đang chạy
  static Future<void> _handleForegroundMessage(RemoteMessage message) async {
    _showLocalNotification(
      title: message.notification?.title ?? 'Tin nhắn mới',
      body: message.notification?.body ?? '',
      payload: message.data['type'],
    );

    // Cập nhật badge
    _updateBadge();
  }

  // Xử lý tin nhắn khi app ở background
  static Future<void> _handleBackgroundMessage(RemoteMessage message) async {
    // Cập nhật badge và hiển thị notification
    await _showLocalNotification(
      title: message.notification?.title ?? 'Tin nhắn mới',
      body: message.notification?.body ?? '',
      payload: message.data['type'],
    );
  }

  // Hiển thị local notification
  static Future<void> _showLocalNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'messages_channel',
      'Messages',
      channelDescription: 'Notifications for new messages',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(
      DateTime.now().millisecond,
      title,
      body,
      details,
      payload: payload,
    );
  }

  // Cập nhật badge số tin nhắn chưa đọc
  static Future<void> _updateBadge() async {
    // Đọc số tin nhắn chưa đọc từ Firestore
    // Cập nhật badge trên icon app
    // Implement logic đọc unreadCount ở đây
  }

  // Xóa badge khi đã đọc hết tin nhắn
  static Future<void> clearBadge() async {
    await _notifications.clearAll();
  }
}

extension on FlutterLocalNotificationsPlugin {
  Future<void> clearAll() async {}
}
