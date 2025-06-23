import 'package:flutter/material.dart';
import '../../../../presentation/theme/app_theme.dart';

class RegisterScreen extends StatelessWidget {
  const RegisterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // A AppBar adiciona um botão de "voltar" automaticamente,
      appBar: AppBar(
        title: const Text('Cria a tua conta'),
        backgroundColor: AppTheme.backgroundColor,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppTheme.primaryColor),
        titleTextStyle: const TextStyle(
          color: AppTheme.primaryColor,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      body: SingleChildScrollView(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              // --- CAMPOS DE FORMULÁRIO ---
              _buildTextField(label: 'Nome Completo', icon: Icons.person_outline),
              const SizedBox(height: 16),
              _buildTextField(label: 'E-mail', icon: Icons.email_outlined, keyboardType: TextInputType.emailAddress),
              const SizedBox(height: 16),
              _buildTextField(label: 'Password', icon: Icons.lock_outline, obscureText: true),
              const SizedBox(height: 16),
               _buildTextField(label: 'Confirmar Password', icon: Icons.lock_outline, obscureText: true),
              const SizedBox(height: 16),
              _buildTextField(label: 'NIF de empresa ou NIF pessoal', icon: Icons.badge_outlined),
              const SizedBox(height: 16),
              _buildTextField(label: 'Nº de Telemóvel', icon: Icons.phone_outlined, keyboardType: TextInputType.phone),
              const SizedBox(height: 16),
              _buildTextField(label: 'Morada', icon: Icons.home_outlined),
              const SizedBox(height: 16),
              _buildTextField(label: 'Código Postal', icon: Icons.local_post_office_outlined),
              const SizedBox(height: 32),

              // --- BOTÃO DE REGISTO ---
              ElevatedButton(
                onPressed: () {
                  // TODO: Implementar lógica de registo de utilizador
                },
                child: const Text('Registar!'),
              ),
              const SizedBox(height: 16),

              // --- VOLTAR AO LOGIN ---
              TextButton(
                onPressed: () {
                  // Fecha a tela de registo e volta à anterior (Login)
                  Navigator.of(context).pop();
                },
                child: const Text('Já tem uma conta? Iniciar Sessão'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Widget auxiliar para criar os campos de texto e manter o código limpo
  Widget _buildTextField({
    required String label,
    required IconData icon,
    bool obscureText = false,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextField(
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
      ),
      obscureText: obscureText,
      keyboardType: keyboardType,
    );
  }
}
