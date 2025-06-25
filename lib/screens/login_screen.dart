import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:hellofarmer_app/theme/app_theme.dart';
import 'package:hellofarmer_app/screens/register_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hellofarmer_app/services/auth_repository.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final AuthRepository _authRepository = AuthRepository();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _loginUser() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await _authRepository.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      // AuthGate will handle navigation on success
    } on FirebaseAuthException catch (e) {
      String errorMessage = 'Ocorreu um erro ao iniciar sessão.';
      if (e.code == 'user-not-found' || e.code == 'wrong-password' || e.code == 'invalid-credential') {
        errorMessage = 'O e-mail ou a password estão incorretos.';
      }
      _showErrorSnackBar(errorMessage);
    } catch (e) {
      _showErrorSnackBar('Ocorreu um erro inesperado. Tente novamente.');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.redAccent,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Container(
          color: AppTheme.backgroundColor,
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 60.0),
          child: Form(
            key: _formKey,
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
                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                    labelText: 'E-mail',
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || !value.contains('@')) {
                      return 'Por favor, introduza um e-mail válido.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _passwordController,
                  decoration: const InputDecoration(
                    labelText: 'Password',
                    prefixIcon: Icon(Icons.lock_outline),
                  ),
                  obscureText: true,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor, introduza a sua password.';
                    }
                    return null;
                  },
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
                  onPressed: _isLoading ? null : _loginUser,
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.0,
                          ),
                        )
                      : const Text('Iniciar Sessão'),
                ),
                const SizedBox(height: 24),

                // Botões de login rápido para teste
                Text('Acesso Rápido (Desenvolvimento)', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey.shade600)),
                const SizedBox(height: 12),
                
                // Consumidores (Zona de Braga - 5-30km)
                Text('Consumidores:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue.shade700)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _buildQuickLoginButton('Rita Sousa', 'rita.sousa@email.pt', Colors.blue),
                    _buildQuickLoginButton('Tiago Mendes', 'tiago.mendes@email.pt', Colors.blue),
                    _buildQuickLoginButton('Carla Nunes', 'carla.nunes@email.pt', Colors.blue),
                    _buildQuickLoginButton('Bruno Dias', 'bruno.dias@email.pt', Colors.blue),
                    _buildQuickLoginButton('Luís Cardoso', 'luis.cardoso@email.pt', Colors.blue),
                  ],
                ),
                
                const SizedBox(height: 16),
                
                // Produtores (Região de Braga - 5-30km)
                Text('Produtores:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green.shade700)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _buildQuickLoginButton('João Silva', 'joao.silva@farm.pt', Colors.green),
                    _buildQuickLoginButton('Maria Santos', 'maria.santos@verde.pt', Colors.green),
                    _buildQuickLoginButton('António Costa', 'antonio.costa@bio.pt', Colors.green),
                    _buildQuickLoginButton('Ana Ferreira', 'ana.ferreira@natural.pt', Colors.green),
                    _buildQuickLoginButton('Patrícia Lima', 'patricia.lima@campo.pt', Colors.green),
                  ],
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
                TextButton(
                  onPressed: () {
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
      ),
    );
  }

  void _loginFast(String email) {
    _emailController.text = email;
    _passwordController.text = 'password123';
    _loginUser();
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

  Widget _buildQuickLoginButton(String name, String email, Color color) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(backgroundColor: color),
      onPressed: _isLoading ? null : () => _loginFast(email),
      child: Text(name, style: const TextStyle(fontSize: 12)),
    );
  }
}
