import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:hellofarmer_app/theme/app_theme.dart';
import 'package:hellofarmer_app/screens/register_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hellofarmer_app/services/auth_repository.dart';
import 'package:flutter_animate/flutter_animate.dart';

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
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 40.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                // Cabeçalho com Animação
                _buildHeader(context),
                const SizedBox(height: 48),

                // Formulário com Animação
                _buildLoginForm(),
                const SizedBox(height: 24),

                // Botão de Login com Animação
                _buildLoginButton(),
                const SizedBox(height: 24),
                
                // Acesso rápido para desenvolvimento (se necessário)
                _buildQuickLoginSection(),
                
                // Divisor e Opções de Registo
                _buildFooter(context),
              ].animate(interval: 100.ms).fade(duration: 400.ms).slideY(begin: 0.5),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Column(
      children: [
        Icon(
          Icons.agriculture_rounded,
          color: Theme.of(context).colorScheme.primary,
          size: 60,
        ),
        const SizedBox(height: 16),
        Text(
          'Bem-vindo à HelloFarmer',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 8),
        Text(
          'Conectando produtores e consumidores.',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              ),
        ),
      ],
    );
  }

  Widget _buildLoginForm() {
    return Column(
      children: [
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
              // TODO: Implementar recuperação de password
            },
            child: const Text('Esqueceu-se da password?'),
          ),
        ),
      ],
    );
  }

  Widget _buildLoginButton() {
    return ElevatedButton(
      onPressed: _isLoading ? null : _loginUser,
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16),
      ),
      child: _isLoading
          ? const SizedBox(
              height: 24,
              width: 24,
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 2.5,
              ),
            )
          : const Text('Iniciar Sessão'),
    );
  }

  Widget _buildFooter(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 24),
        const Row(
          children: <Widget>[
            Expanded(child: Divider()),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0),
              child: Text('OU'),
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
            const SizedBox(width: 24),
            _buildSocialButton(FontAwesomeIcons.apple, () {
              // TODO: Implementar Apple Sign-In
            }),
          ],
        ),
        const SizedBox(height: 32),
        TextButton(
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (context) => const RegisterScreen()),
            );
          },
          child: RichText(
            text: TextSpan(
              text: 'Não tem uma conta? ',
              style: Theme.of(context).textTheme.bodyMedium,
              children: [
                TextSpan(
                  text: 'Criar Conta',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // Seção de login rápido mantida para desenvolvimento, pode ser removida para produção
  Widget _buildQuickLoginSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        Text(
          'Acesso Rápido (Desenvolvimento)',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(color: Colors.grey.shade600),
        ),
        const SizedBox(height: 12),
        _buildQuickLoginCategory('Consumidores', [
          _buildQuickLoginButton('Rita Sousa', 'rita.sousa@email.pt', Colors.blue),
          _buildQuickLoginButton('Tiago Mendes', 'tiago.mendes@email.pt', Colors.blue),
          _buildQuickLoginButton('Luís Cardoso', 'luis.cardoso@email.pt', Colors.blue),
        ]),
        const SizedBox(height: 16),
        _buildQuickLoginCategory('Produtores', [
          _buildQuickLoginButton('João Silva', 'joao.silva@farm.pt', Colors.green),
          _buildQuickLoginButton('Maria Santos', 'maria.santos@verde.pt', Colors.green),
          _buildQuickLoginButton('Ana Ferreira', 'ana.ferreira@natural.pt', Colors.green),
        ]),
        const SizedBox(height: 24),
      ],
    );
  }
  
  Widget _buildQuickLoginCategory(String title, List<Widget> buttons) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: title == 'Consumidores' ? Colors.blue.shade700 : Colors.green.shade700)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: buttons,
        ),
      ],
    );
  }

  void _loginFast(String email) {
    _emailController.text = email;
    _passwordController.text = 'password123';
    _loginUser();
  }

  Widget _buildSocialButton(IconData icon, VoidCallback onPressed) {
    return IconButton(
      icon: FaIcon(icon),
      iconSize: 28,
      onPressed: onPressed,
      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
    );
  }

  Widget _buildQuickLoginButton(String name, String email, Color color) {
    return ElevatedButton(
      onPressed: () => _loginFast(email),
      style: ElevatedButton.styleFrom(
        backgroundColor: color.withOpacity(0.1),
        foregroundColor: color is MaterialColor ? color.shade800 : color,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      child: Text(name, style: const TextStyle(fontSize: 12)),
    );
  }
}
