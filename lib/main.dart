import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import 'services/auth_service.dart';
import 'providers/menu_provider.dart';
import 'providers/order_provider.dart';
import 'providers/tenant_provider.dart';
import 'screens/welcome_screen.dart';
import 'utils/theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print('Firebase initialized successfully');
  } catch (e) {
    print('Failed to initialize Firebase: $e');
    // Continue with the app but functionality that depends on Firebase will be limited
  }
  
  runApp(const MyApp());
}

// Default Firebase Options for platform-specific configuration
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (defaultTargetPlatform == TargetPlatform.android) {
      // Android
      return const FirebaseOptions(
        apiKey: 'AIzaSyDaVplCtnLms8sZ4GuaT6Npc1dt01uqkbw',
        appId: '1:689965371852:android:d72ea5035948bc175d4d69',
        messagingSenderId: '689965371852',
        projectId: 'quickbites-456e4',
        storageBucket: 'quickbites-456e4.firebasestorage.app',
      );
    } else {
      // Default to Android configuration
      return const FirebaseOptions(
        apiKey: 'AIzaSyDaVplCtnLms8sZ4GuaT6Npc1dt01uqkbw',
        appId: '1:689965371852:android:d72ea5035948bc175d4d69',
        messagingSenderId: '689965371852',
        projectId: 'quickbites-456e4',
        storageBucket: 'quickbites-456e4.firebasestorage.app',
      );
    }
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthService()),
        ChangeNotifierProvider(create: (_) => MenuProvider()),
        ChangeNotifierProvider(create: (_) => OrderProvider()),
        ChangeNotifierProvider(create: (_) => TenantProvider()),
      ],
      child: MaterialApp(
        title: 'QuickBites',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.getTheme(),
        home: const WelcomeScreen(),
      ),
    );
  }
}
