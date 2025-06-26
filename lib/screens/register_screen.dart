import 'dart:async';
import 'package:flutter/material.dart';
import 'package:hellofarmer_app/theme/app_theme.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hellofarmer_app/models/user_model.dart';
import 'package:hellofarmer_app/services/auth_repository.dart';
import 'package:hellofarmer_app/services/location_service.dart';
import 'package:flutter_animate/flutter_animate.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nomeController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _nifController = TextEditingController();
  final _telefoneController = TextEditingController();
  final _moradaController = TextEditingController();
  final _codigoPostalController = TextEditingController();

  final AuthRepository _authRepository = AuthRepository();
  final LocationService _locationService = LocationService();

  Timer? _debounce;
  List<AddressSuggestion> _predictions = [];
  bool _isSearching = false;
  final FocusNode _moradaFocusNode = FocusNode();

  bool _isLoading = false;

  double? _latitude;
  double? _longitude;

  @override
  void initState() {
    super.initState();
    _moradaFocusNode.addListener(() {
      if (!_moradaFocusNode.hasFocus) {
        setState(() {
          _predictions = [];
        });
      }
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _moradaFocusNode.dispose();
    _nomeController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _nifController.dispose();
    _telefoneController.dispose();
    _moradaController.dispose();
    _codigoPostalController.dispose();
    super.dispose();
  }

  void _onMoradaChanged(String input) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () async {
      if (input.isNotEmpty && _moradaFocusNode.hasFocus) {
        setState(() {
          _isSearching = true;
          _predictions = [];
        });
        final result = await _locationService.searchPlaces(input);
        if (mounted) {
          setState(() {
            _predictions = result;
            _isSearching = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _predictions = [];
            _isSearching = false;
          });
        }
      }
    });
  }

  void _onPredictionSelected(AddressSuggestion prediction) async {
    FocusScope.of(context).unfocus();
    
    setState(() {
      _moradaController.text = prediction.description;
      _latitude = prediction.latitude;
      _longitude = prediction.longitude;
      _predictions = [];
      _isSearching = false;
    });

    final placemark = await _locationService.getAddressFromCoordinates(prediction.latitude, prediction.longitude);
    if (placemark != null && placemark.postalCode != null) {
      if (mounted) {
        setState(() {
          _codigoPostalController.text = placemark.postalCode!;
        });
      }
    }
  }

  Future<void> _registerUser() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      UserCredential userCredential =
          await _authRepository.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      if (userCredential.user != null) {
        UserModel newUser = UserModel(
          uid: userCredential.user!.uid,
          nome: _nomeController.text.trim(),
          email: _emailController.text.trim(),
          nif: _nifController.text.trim(),
          telefone: _telefoneController.text.trim(),
          morada: _moradaController.text.trim(),
          codigoPostal: _codigoPostalController.text.trim(),
          latitude: _latitude,
          longitude: _longitude,
        );

        await FirebaseFirestore.instance
            .collection('users')
            .doc(newUser.uid)
            .set(newUser.toMap());
        
        await _authRepository.signOut();
        
        if (mounted) {
          _showSuccessSnackBar('Registo concluído! Por favor, inicie sessão.');
          Navigator.of(context).pop();
        }
      }
    } on FirebaseAuthException catch (e) {
      String errorMessage = 'Ocorreu um erro durante o registo.';
      if (e.code == 'weak-password') {
        errorMessage = 'A password é demasiado fraca.';
      } else if (e.code == 'email-already-in-use') {
        errorMessage = 'Este e-mail já está a ser utilizado por outra conta.';
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

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Criar Conta'),
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                _buildHeader(context),
                const SizedBox(height: 32),
                ..._buildFormFields(),
                const SizedBox(height: 32),
                _buildRegisterButton(),
                const SizedBox(height: 16),
                _buildLoginRedirect(context),
              ].animate(interval: 80.ms).fade(duration: 300.ms).slideY(begin: 0.2),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Column(
      children: [
        Text(
          'Junte-se à comunidade',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          'Crie a sua conta para começar a comprar ou vender produtos locais frescos.',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              ),
        ),
      ],
    );
  }

  List<Widget> _buildFormFields() {
    return [
      _buildAddressSearchField(),
      const SizedBox(height: 16),
      TextFormField(
        controller: _codigoPostalController,
        decoration: const InputDecoration(labelText: 'Código Postal'),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Por favor, introduza o seu código postal.';
          }
          return null;
        },
      ),
      const SizedBox(height: 16),
      TextFormField(
        controller: _nomeController,
        decoration: const InputDecoration(labelText: 'Nome Completo'),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Por favor, introduza o seu nome.';
          }
          return null;
        },
      ),
      const SizedBox(height: 16),
      TextFormField(
        controller: _nifController,
        decoration: const InputDecoration(labelText: 'NIF'),
        keyboardType: TextInputType.number,
      ),
      const SizedBox(height: 16),
      TextFormField(
        controller: _telefoneController,
        decoration: const InputDecoration(labelText: 'Telefone'),
        keyboardType: TextInputType.phone,
      ),
      const SizedBox(height: 16),
      TextFormField(
        controller: _emailController,
        decoration: const InputDecoration(labelText: 'E-mail'),
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
        decoration: const InputDecoration(labelText: 'Password'),
        obscureText: true,
        validator: (value) {
          if (value == null || value.length < 6) {
            return 'A password deve ter pelo menos 6 caracteres.';
          }
          return null;
        },
      ),
      const SizedBox(height: 16),
      TextFormField(
        controller: _confirmPasswordController,
        decoration: const InputDecoration(labelText: 'Confirmar Password'),
        obscureText: true,
        validator: (value) {
          if (value != _passwordController.text) {
            return 'As passwords não coincidem.';
          }
          return null;
        },
      ),
    ];
  }

  Widget _buildAddressSearchField() {
    return Column(
      children: [
        TextFormField(
          controller: _moradaController,
          focusNode: _moradaFocusNode,
          onChanged: _onMoradaChanged,
          decoration: InputDecoration(
            labelText: 'Pesquisar Morada',
            prefixIcon: const Icon(Icons.location_on_outlined),
            suffixIcon: _isSearching ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : null,
          ),
          validator: (value) => value!.isEmpty ? 'Insira a morada.' : null,
        ),
        if (_predictions.isNotEmpty)
          Container(
            height: 200,
            margin: const EdgeInsets.only(top: 8),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300)
            ),
            child: ListView.builder(
              itemCount: _predictions.length,
              itemBuilder: (context, index) {
                final prediction = _predictions[index];
                return ListTile(
                  title: Text(prediction.description),
                  onTap: () => _onPredictionSelected(prediction),
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _buildRegisterButton() {
    return ElevatedButton(
      onPressed: _isLoading ? null : _registerUser,
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16),
      ),
      child: _isLoading
          ? const SizedBox(
              height: 24,
              width: 24,
              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
            )
          : const Text('Criar Conta'),
    );
  }

  Widget _buildLoginRedirect(BuildContext context) {
    return TextButton(
      onPressed: () => Navigator.of(context).pop(),
      child: RichText(
        textAlign: TextAlign.center,
        text: TextSpan(
          text: 'Já tem uma conta? ',
          style: Theme.of(context).textTheme.bodyMedium,
          children: [
            TextSpan(
              text: 'Iniciar Sessão',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
