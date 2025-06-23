import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:hellofarmer_app/theme/app_theme.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Obtemos o utilizador atual para mostrar o e-mail.
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Página Principal'),
        actions: [
          // Adicionamos um botão de logout.
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              // Chamamos o método signOut do Firebase.
              // O AuthGate irá detetar a mudança de estado e mostrar o ecrã de login.
              FirebaseAuth.instance.signOut();
            },
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Bem-vindo à HelloFarmer!',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppTheme.primaryColor),
            ),
            const SizedBox(height: 16),
            // Mostramos o e-mail do utilizador se ele existir.
            if (user != null)
              Text(
                'Sessão iniciada como: ${user.email}',
                style: const TextStyle(fontSize: 16),
              ),
          ],
        ),
      ),
    );
  }
}

