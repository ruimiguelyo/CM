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
  // Se quiser fazer algo com a mensagem em segundo plano, como guardar dados,
  // pode fazer aqui. Por agora, apenas imprimimos para depuração.
  print("A lidar com uma mensagem em segundo plano: ${message.messageId}");
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } on FirebaseException catch (e) {
    if (e.code != 'duplicate-app') {
      rethrow;
    }
  }

  if (!kIsWeb) {
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
    await NotificationService().initNotifications();
  }

  runApp(const HelloFarmerApp());
}

class HelloFarmerApp extends StatelessWidget {
  const HelloFarmerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => CartProvider(),
      child: MaterialApp(
        title: 'HelloFarmer',
        theme: AppTheme.lightTheme,
        // Usamos o SplashScreen como ecrã inicial
        home: const SplashScreen(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
