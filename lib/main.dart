import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
// ALTERAÇÃO: Usamos um import absoluto para garantir que o caminho está sempre correto.
import 'package:hellofarmer_app/features/presentation/screens/auth_gate.dart';
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
      // A nossa home continua a ser o AuthGate, que agora será encontrado corretamente.
      home: const AuthGate(),
      debugShowCheckedModeBanner: false,
    );
  }
}
