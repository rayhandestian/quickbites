import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import '../screens/buyer/order_tracker_screen.dart';
import '../screens/seller/seller_orders_screen.dart';

// It is recommended to keep this function as a top-level function, outside of any class.
// This ensures that it can be handled in the background.
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // If you're going to use other Firebase services in the background, like Firestore,
  // make sure you call `initializeApp` before using them.
  // await Firebase.initializeApp(); // Not needed if already done in main.dart
  
  print("Handling a background message: ${message.messageId}");
}


class NotificationService {
  final GlobalKey<NavigatorState> navigatorKey;

  NotificationService({required this.navigatorKey});

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;

  Future<void> initialize() async {
    // Request permission for iOS and web
    await _firebaseMessaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    // Handle messages when the app is in the foreground
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('Got a message whilst in the foreground!');
      print('Message data: ${message.data}');

      if (message.notification != null) {
        print('Message also contained a notification: ${message.notification}');
        // Here you could show a local notification using a package like flutter_local_notifications
      }
    });

    // Handle messages when the app is opened from a terminated state
    FirebaseMessaging.instance.getInitialMessage().then((RemoteMessage? message) {
      if (message != null) {
        _handleNotificationClick(message);
      }
    });

    // Handle messages when the app is opened from a background state
    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationClick);

    // Set the background messaging handler
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  }

  void _handleNotificationClick(RemoteMessage message) {
    print('Notification clicked with data: ${message.data}');
    final screen = message.data['screen'];
    
    // Use the navigatorKey to navigate
    final navigator = navigatorKey.currentState;
    if (navigator == null) return;

    if (screen == 'order_tracker') {
      // Navigate to the buyer's order tracking screen.
      // The screen itself will fetch the latest order status.
      navigator.push(
        MaterialPageRoute(builder: (_) => const OrderTrackerScreen()),
      );
    } else if (screen == 'order_details') {
      // Navigate to the seller's main orders screen.
      // The screen will show the new order in the "Dipesan" tab.
      navigator.push(
        MaterialPageRoute(builder: (_) => const SellerOrdersScreen()),
      );
    }
  }
} 