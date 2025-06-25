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

  // Obtém uma lista de produtos com base numa lista de IDs.
  Stream<List<ProductModel>> getProductsByIds(List<String> productIds) {
    if (productIds.isEmpty) {
      return Stream.value([]);
    }

    // Filtra IDs válidos (não nulos e não vazios)
    final validIds = productIds.where((id) => id.isNotEmpty).toList();
    if (validIds.isEmpty) {
      return Stream.value([]);
    }

    try {
      // O Firestore tem um limite de 30 elementos para queries com 'in'.
      // Dividimos a lista em pedaços de 10 para ser mais seguro.
      final List<Stream<List<ProductModel>>> streams = [];
      for (var i = 0; i < validIds.length; i += 10) {
        final sublist = validIds.sublist(i, i + 10 > validIds.length ? validIds.length : i + 10);
        streams.add(_db
            .collectionGroup('products')
            .where(FieldPath.documentId, whereIn: sublist)
            .snapshots()
            .map((snapshot) => snapshot.docs
                .map((doc) => ProductModel.fromFirestore(doc))
                .toList())
            .handleError((error) {
              print('Erro ao obter produtos por IDs: $error');
              return <ProductModel>[];
            }));
      }
      
      // Combinar os resultados de todas as streams
      return streams.length == 1 ? streams.first : _combineStreams(streams);
    } catch (e) {
      print('Erro na query getProductsByIds: $e');
      return Stream.value([]);
    }
  }

  // Helper para combinar múltiplas streams
  Stream<List<T>> _combineStreams<T>(List<Stream<List<T>>> streams) {
    return Stream.multi((controller) {
      final List<List<T>> results = List.filled(streams.length, []);
      int streamsDone = 0;

      for (int i = 0; i < streams.length; i++) {
        streams[i].listen((data) {
          results[i] = data;
          if (streamsDone == streams.length) {
            controller.add(results.expand((x) => x).toList());
          }
        }, onDone: () {
          streamsDone++;
          if (streamsDone == streams.length) {
            controller.add(results.expand((x) => x).toList());
            controller.close();
          }
        });
      }
    });
  }

  // Buscar produtores que vendem produtos de uma categoria específica
  Future<List<UserModel>> getProducersByCategory(String categoria) async {
    try {
      // Primeiro, buscar produtos da categoria especificada
      final QuerySnapshot productSnapshot = await FirebaseFirestore.instance
          .collectionGroup('products')
          .where('categoria', isEqualTo: categoria)
          .get();

      // Extrair IDs únicos de produtores
      final Set<String> producerIds = productSnapshot.docs
          .map((doc) => doc['produtorId'] as String)
          .toSet();

      if (producerIds.isEmpty) {
        return [];
      }

      // Buscar produtores pelos IDs
      final List<UserModel> producers = [];
      
      // Firestore tem limite de 30 IDs por consulta 'in' (era 10, mas foi aumentado)
      final List<List<String>> chunks = [];
      final List<String> idList = producerIds.toList();
      
      for (int i = 0; i < idList.length; i += 30) {
        chunks.add(idList.sublist(
          i, 
          i + 30 > idList.length ? idList.length : i + 30
        ));
      }

      for (final chunk in chunks) {
        if (chunk.isEmpty) continue;
        final QuerySnapshot userSnapshot = await FirebaseFirestore.instance
            .collection('users')
            .where(FieldPath.documentId, whereIn: chunk)
            .get();

        producers.addAll(
          userSnapshot.docs.map((doc) => UserModel.fromFirestore(doc)).toList()
        );
      }

      return producers;
    } catch (e) {
      print('Erro ao buscar produtores por categoria: $e');
      return [];
    }
  }

  // Buscar produtores dentro de uma distância específica
  Future<List<UserModel>> getProducersWithinDistance(
    double userLat, 
    double userLon, 
    double maxDistanceKm
  ) async {
    try {
      // Buscar todos os produtores com coordenadas válidas
      final QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('tipo', isEqualTo: 'agricultor')
          .where('latitude', isNotEqualTo: null)
          .where('longitude', isNotEqualTo: null)
          .get();

      final List<UserModel> producers = [];

      for (final doc in snapshot.docs) {
        final UserModel producer = UserModel.fromFirestore(doc);
        
        if (producer.latitude != null && producer.longitude != null) {
          final double distance = _calculateDistance(
            userLat, userLon,
            producer.latitude!, producer.longitude!
          );

          if (distance <= maxDistanceKm) {
            producers.add(producer);
          }
        }
      }

      return producers;
    } catch (e) {
      print('Erro ao buscar produtores por distância: $e');
      return [];
    }
  }

  // Calcular distância entre duas coordenadas usando a fórmula de Haversine
  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const double earthRadius = 6371; // Raio da Terra em km

    final double dLat = _degreesToRadians(lat2 - lat1);
    final double dLon = _degreesToRadians(lon2 - lon1);

    final double a = 
        sin(dLat / 2) * sin(dLat / 2) +
        cos(_degreesToRadians(lat1)) * cos(_degreesToRadians(lat2)) *
        sin(dLon / 2) * sin(dLon / 2);

    final double c = 2 * asin(sqrt(a));
    
    return earthRadius * c;
  }

  double _degreesToRadians(double degrees) {
    return degrees * (pi / 180);
  }

  // Buscar todas as categorias de produtos disponíveis
  Future<List<String>> getAvailableCategories() async {
    try {
      final QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collectionGroup('products')
          .get();

      final Set<String> categories = {};
      
      for (final doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final categoria = data['categoria'] as String?;
        if (categoria != null && categoria.isNotEmpty) {
          categories.add(categoria);
        }
      }

      final List<String> sortedCategories = categories.toList()..sort();
      return sortedCategories;
    } catch (e) {
      print('Erro ao buscar categorias: $e');
      return [];
    }
  }
} 