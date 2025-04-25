import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/foundation.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  
  // Initialize notification channels and request permissions
  Future<void> initialize() async {
    try {
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
      
      // Configure FCM - wrapped in try-catch to handle potential issues
      try {
        FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
        FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);
      } catch (e) {
        if (kDebugMode) {
          print('Error setting up FCM listeners: $e');
        }
        // Continue initialization even if FCM setup fails
      }
      
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
      
      try {
        await _localNotifications.initialize(
          initSettings,
          onDidReceiveNotificationResponse: _handleLocalNotificationTap,
        );
        
        // Create notification channels for Android
        await _createAndroidNotificationChannel();
      } catch (e) {
        if (kDebugMode) {
          print('Error initializing local notifications: $e');
        }
        // Continue even if local notifications setup fails
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error in notification service initialization: $e');
      }
      // The app should continue to work even if notifications setup fails
    }
  }
  
  // Subscribe to topics with error handling
  Future<void> subscribeToTopic(String topic) async {
    try {
      await _fcm.subscribeToTopic(topic);
    } catch (e) {
      if (kDebugMode) {
        print('Error subscribing to topic $topic: $e');
      }
    }
  }
  
  // Unsubscribe from topics with error handling
  Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await _fcm.unsubscribeFromTopic(topic);
    } catch (e) {
      if (kDebugMode) {
        print('Error unsubscribing from topic $topic: $e');
      }
    }
  }
  
  // Get FCM token with error handling
  Future<String?> getToken() async {
    try {
      return await _fcm.getToken();
    } catch (e) {
      if (kDebugMode) {
        print('Error getting FCM token: $e');
      }
      return null;
    }
  }
  
  // Handle foreground messages
  void _handleForegroundMessage(RemoteMessage message) {
    try {
      _showLocalNotification(message);
    } catch (e) {
      if (kDebugMode) {
        print('Error handling foreground message: $e');
      }
    }
  }
  
  // Handle when user taps on notification from terminated state
  void _handleMessageOpenedApp(RemoteMessage message) {
    // Navigate to specific page based on notification data
    // This will be implemented based on app navigation structure
    if (kDebugMode) {
      print('App opened from notification: ${message.data}');
    }
  }
  
  // Handle when user taps on a local notification
  void _handleLocalNotificationTap(NotificationResponse response) {
    // Navigate to specific page based on notification data
    // This will be implemented based on app navigation structure
    if (kDebugMode) {
      print('Local notification tapped: ${response.payload}');
    }
  }
  
  // Show a local notification
  Future<void> _showLocalNotification(RemoteMessage message) async {
    try {
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
    } catch (e) {
      if (kDebugMode) {
        print('Error showing local notification: $e');
      }
    }
  }
  
  // Create Android notification channel
  Future<void> _createAndroidNotificationChannel() async {
    try {
      const AndroidNotificationChannel channel = AndroidNotificationChannel(
        'general_channel',
        'General Notifications',
        description: 'Channel for general notifications',
        importance: Importance.max,
      );
      
      await _localNotifications
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(channel);
    } catch (e) {
      if (kDebugMode) {
        print('Error creating Android notification channel: $e');
      }
    }
  }
}

// Handle background messages (must be a top-level function)
@pragma('vm:entry-point')
Future<void> _handleBackgroundMessage(RemoteMessage message) async {
  // Minimal processing when app is in background
  print("Background message received: ${message.messageId}");
}