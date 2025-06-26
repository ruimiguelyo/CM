import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:hellofarmer_app/models/user_model.dart';
import 'package:hellofarmer_app/screens/login_screen.dart';
import 'package:hellofarmer_app/screens/home_screen.dart';
import 'package:hellofarmer_app/services/firestore_service.dart';
import 'package:hellofarmer_app/services/notification_service.dart';
import 'package:flutter/foundation.dart';
import 'package:hellofarmer_app/screens/consumer_hub.dart';
import 'package:hellofarmer_app/screens/producer_hub.dart';

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  final NotificationService _notificationService = NotificationService();
  final FirestoreService _firestoreService = FirestoreService();

  @override
  Widget build(BuildContext context) {
    // O StreamBuilder reconstrói a UI sempre que há uma nova emissão no stream.
    // Neste caso, ele ouve as mudanças de estado de autenticação do Firebase.
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // Se ainda estiver a verificar o estado, mostramos um loading.
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // Se o snapshot tem dados, significa que o utilizador está autenticado.
        if (snapshot.hasData) {
          final user = snapshot.data!;
          _handleTokenRefresh(user.uid);

          // Agora, em vez de ir direto para a HomeScreen, verificamos o tipo de utilizador.
          return FutureBuilder<UserModel>(
            future: _firestoreService.getUser(user.uid).first,
            builder: (context, userSnapshot) {
              if (userSnapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(body: Center(child: CircularProgressIndicator()));
              }
              if (userSnapshot.hasError || !userSnapshot.hasData) {
                // Se não conseguir carregar o perfil, volta para o login.
                // Pode acontecer se o user for removido da BD mas a auth ainda existir.
                return const LoginScreen(); 
              }

              final userModel = userSnapshot.data!;
              if (userModel.tipo == 'consumidor') {
                return const ConsumerHub();
              } else if (userModel.tipo == 'agricultor') {
                return const ProducerHub();
              }

              // Como fallback, se o tipo for desconhecido, vai para uma página genérica ou de erro.
              // Por agora, vamos para o Login.
              return const LoginScreen();
            },
          );
        }

        // Caso contrário, o utilizador não está autenticado.
        // Mostramos o ecrã de login.
        return const LoginScreen();
      },
    );
  }

  // Obtém e guarda o token FCM quando o utilizador faz login
  Future<void> _handleTokenRefresh(String uid) async {
    // Apenas tentamos obter e guardar o token se não estivermos na web.
    if (kIsWeb) return;

    try {
      final token = await _notificationService.getFCMToken();
      print('FCM Token: $token'); // Para depuração
      await _firestoreService.updateUserFCMToken(uid, token);
    } catch (e) {
      print('Erro ao guardar o token FCM: $e');
    }
  }
}
