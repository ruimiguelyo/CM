import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();

  // Canal para notificações no Android
  final AndroidNotificationChannel _androidChannel = const AndroidNotificationChannel(
    'high_importance_channel', // id
    'Notificações Importantes', // title
    description: 'Este canal é usado para notificações importantes.',
    importance: Importance.max,
  );

  Future<void> initNotifications() async {
    // Pedir permissão ao utilizador (iOS e Android >= 13)
    await _firebaseMessaging.requestPermission();

    // A inicialização de notificações locais é diferente para a web,
    // e o nosso setup atual é apenas para mobile. Por isso, só o executamos em mobile.
    if (!kIsWeb) {
      await _initLocalNotifications();
    }

    // Lidar com mensagens em primeiro plano (app aberta)
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      final notification = message.notification;
      final android = message.notification?.android;

      // Na web, não mostramos uma notificação local, apenas imprimimos na consola.
      // Em mobile, mostramos a notificação local.
      if (notification != null && android != null && !kIsWeb) {
        _localNotifications.show(
          notification.hashCode,
          notification.title,
          notification.body,
          NotificationDetails(
            android: AndroidNotificationDetails(
              _androidChannel.id,
              _androidChannel.name,
              channelDescription: _androidChannel.description,
              icon: '@mipmap/ic_launcher',
            ),
          ),
        );
      }
    });
  }

  Future<void> _initLocalNotifications() async {
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const DarwinInitializationSettings iosSettings = DarwinInitializationSettings();
    
    const InitializationSettings settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(settings);

    // Criar o canal no Android
    await _localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_androidChannel);
  }

  // Método para obter o token FCM do dispositivo
  Future<String?> getFCMToken() async {
    return await _firebaseMessaging.getToken();
  }

  // Exemplo de como mostrar uma notificação local (para testes)
  Future<void> showLocalNotification({
    required String title,
    required String body,
  }) async {
    await _localNotifications.show(
      0,
      title,
      body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _androidChannel.id,
          _androidChannel.name,
          channelDescription: _androidChannel.description,
          importance: Importance.max,
          priority: Priority.high,
        ),
      ),
    );
  }
} 