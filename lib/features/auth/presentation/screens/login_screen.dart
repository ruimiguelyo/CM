import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../../../presentation/theme/app_theme.dart';
// ALTERAÇÃO: Importar a nova tela de registo
import 'register_screen.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Container(
          color: AppTheme.backgroundColor,
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 60.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              const Icon(Icons.agriculture, color: AppTheme.primaryColor, size: 80),
              const SizedBox(height: 16),
              const Text(
                'HelloFarmer',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryColor,
                ),
              ),
              const Text(
                'O Futuro do Agricultor',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: AppTheme.textColor,
                ),
              ),
              const SizedBox(height: 48),

              const TextField(
                decoration: InputDecoration(
                  labelText: 'E-mail',
                  prefixIcon: Icon(Icons.email_outlined),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),
              const TextField(
                decoration: InputDecoration(
                  labelText: 'Password',
                  prefixIcon: Icon(Icons.lock_outline),
                ),
                obscureText: true,
              ),
              const SizedBox(height: 12),

              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () {
                    // TODO: Implementar navegação para a tela de recuperação
                  },
                  child: const Text('Esqueceu-se do E-mail ou password?'),
                ),
              ),
              const SizedBox(height: 24),

              ElevatedButton(
                onPressed: () {
                  // TODO: Implementar lógica de autenticação com E-mail/Password
                },
                child: const Text('Iniciar Sessão'),
              ),
              const SizedBox(height: 24),

              const Row(
                children: <Widget>[
                  Expanded(child: Divider()),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8.0),
                    child: Text('ou'),
                  ),
                  Expanded(child: Divider()),
                ],
              ),
              const SizedBox(height: 24),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildSocialButton(FontAwesomeIcons.google, () {
                    // TODO: Implementar Google Sign-In
                  }),
                  const SizedBox(width: 20),
                  _buildSocialButton(FontAwesomeIcons.facebook, () {
                     // TODO: Implementar Facebook Sign-In
                  }),
                  const SizedBox(width: 20),
                  _buildSocialButton(FontAwesomeIcons.apple, () {
                     // TODO: Implementar Apple Sign-In
                  }),
                ],
              ),
              const SizedBox(height: 32),

              // --- BOTÃO CRIAR CONTA ---
              TextButton(
                onPressed: () {
                  // ALTERAÇÃO: Navegar para a tela de registo
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const RegisterScreen(),
                    ),
                  );
                },
                child: const Text('Não tem uma conta? Criar Conta'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSocialButton(IconData icon, VoidCallback onPressed) {
    return IconButton(
      icon: FaIcon(icon, color: AppTheme.primaryColor),
      iconSize: 30,
      onPressed: onPressed,
      style: IconButton.styleFrom(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: Colors.grey.shade300)
        ),
        padding: const EdgeInsets.all(16)
      ),
    );
  }
}
