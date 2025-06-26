import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:hellofarmer_app/firebase_options.dart';
// Imports refatorados para a nova arquitetura
import 'package:hellofarmer_app/screens/splash_screen.dart';
import 'package:hellofarmer_app/services/notification_service.dart';
import 'package:hellofarmer_app/theme/app_theme.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:hellofarmer_app/providers/cart_provider.dart';
import 'package:provider/provider.dart';
import 'package:flutter/foundation.dart';

// Esta função tem de estar fora de uma classe (top-level)
// para poder ser chamada quando a app está em segundo plano.
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // If you're going to use other Firebase services in the background, like Firestore,
  // make sure you call `initializeApp` before using them.
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  print("Handling a background message: ${message.messageId}");
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } on FirebaseException catch (e) {
    // This is a workaround for a known issue with Firebase initialization on hot reloads.
    if (e.code != 'duplicate-app') {
      rethrow;
    }
  }

  // Handle background messages for notifications
  // This needs to be outside of the app's main logic
  if (!kIsWeb) {
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  }

  // Inicializa o serviço de notificações aqui.
  await NotificationService().initNotifications();

  runApp(const MyApp());
}

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => CartProvider(),
      child: MaterialApp(
        title: 'HelloFarmer',
        theme: AppTheme.lightTheme,
        // Usamos o SplashScreen como ecrã inicial
        navigatorKey: navigatorKey,
        home: const SplashScreen(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
