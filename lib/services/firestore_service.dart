import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hellofarmer_app/models/product_model.dart';
import 'package:hellofarmer_app/models/user_model.dart';
import 'package:hellofarmer_app/models/order_model.dart';
import 'dart:math';

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

  // NOVO: Obtém um stream com todos os produtos de todos os agricultores.
  Stream<List<ProductModel>> getAllProducts() {
    return _db
        .collectionGroup('products')
        // .orderBy('dataCriacao', descending: true) // Removido para evitar erro de índice
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ProductModel.fromFirestore(doc))
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

  // --- MÉTODOS PARA GESTÃO DE ENCOMENDAS ---

  // Coloca uma nova encomenda
  Future<void> placeOrder(OrderModel order) async {
    return _db.runTransaction((transaction) async {
      // 1. Validar o stock de cada produto na encomenda
      for (final item in order.items) {
        final productRef = _db
            .collection('users')
            .doc(item.product.produtorId)
            .collection('products')
            .doc(item.product.id);
        
        final productSnapshot = await transaction.get(productRef);

        if (!productSnapshot.exists) {
          throw Exception('Produto ${item.product.nome} não encontrado!');
        }

        final currentStock = (productSnapshot.data()!['stock'] ?? 0).toDouble();

        if (currentStock < item.quantity) {
          throw Exception('Stock insuficiente para ${item.product.nome}. Disponível: $currentStock');
        }
      }

      // 2. Se todo o stock for válido, criar a encomenda e atualizar o stock
      final orderRef = _db.collection('orders').doc();
      transaction.set(orderRef, order.toMap());

      // 3. Atualizar o stock para cada item
      for (final item in order.items) {
        final productRef = _db
            .collection('users')
            .doc(item.product.produtorId)
            .collection('products')
            .doc(item.product.id);
        
        transaction.update(productRef, {
          'stock': FieldValue.increment(-item.quantity.toDouble())
        });
      }
    });
  }

  // Obtém um stream com todas as encomendas de um utilizador específico
  Stream<List<OrderModel>> getUserOrders(String userId) {
    return _db
        .collection('orders')
        .where('userId', isEqualTo: userId)
        // .orderBy('orderDate', descending: true) // Removido para evitar erro de índice
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => OrderModel.fromFirestore(doc))
            .toList());
  }

  // NOVO: Obtém um stream com todas as encomendas para um produtor específico
  Stream<List<OrderModel>> getProducerOrders(String producerId) {
    return _db
        .collection('orders')
        .where('producerIds', arrayContains: producerId)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => OrderModel.fromFirestore(doc))
            .toList());
  }

  // NOVO: Obtém um documento de encomenda específico pelo seu ID
  Future<DocumentSnapshot> getOrderById(String orderId) {
    return _db.collection('orders').doc(orderId).get();
  }

  // NOVO: Atualiza o estado de uma encomenda
  Future<void> updateOrderStatus(String orderId, String newStatus) {
    return _db.collection('orders').doc(orderId).update({'status': newStatus});
  }

  // NOVO: Submete uma avaliação para uma encomenda
  Future<void> submitOrderReview({
    required String orderId,
    required double orderRating,
    required double producerRating,
    required String reviewText,
    List<String>? reviewImageUrls,
  }) {
    return _db.collection('orders').doc(orderId).update({
      'orderRating': orderRating,
      'producerRating': producerRating,
      'reviewText': reviewText,
      if (reviewImageUrls != null) 'reviewImageUrls': reviewImageUrls,
    });
  }

  // NOVO: Obtém um stream com todas as avaliações para um produtor específico
  Stream<List<OrderModel>> getProducerReviews(String producerId) {
    return _db
        .collection('orders')
        .where('producerIds', arrayContains: producerId)
        .where('orderRating', isNotEqualTo: null) // Apenas encomendas com avaliação
        .snapshots()
        .map((snapshot) {
          final allReviews = snapshot.docs
              .map((doc) => OrderModel.fromFirestore(doc))
              .toList();
          
          // Filtrar para manter apenas a avaliação mais recente de cada consumidor
          final Map<String, OrderModel> uniqueReviews = {};
          for (final review in allReviews) {
            final userId = review.userId;
            if (!uniqueReviews.containsKey(userId) || 
                review.orderDate.compareTo(uniqueReviews[userId]!.orderDate) > 0) {
              uniqueReviews[userId] = review;
            }
          }
          
          return uniqueReviews.values.toList();
        });
  }

  // NOVO: Submete uma resposta do produtor a uma avaliação
  Future<void> submitProducerReply(String orderId, String replyText) {
    return _db.collection('orders').doc(orderId).update({
      'producerReplyText': replyText,
      'producerReplyDate': Timestamp.now(),
    });
  }

  // --- MÉTODOS PARA GESTÃO DE FAVORITOS ---

  Future<void> addProdutoAosFavoritos(String userId, String productId) {
    return _db.collection('users').doc(userId).update({
      'favoritos': FieldValue.arrayUnion([productId])
    });
  }

  Future<void> removerProdutoDosFavoritos(String userId, String productId) {
    return _db.collection('users').doc(userId).update({
      'favoritos': FieldValue.arrayRemove([productId])
    });
  }

  // --- MÉTODOS PARA GESTÃO DE PRODUTORES FAVORITOS ---

  Future<void> addProdutorAosFavoritos(String userId, String producerId) {
    return _db.collection('users').doc(userId).update({
      'favoriteProducers': FieldValue.arrayUnion([producerId])
    });
  }

  Future<void> removerProdutorDosFavoritos(String userId, String producerId) {
    return _db.collection('users').doc(userId).update({
      'favoriteProducers': FieldValue.arrayRemove([producerId])
    });
  }

  // NOVO: Obtém todas as categorias de produtos disponíveis.
  Future<List<String>> getAvailableCategories() async {
    final snapshot = await _db.collectionGroup('products').get();
    final categories = snapshot.docs
        .map((doc) => doc.data()['categoria'] as String?)
        .where((c) => c != null && c.isNotEmpty)
        .cast<String>()
        .toSet()
        .toList();
    categories.sort();
    return categories;
  }

  // NOVO: Obtém todos os produtores que têm produtos numa dada categoria.
  Future<List<UserModel>> getProducersByCategory(String category) async {
    // 1. Encontra todos os produtos na categoria
    final productsSnapshot = await _db
        .collectionGroup('products')
        .where('categoria', isEqualTo: category)
        .get();
    
    // 2. Extrai os IDs únicos dos produtores
    final producerIds = productsSnapshot.docs
        .map((doc) => doc.data()['produtorId'] as String)
        .toSet();

    if (producerIds.isEmpty) {
      return [];
    }

    // 3. Busca os dados desses produtores
    final usersSnapshot = await _db
        .collection('users')
        .where(FieldPath.documentId, whereIn: producerIds.toList())
        .get();
        
    return usersSnapshot.docs
        .map((doc) => UserModel.fromFirestore(doc))
        .toList();
  }
} 