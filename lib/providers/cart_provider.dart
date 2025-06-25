import 'package:flutter/foundation.dart';
import 'package:hellofarmer_app/models/cart_item_model.dart';
import 'package:hellofarmer_app/models/product_model.dart';

class CartProvider with ChangeNotifier {
  final Map<String, CartItemModel> _items = {};

  Map<String, CartItemModel> get items => {..._items};

  int get itemCount => _items.length;

  double get totalAmount {
    var total = 0.0;
    _items.forEach((key, cartItem) {
      total += cartItem.product.preco * cartItem.quantity;
    });
    return total;
  }

  void addItem(ProductModel product) {
    if (product.id == null || product.id!.isEmpty) {
      print('Erro: Produto sem ID válido');
      return;
    }
    
    if (_items.containsKey(product.id)) {
      if ((_items[product.id]!.quantity + 1) <= product.stock) {
        _items.update(
          product.id!,
          (existingCartItem) => existingCartItem.copyWith(
            quantity: existingCartItem.quantity + 1,
          ),
        );
      } else {
        print('Stock máximo atingido para ${product.nome}');
        return;
      }
    } else {
      if (product.stock > 0) {
        _items.putIfAbsent(
          product.id!,
          () => CartItemModel(product: product, quantity: 1),
        );
      } else {
        print('Produto ${product.nome} está esgotado.');
        return;
      }
    }
    notifyListeners();
  }

  void removeSingleItem(String productId) {
    if (!_items.containsKey(productId)) {
      return;
    }
    if (_items[productId]!.quantity > 1) {
      _items.update(
        productId,
        (existingCartItem) => existingCartItem.copyWith(
          quantity: existingCartItem.quantity - 1,
        ),
      );
    } else {
      _items.remove(productId);
    }
    notifyListeners();
  }

  void removeItem(String productId) {
    _items.remove(productId);
    notifyListeners();
  }

  void clear() {
    _items.clear();
    notifyListeners();
  }
} 