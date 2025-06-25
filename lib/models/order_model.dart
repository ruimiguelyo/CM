import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hellofarmer_app/models/cart_item_model.dart';

class OrderModel {
  final String? id;
  final String userId;
  final List<CartItemModel> items;
  final double total;
  final Timestamp orderDate;
  final String status;
  final Map<String, String> shippingAddress;
  final List<String> producerIds;
  final double? orderRating;
  final double? producerRating;
  final String? reviewText;
  final List<String>? reviewImageUrls;
  final String? producerReplyText;
  final Timestamp? producerReplyDate;
  final double? deliveryLatitude;
  final double? deliveryLongitude;

  OrderModel({
    this.id,
    required this.userId,
    required this.items,
    required this.total,
    required this.orderDate,
    required this.shippingAddress,
    required this.producerIds,
    this.status = 'Pendente',
    this.orderRating,
    this.producerRating,
    this.reviewText,
    this.reviewImageUrls,
    this.producerReplyText,
    this.producerReplyDate,
    this.deliveryLatitude,
    this.deliveryLongitude,
  });

  // Converte o objeto OrderModel para um formato compatível com o Firestore.
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      // Converte cada CartItemModel para um Map
      'items': items.map((item) => item.toMap()).toList(),
      'total': total,
      'orderDate': orderDate,
      'status': status,
      'shippingAddress': shippingAddress,
      'producerIds': producerIds,
      'orderRating': orderRating,
      'producerRating': producerRating,
      'reviewText': reviewText,
      'reviewImageUrls': reviewImageUrls,
      'producerReplyText': producerReplyText,
      'producerReplyDate': producerReplyDate,
      'deliveryLatitude': deliveryLatitude,
      'deliveryLongitude': deliveryLongitude,
    };
  }

  // Cria um objeto OrderModel a partir de um documento do Firestore.
  factory OrderModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

    return OrderModel(
      id: doc.id,
      userId: data['userId'],
      // Converte a lista de Maps do Firestore de volta para uma lista de CartItemModel
      items: (data['items'] as List)
          .map((itemData) => CartItemModel.fromMap(itemData))
          .toList(),
      total: (data['total'] as num).toDouble(),
      orderDate: data['orderDate'],
      status: data['status'],
      shippingAddress: Map<String, String>.from(data['shippingAddress'] ?? {}),
      producerIds: List<String>.from(data['producerIds'] ?? []),
      orderRating: (data['orderRating'] as num?)?.toDouble(),
      producerRating: (data['producerRating'] as num?)?.toDouble(),
      reviewText: data['reviewText'],
      reviewImageUrls: List<String>.from(data['reviewImageUrls'] ?? []),
      producerReplyText: data['producerReplyText'],
      producerReplyDate: data['producerReplyDate'],
      deliveryLatitude: (data['deliveryLatitude'] as num?)?.toDouble(),
      deliveryLongitude: (data['deliveryLongitude'] as num?)?.toDouble(),
    );
  }
} 