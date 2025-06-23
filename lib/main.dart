import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:hellofarmer_app/firebase_options.dart';
// Imports refatorados para a nova arquitetura
import 'package:hellofarmer_app/screens/auth_gate.dart';
import 'package:hellofarmer_app/theme/app_theme.dart';

Future<void> main() async {
  // Garantimos que os bindings do Flutter estão inicializados antes de chamar o Firebase.
  WidgetsFlutterBinding.ensureInitialized();
  // Inicializamos o Firebase com as opções da plataforma atual.
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
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
