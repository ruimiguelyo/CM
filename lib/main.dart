import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
// ALTERAÇÃO: Corrigimos o caminho de importação para o AuthGate.
import 'package:hellofarmer_app/features/auth/presentation/screens/auth_gate.dart';
import 'package:hellofarmer_app/presentation/theme/app_theme.dart';

Future<void> main() async {
  // Garantimos que os bindings do Flutter estão inicializados antes de chamar o Firebase.
  WidgetsFlutterBinding.ensureInitialized();
  // Inicializamos o Firebase. Isto tem de ser feito antes de usar qualquer serviço Firebase.
  await Firebase.initializeApp();
  runApp(const HelloFarmerApp());
}

class HelloFarmerApp extends StatelessWidget {
  const HelloFarmerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'HelloFarmer',
      theme: AppTheme.lightTheme,
      // Agora que o import está correto, o AuthGate será encontrado.
      home: const AuthGate(),
      debugShowCheckedModeBanner: false,
    );
  }
}
