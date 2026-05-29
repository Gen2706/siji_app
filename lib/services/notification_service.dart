import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart';
import 'api_service.dart';
import '../screens/ticket_detail_screen.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try { await Firebase.initializeApp(); } catch (e) {}
}

// Global navigator key untuk navigasi dari notifikasi
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

class NotificationService {
  static bool _initialized = false;
  static final _notifications = FlutterLocalNotificationsPlugin();

  static const _androidDetails = AndroidNotificationDetails(
    'siji_channel',
    'SIJI Notifications',
    channelDescription: 'Notifikasi tiket SIJI',
    importance: Importance.high,
    priority: Priority.high,
    icon: '@mipmap/ic_launcher',
  );

  static const _notifDetails = NotificationDetails(android: _androidDetails);

  static Future<void> initialize() async {
    _initialized = false;
    try {
      await Firebase.initializeApp();

      await _notifications.initialize(
        const InitializationSettings(
          android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        ),
        onDidReceiveNotificationResponse: (details) {
          // Tap notif saat app foreground/background
          _handleNotificationTap(details.payload);
        },
      );

      await FirebaseMessaging.instance.requestPermission(
        alert: true, badge: true, sound: true,
      );

      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

      // Foreground
      FirebaseMessaging.onMessage.listen((message) {
        final n = message.notification;
        if (n != null) {
          _show(
            n.title ?? 'SIJI',
            n.body ?? '',
            message.data,
          );
        }
      });

      // App dibuka dari notif (background → foreground)
      FirebaseMessaging.onMessageOpenedApp.listen((message) {
        final ticketId = message.data['ticket_id'];
        if (ticketId != null) {
          _navigateToTicket(ticketId);
        }
      });

      // App dibuka dari terminated state
      final initialMessage = await FirebaseMessaging.instance.getInitialMessage();
      if (initialMessage != null) {
        final ticketId = initialMessage.data['ticket_id'];
        if (ticketId != null) {
          Future.delayed(Duration(seconds: 1), () {
            _navigateToTicket(ticketId);
          });
        }
      }

      // Save FCM token
      final token = await FirebaseMessaging.instance.getToken();
      if (token != null) {
        print('📱 Saving FCM token: ${token.substring(0, 20)}...');
        await ApiService.updateFcmToken(token);
      }

      FirebaseMessaging.instance.onTokenRefresh.listen(
            (t) => ApiService.updateFcmToken(t),
      );

      _initialized = true;
      print('✅ Notification initialized OK');
    } catch (e) {
      print('❌ NotificationService error: $e');
    }
  }

  static void _navigateToTicket(String ticketId) {
    try {
      final id = int.parse(ticketId);
      navigatorKey.currentState?.push(
        MaterialPageRoute(
          builder: (_) => TicketDetailWrapper(ticketId: id),
        ),
      );
    } catch (e) {
      print('Navigate error: $e');
    }
  }

  static void _handleNotificationTap(String? payload) {
    if (payload != null) {
      _navigateToTicket(payload);
    }
  }

  static void _show(String title, String body, Map<String, dynamic> data) {
    try {
      _notifications.show(
        DateTime.now().millisecondsSinceEpoch ~/ 1000,
        title,
        body,
        _notifDetails,
        payload: data['ticket_id'],
      );
    } catch (e) {}
  }

  static void reset() {
    _initialized = false;
  }
}

// Wrapper untuk navigasi ke detail tiket
class TicketDetailWrapper extends StatelessWidget {
  final int ticketId;
  const TicketDetailWrapper({required this.ticketId});

  @override
  Widget build(BuildContext context) {
    // Import di atas
    return TicketDetailScreen(ticketId: ticketId);
  }
}