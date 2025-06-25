import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_apis/places.dart';
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
  // Chave para identificar e validar o nosso formulário
  final _formKey = GlobalKey<FormState>();

  // Controladores para obter o texto dos campos
  final _nomeController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _nifController = TextEditingController();
  final _telefoneController = TextEditingController();
  final _moradaController = TextEditingController();
  final _codigoPostalController = TextEditingController();

  // Instância do nosso repositório de autenticação
  final AuthRepository _authRepository = AuthRepository();
  // Instância do serviço de localização
  final LocationService _locationService = LocationService();

  // Variáveis para a pesquisa de moradas
  Timer? _debounce;
  List<Prediction> _predictions = [];
  bool _isSearching = false;
  String? _sessionToken;
  final FocusNode _moradaFocusNode = FocusNode();

  // Estado para controlar o loading
  bool _isLoading = false;

  // Novas variáveis para guardar as coordenadas
  double? _latitude;
  double? _longitude;

  @override
  void initState() {
    super.initState();
    // Gerar um token de sessão quando o ecrã é iniciado
    _sessionToken = _locationService.generateSessionToken();
    _moradaFocusNode.addListener(() {
      if (!_moradaFocusNode.hasFocus) {
        // Se o campo de morada perde o foco, limpa as sugestões
        setState(() {
          _predictions = [];
        });
      }
    });
  }

  // É importante limpar os controladores quando o widget é removido da árvore.
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

  /// Pesquisa a morada com um debounce para evitar chamadas excessivas à API
  void _onMoradaChanged(String input) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () async {
      if (input.isNotEmpty && _moradaFocusNode.hasFocus) {
        setState(() {
          _isSearching = true;
          _predictions = [];
        });
        final result = await _locationService.searchPlaces(input, sessionToken: _sessionToken!);
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

  /// Chamado quando uma sugestão de morada é selecionada
  Future<void> _onPredictionSelected(Prediction prediction) async {
    // Esconder o teclado e limpar sugestões
    FocusScope.of(context).unfocus();
    
    // Mostra loading enquanto busca detalhes
    setState(() {
      _moradaController.text = prediction.description ?? '';
      _predictions = []; 
      _isSearching = true;
    });

    final details = await _locationService.getPlaceDetails(prediction.placeId!, sessionToken: _sessionToken!);

    if (details != null && mounted) {
      // Extrair componentes da morada
      String streetName = '';
      String streetNumber = '';
      String postalCode = '';
      String city = '';

      if (details.addressComponents != null) {
        for (var component in details.addressComponents!) {
          if (component.types?.contains('route') ?? false) {
            streetName = component.longName ?? '';
          }
          if (component.types?.contains('street_number') ?? false) {
            streetNumber = component.longName ?? '';
          }
          if (component.types?.contains('postal_code') ?? false) {
            postalCode = component.longName ?? '';
          }
          if (component.types?.contains('postal_town') ?? false || (component.types?.contains('locality') ?? false)) {
            city = component.longName ?? '';
          }
        }
      }

      setState(() {
        _moradaController.text = '$streetName, $streetNumber'.trim().replaceAll(RegExp(r',$'), '');
        _codigoPostalController.text = postalCode;
        _latitude = details.geometry?.location.lat;
        _longitude = details.geometry?.location.lng;
        _isSearching = false;
      });
    } else if (mounted) {
      setState(() => _isSearching = false);
      _showErrorSnackBar('Não foi possível obter os detalhes da morada.');
    }

    // Gerar um novo token de sessão para a próxima pesquisa
    _sessionToken = _locationService.generateSessionToken();
  }


  // Método principal para o registo do utilizador
  Future<void> _registerUser() async {
    // Primeiro, validamos o formulário
    if (!_formKey.currentState!.validate()) {
      return; // Se não for válido, não fazemos nada.
    }

    // Ativamos o estado de loading para dar feedback visual
    setState(() {
      _isLoading = true;
    });

    try {
      // 1. Criar utilizador no Firebase Authentication
      UserCredential userCredential =
          await _authRepository.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      // 2. Se a criação for bem-sucedida, guardar dados no Firestore
      if (userCredential.user != null) {
        // Criar uma instância do nosso UserModel com os dados dos controladores
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

        // Guardar o objeto UserModel (convertido para Map) no Firestore
        await FirebaseFirestore.instance
            .collection('users')
            .doc(newUser.uid)
            .set(newUser.toMap());
        
        // **NOVA LÓGICA**: Forçar logout e voltar ao login
        // Fazemos logout para que o AuthGate não navegue automaticamente.
        await _authRepository.signOut();
        
        // Se o widget ainda estiver montado, mostramos feedback e voltamos.
        if (mounted) {
          _showSuccessSnackBar('Registo concluído! Por favor, inicie sessão.');
          Navigator.of(context).pop(); // Volta para o ecrã de login
        }
      }
    } on FirebaseAuthException catch (e) {
      // Tratar erros específicos do Firebase Auth
      String errorMessage = 'Ocorreu um erro durante o registo.';
      if (e.code == 'weak-password') {
        errorMessage = 'A password é demasiado fraca.';
      } else if (e.code == 'email-already-in-use') {
        errorMessage = 'Este e-mail já está a ser utilizado por outra conta.';
      }
      _showErrorSnackBar(errorMessage);
    } catch (e) {
      // Tratar outros erros genéricos
      _showErrorSnackBar('Ocorreu um erro inesperado. Tente novamente.');
    } finally {
      // Desativar o estado de loading, quer o processo tenha sucesso ou falhe.
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // Widget auxiliar para mostrar feedback de erro
  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.redAccent,
      ),
    );
  }

  // Widget auxiliar para mostrar feedback de sucesso
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
      TextFormField(
        controller: _nomeController,
        decoration: const InputDecoration(labelText: 'Nome Completo', prefixIcon: Icon(Icons.person_outline)),
        validator: (value) => (value == null || value.isEmpty) ? 'O nome é obrigatório.' : null,
      ),
      const SizedBox(height: 16),
      TextFormField(
        controller: _emailController,
        decoration: const InputDecoration(labelText: 'E-mail', prefixIcon: Icon(Icons.email_outlined)),
        keyboardType: TextInputType.emailAddress,
        validator: (value) => (value == null || !value.contains('@')) ? 'Insira um e-mail válido.' : null,
      ),
      const SizedBox(height: 16),
      TextFormField(
        controller: _passwordController,
        decoration: const InputDecoration(labelText: 'Password', prefixIcon: Icon(Icons.lock_outline)),
        obscureText: true,
        validator: (value) => (value == null || value.length < 6) ? 'A password deve ter pelo menos 6 caracteres.' : null,
      ),
      const SizedBox(height: 16),
      TextFormField(
        controller: _confirmPasswordController,
        decoration: const InputDecoration(labelText: 'Confirmar Password', prefixIcon: Icon(Icons.lock_person_outlined)),
        obscureText: true,
        validator: (value) => (value != _passwordController.text) ? 'As passwords não coincidem.' : null,
      ),
      const SizedBox(height: 24),
      const Divider(),
      const SizedBox(height: 16),
      TextFormField(
        controller: _nifController,
        decoration: const InputDecoration(labelText: 'NIF (Opcional)', prefixIcon: Icon(Icons.badge_outlined)),
        keyboardType: TextInputType.number,
      ),
      const SizedBox(height: 16),
      TextFormField(
        controller: _telefoneController,
        decoration: const InputDecoration(labelText: 'Telefone (Opcional)', prefixIcon: Icon(Icons.phone_outlined)),
        keyboardType: TextInputType.phone,
      ),
      const SizedBox(height: 16),
      _buildAddressSearch(),
    ];
  }

  Widget _buildAddressSearch() {
    return Column(
      children: [
        TextFormField(
          controller: _moradaController,
          focusNode: _moradaFocusNode,
          onChanged: _onMoradaChanged,
          decoration: InputDecoration(
            labelText: 'Morada',
            prefixIcon: const Icon(Icons.location_on_outlined),
            suffixIcon: _isSearching ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : null,
          ),
          validator: (value) => (value == null || value.isEmpty) ? 'A morada é obrigatória.' : null,
        ),
        if (_predictions.isNotEmpty)
          SizedBox(
            height: 200, // Altura fixa para a lista de sugestões
            child: ListView.builder(
              itemCount: _predictions.length,
              itemBuilder: (context, index) {
                final prediction = _predictions[index];
                return ListTile(
                  title: Text(prediction.description ?? ''),
                  onTap: () => _onPredictionSelected(prediction),
                );
              },
            ),
          ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _codigoPostalController,
          decoration: const InputDecoration(labelText: 'Código Postal', prefixIcon: Icon(Icons.local_post_office_outlined)),
          validator: (value) => (value == null || value.isEmpty) ? 'O código postal é obrigatório.' : null,
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
