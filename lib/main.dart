import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'state/app_state.dart';
import 'theme.dart';
import 'navigation.dart';
import 'screens/splash_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/orders/order_router_screen.dart';
import 'services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Firebase.initializeApp() reads android/app/google-services.json
  // automatically on Android - no explicit FirebaseOptions needed here.
  try {
    await Firebase.initializeApp();
    await NotificationService.init(navigatorKey: navigatorKey);
  } catch (e) {
    // If google-services.json wasn't set up yet, continue without push
    // notifications rather than crashing the whole app on launch — the
    // dashboard's 20s poll still surfaces new orders either way.
    debugPrint('Firebase/notifications not available: $e');
  }

  runApp(const DeliveryPartnerApp());
}

class DeliveryPartnerApp extends StatelessWidget {
  const DeliveryPartnerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AppState(),
      child: MaterialApp(
        title: 'JEEVI Partner',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        navigatorKey: navigatorKey,
        home: const SplashScreen(),
        onGenerateRoute: (settings) {
          if (settings.name == '/order-detail') {
            final orderId = settings.arguments as int;
            return MaterialPageRoute(builder: (_) => OrderRouterScreen(orderId: orderId));
          }
          if (settings.name == '/login') {
            final sessionExpired = settings.arguments == 'session_expired';
            return MaterialPageRoute(builder: (_) => LoginScreen(sessionExpired: sessionExpired));
          }
          return null;
        },
      ),
    );
  }
}
