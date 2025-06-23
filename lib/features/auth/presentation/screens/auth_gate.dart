import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:hellofarmer_app/features/auth/presentation/screens/login_screen.dart';
import 'package:hellofarmer_app/features/home/presentation/screens/home_screen.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

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
          // Navegamos para o ecrã principal da aplicação.
          return const HomeScreen();
        }

        // Caso contrário, o utilizador não está autenticado.
        // Mostramos o ecrã de login.
        return const LoginScreen();
      },
    );
  }
}
