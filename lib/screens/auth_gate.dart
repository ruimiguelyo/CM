import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:hellofarmer_app/screens/login_screen.dart';
import 'package:hellofarmer_app/screens/home_screen.dart';
import 'package:hellofarmer_app/services/firestore_service.dart';
import 'package:hellofarmer_app/services/notification_service.dart';
import 'package:flutter/foundation.dart';

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
          _handleTokenRefresh(snapshot.data!.uid);
          // Navegamos para o ecrã principal da aplicação.
          return const HomeScreen();
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
