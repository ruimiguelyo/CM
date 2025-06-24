import 'package:hellofarmer_app/models/product_model.dart';

class CartItemModel {
  final ProductModel product;
  final int quantity;

  const CartItemModel({
    required this.product,
    this.quantity = 1,
  });

  CartItemModel copyWith({
    int? quantity,
  }) {
    return CartItemModel(
      product: product,
      quantity: quantity ?? this.quantity,
    );
  }

  // Converte o objeto CartItemModel para um Map
  Map<String, dynamic> toMap() {
    return {
      'product': product.toMap(),
      'quantity': quantity,
    };
  }

  // Cria um CartItemModel a partir de um Map
  factory CartItemModel.fromMap(Map<String, dynamic> map) {
    return CartItemModel(
      product: ProductModel.fromMap(map['product']),
      quantity: map['quantity'],
    );
  }
} 