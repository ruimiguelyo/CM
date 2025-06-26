import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:hellofarmer_app/services/firestore_service.dart';
import 'package:hellofarmer_app/screens/producer_order_detail_screen.dart';
import 'package:hellofarmer_app/screens/order_detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:hellofarmer_app/models/order_model.dart';

// Variável Global para o NavigatorKey, para podermos navegar a partir de fora da árvore de widgets.
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

// Função para ser chamada quando uma notificação é aberta, fora da classe.
Future<void> _handleMessage(RemoteMessage message) async {
  if (message.data['orderId'] != null) {
    final orderId = message.data['orderId'];
    final firestoreService = FirestoreService();
    
    try {
      final orderDoc = await firestoreService.getOrderById(orderId);
      if (orderDoc.exists) {
        final order = OrderModel.fromFirestore(orderDoc);
        
        // Determina para que ecrã navegar
        if(message.data['type'] == 'NEW_ORDER') {
          navigatorKey.currentState?.push(MaterialPageRoute(
            builder: (context) => ProducerOrderDetailScreen(order: order),
          ));
        } else {
          navigatorKey.currentState?.push(MaterialPageRoute(
            builder: (context) => OrderDetailScreen(order: order),
          ));
        }
      }
    } catch (e) {
      print('Erro ao navegar a partir da notificação: $e');
    }
  }
}

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
      // Lida com a notificação que abriu a app (background/terminated)
      FirebaseMessaging.onMessageOpenedApp.listen(_handleMessage);
      // Lida com a notificação que abriu a app a partir do estado terminado
      _checkForInitialMessage();
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
          payload: message.data['orderId'], // Passa o ID da encomenda como payload
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

    await _localNotifications.initialize(
      settings,
      // Lida com o toque na notificação local (quando a app está em primeiro plano)
      onDidReceiveNotificationResponse: (response) async {
        if (response.payload != null) {
          final orderDoc = await FirestoreService().getOrderById(response.payload!);
          if(orderDoc.exists) {
            final order = OrderModel.fromFirestore(orderDoc);
            // Assume que se a app está aberta, é um consumidor a ver o estado.
             navigatorKey.currentState?.push(MaterialPageRoute(
                builder: (context) => OrderDetailScreen(order: order),
            ));
          }
        }
      },
    );

    // Criar o canal no Android
    await _localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_androidChannel);
  }

  // NOVO: Verifica se a app foi aberta por uma notificação
  Future<void> _checkForInitialMessage() async {
    final initialMessage = await _firebaseMessaging.getInitialMessage();
    if (initialMessage != null) {
      _handleMessage(initialMessage);
    }
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