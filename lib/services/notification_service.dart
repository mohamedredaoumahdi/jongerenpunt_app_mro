import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  
  // Initialize notification channels and request permissions
  Future<void> initialize() async {
    // Request notification permissions
    await _fcm.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );
    
    // Configure FCM
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);
    FirebaseMessaging.onBackgroundMessage(_handleBackgroundMessage);
    
    // Initialize local notifications
    const AndroidInitializationSettings androidInitSettings = 
        AndroidInitializationSettings('@mipmap/ic_launcher');
    
    const DarwinInitializationSettings iosInitSettings = 
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    
    const InitializationSettings initSettings = InitializationSettings(
      android: androidInitSettings,
      iOS: iosInitSettings,
    );
    
    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _handleLocalNotificationTap,
    );
    
    // Create notification channels for Android
    await _createAndroidNotificationChannel();
  }
  
  // Subscribe to topics
  Future<void> subscribeToTopic(String topic) async {
    await _fcm.subscribeToTopic(topic);
  }
  
  // Unsubscribe from topics
  Future<void> unsubscribeFromTopic(String topic) async {
    await _fcm.unsubscribeFromTopic(topic);
  }
  
  // Get FCM token
  Future<String?> getToken() async {
    return await _fcm.getToken();
  }
  
  // Handle foreground messages
  void _handleForegroundMessage(RemoteMessage message) {
    _showLocalNotification(message);
  }
  
  // Handle when user taps on notification from terminated state
  void _handleMessageOpenedApp(RemoteMessage message) {
    // Navigate to specific page based on notification data
    // This will be implemented based on app navigation structure
  }
  
  // Handle when user taps on a local notification
  void _handleLocalNotificationTap(NotificationResponse response) {
    // Navigate to specific page based on notification data
    // This will be implemented based on app navigation structure
  }
  
  // Show a local notification
  Future<void> _showLocalNotification(RemoteMessage message) async {
    // Extract notification details from FCM message
    final RemoteNotification? notification = message.notification;
    final AndroidNotification? android = message.notification?.android;
    
    if (notification != null) {
      await _localNotifications.show(
        notification.hashCode,
        notification.title,
        notification.body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            'general_channel',
            'General Notifications',
            channelDescription: 'Channel for general notifications',
            importance: Importance.max,
            priority: Priority.high,
            icon: android?.smallIcon ?? '@mipmap/ic_launcher',
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        payload: message.data.toString(),
      );
    }
  }
  
  // Create Android notification channel
  Future<void> _createAndroidNotificationChannel() async {
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'general_channel',
      'General Notifications',
      description: 'Channel for general notifications',
      importance: Importance.max,
    );
    
    await _localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }
}

// Handle background messages (must be a top-level function)
@pragma('vm:entry-point')
Future<void> _handleBackgroundMessage(RemoteMessage message) async {
  // Minimal processing when app is in background
  print("Background message received: ${message.messageId}");
}