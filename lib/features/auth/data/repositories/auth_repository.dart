import 'package:firebase_auth/firebase_auth.dart';

class AuthRepository {
  // Criamos uma instância do Firebase Auth para ser usada na classe.
  final FirebaseAuth _firebaseAuth;

  // O construtor permite-nos injetar uma instância do FirebaseAuth,
  // o que é útil para testes no futuro. Se nada for passado, usa a instância padrão.
  AuthRepository({FirebaseAuth? firebaseAuth})
      : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance;

  // Um stream que nos informa em tempo real se o estado de autenticação mudou
  // (ex: utilizador fez login ou logout).
  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();

  // Método para fazer login com e-mail e password.
  Future<void> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } catch (e) {
      // Aqui podemos tratar erros específicos no futuro.
      // Por agora, relançamos a exceção para ser tratada na UI.
      rethrow;
    }
  }

  // Método para criar um novo utilizador com e-mail e password.
  Future<UserCredential> createUserWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      final userCredential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      return userCredential;
    } catch (e) {
      rethrow;
    }
  }

  // Método para fazer logout.
  Future<void> signOut() async {
    await _firebaseAuth.signOut();
  }
}
