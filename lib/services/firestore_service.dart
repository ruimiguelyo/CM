import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hellofarmer_app/models/product_model.dart';
import 'package:hellofarmer_app/models/user_model.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Obtém um stream com todos os utilizadores que são agricultores.
  // Usamos um stream para que o mapa se atualize automaticamente se os dados mudarem.
  Stream<List<UserModel>> getAgricultores() {
    return _db
        .collection('users')
        .where('tipo', isEqualTo: 'agricultor')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => UserModel.fromFirestore(doc))
            .toList());
  }

  // Obtém os dados de um utilizador específico em tempo real.
  Stream<UserModel> getUser(String uid) {
    return _db
        .collection('users')
        .doc(uid)
        .snapshots()
        .map((snapshot) => UserModel.fromFirestore(snapshot));
  }

  // Atualiza o token FCM de um utilizador.
  Future<void> updateUserFCMToken(String uid, String? token) {
    if (token == null) return Future.value(); // Não faz nada se o token for nulo
    return _db.collection('users').doc(uid).update({
      'fcmToken': token,
    });
  }

  // --- MÉTODOS PARA GESTÃO DE PRODUTOS ---

  // Obtém um stream dos produtos de um agricultor específico
  Stream<List<ProductModel>> getProdutos(String uid) {
    return _db
        .collection('users')
        .doc(uid)
        .collection('products')
        .orderBy('dataCriacao', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ProductModel.fromFirestore(doc))
            .toList());
  }

  // Adiciona um novo produto
  Future<void> adicionarProduto(String uid, ProductModel produto) {
    return _db
        .collection('users')
        .doc(uid)
        .collection('products')
        .add(produto.toFirestore());
  }

  // Atualiza um produto existente
  Future<void> atualizarProduto(String uid, ProductModel produto) {
    return _db
        .collection('users')
        .doc(uid)
        .collection('products')
        .doc(produto.id)
        .update(produto.toFirestore());
  }

  // Remove um produto
  Future<void> removerProduto(String uid, String produtoId) {
    return _db
        .collection('users')
        .doc(uid)
        .collection('products')
        .doc(produtoId)
        .delete();
  }
} 