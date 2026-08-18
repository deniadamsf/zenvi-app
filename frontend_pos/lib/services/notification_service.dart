import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    await Firebase.initializeApp();
  } catch (e) {
    debugPrint('Firebase background init error: $e');
  }
  debugPrint('FCM Background message: ${message.messageId} - ${message.notification?.title}');
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _localNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static const String channelId = 'zenvi_channel_high_importance';
  static const String channelName = 'Zenvi Notifications';
  static const String channelDescription = 'Notifikasi instan untuk transaksi, shift, stok, cuti, dan chat.';

  bool _isInitialized = false;
  String? _fcmToken;
  String? get fcmToken => _fcmToken;

  // Global key for navigation from background/foreground clicks
  static GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  // Callback to notify providers (like NotificationProvider) when a new message arrives
  static VoidCallback? onNotificationReceived;

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // 1. Initialize Firebase Core
      await Firebase.initializeApp();
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

      // 2. Initialize Local Notifications Plugin
      const AndroidInitializationSettings androidSettings =
          AndroidInitializationSettings('@mipmap/ic_launcher');
      const InitializationSettings initSettings =
          InitializationSettings(android: androidSettings);

      await _localNotificationsPlugin.initialize(
        initSettings,
        onDidReceiveNotificationResponse: (NotificationResponse response) {
          if (response.payload != null && response.payload!.isNotEmpty) {
            try {
              final data = jsonDecode(response.payload!);
              _handleNotificationNavigation(data);
            } catch (e) {
              debugPrint('Error parsing notification payload: $e');
            }
          }
        },
      );

      // 3. Create Android High Importance Notification Channel
      if (!kIsWeb && Platform.isAndroid) {
        final AndroidNotificationChannel channel = const AndroidNotificationChannel(
          channelId,
          channelName,
          description: channelDescription,
          importance: Importance.max,
          enableVibration: true,
          playSound: true,
        );

        await _localNotificationsPlugin
            .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin>()
            ?.createNotificationChannel(channel);
      }

      // 4. Request FCM Permissions
      final NotificationSettings settings =
          await FirebaseMessaging.instance.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      debugPrint('FCM Authorization status: ${settings.authorizationStatus}');

      // 5. Get and cache FCM Token
      try {
        _fcmToken = await FirebaseMessaging.instance.getToken();
        debugPrint('FCM Device Token: $_fcmToken');
      } catch (e) {
        debugPrint('Failed to get FCM Token: $e');
      }

      // Listen for Token Refreshes
      FirebaseMessaging.instance.onTokenRefresh.listen((newToken) {
        _fcmToken = newToken;
        syncTokenWithBackend();
      });

      // 6. Foreground FCM Message Handling
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        debugPrint('FCM Foreground message: ${message.notification?.title} - ${message.notification?.body}');
        
        // Notify active provider/screens to update badge
        if (onNotificationReceived != null) {
          onNotificationReceived!();
        }

        // Show local banner when app is in foreground
        final RemoteNotification? notification = message.notification;
        if (notification != null) {
          showLocalNotification(
            id: message.hashCode,
            title: notification.title ?? 'Zenvi POS',
            body: notification.body ?? '',
            payload: jsonEncode(message.data),
          );
        }
      });

      // 7. Background to Foreground Click Handling
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        debugPrint('FCM Notification opened from background: ${message.data}');
        _handleNotificationNavigation(message.data);
      });

      // 8. Terminated App Click Handling
      final RemoteMessage? initialMessage =
          await FirebaseMessaging.instance.getInitialMessage();
      if (initialMessage != null) {
        debugPrint('FCM App opened from terminated state: ${initialMessage.data}');
        Future.delayed(const Duration(milliseconds: 800), () {
          _handleNotificationNavigation(initialMessage.data);
        });
      }

      _isInitialized = true;
    } catch (e) {
      debugPrint('NotificationService initialization error: $e');
    }
  }

  /// Show local heads-up notification banner
  Future<void> showLocalNotification({
    int id = 0,
    required String title,
    required String body,
    String? payload,
  }) async {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      channelId,
      channelName,
      channelDescription: channelDescription,
      importance: Importance.max,
      priority: Priority.high,
      showWhen: true,
      enableVibration: true,
      playSound: true,
      icon: '@mipmap/ic_launcher',
      largeIcon: DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
      color: Color(0xFF00796B),
    );

    const NotificationDetails platformDetails =
        NotificationDetails(android: androidDetails);

    await _localNotificationsPlugin.show(
      id,
      title,
      body,
      platformDetails,
      payload: payload,
    );
  }

  /// Sync device FCM token with backend API
  Future<void> syncTokenWithBackend() async {
    if (_fcmToken == null || _fcmToken!.isEmpty) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final String? token = prefs.getString('auth_token');
      final String baseUrl = prefs.getString('api_base_url') ?? ApiConfig.baseUrl;

      if (token == null || token.isEmpty) return;

      final url = Uri.parse('$baseUrl/user/fcm-token');
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'fcm_token': _fcmToken,
          'platform': kIsWeb ? 'web' : (Platform.isAndroid ? 'android' : (Platform.isIOS ? 'ios' : 'desktop')),
          'device_name': 'Zenvi POS Client',
        }),
      );

      if (response.statusCode == 200) {
        debugPrint('FCM Token synced successfully with backend.');
      } else {
        debugPrint('FCM Token sync failed: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      debugPrint('Error syncing FCM token with backend: $e');
    }
  }

  /// Remove device token on logout
  Future<void> unregisterTokenOnLogout() async {
    if (_fcmToken == null || _fcmToken!.isEmpty) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final String? token = prefs.getString('auth_token');
      final String baseUrl = prefs.getString('api_base_url') ?? ApiConfig.baseUrl;

      if (token == null || token.isEmpty) return;

      final url = Uri.parse('$baseUrl/user/fcm-token/remove');
      await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'fcm_token': _fcmToken,
        }),
      );
    } catch (e) {
      debugPrint('Error removing FCM token on logout: $e');
    }
  }

  /// Handle navigation routing when tapping a notification
  static void _handleNotificationNavigation(Map<String, dynamic> data) {
    final BuildContext? context = navigatorKey.currentContext;
    if (context == null) return;

    final String? type = data['type']?.toString();
    final String? route = data['route']?.toString();

    debugPrint('Handling notification tap: type=$type, route=$route, payload=$data');

    // Routing decisions based on notification type / route
    if (route == '/chat' || type?.startsWith('chat') == true) {
      Navigator.of(context).pushNamed('/chat');
    } else if (route == '/shifts' || type?.startsWith('shift') == true) {
      Navigator.of(context).pushNamed('/shifts');
    } else if (route == '/stock' || type == 'low_stock') {
      Navigator.of(context).pushNamed('/stock');
    } else if (route == '/permissions' || type?.startsWith('permission') == true) {
      Navigator.of(context).pushNamed('/permissions');
    } else if (route == '/reservations' || type?.startsWith('reservation') == true) {
      Navigator.of(context).pushNamed('/reservations');
    } else {
      // Default open Notification Center
      Navigator.of(context).pushNamed('/notifications');
    }
  }
}
