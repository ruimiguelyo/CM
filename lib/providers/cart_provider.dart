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
      total += cartItem.preco * cartItem.quantidade;
    });
    return total;
  }

  void addItem(ProductModel product) {
    if (_items.containsKey(product.id)) {
      // Apenas incrementa a quantidade
      _items.update(
        product.id!,
        (existingItem) => CartItemModel(
          id: existingItem.id,
          nome: existingItem.nome,
          preco: existingItem.preco,
          imagemUrl: existingItem.imagemUrl,
          quantidade: existingItem.quantidade + 1,
        ),
      );
    } else {
      // Adiciona um novo item
      _items.putIfAbsent(
        product.id!,
        () => CartItemModel.fromProduct(product),
      );
    }
    notifyListeners(); // Notifica os widgets que estão a ouvir
  }

  void removeItem(String productId) {
    _items.remove(productId);
    notifyListeners();
  }

  void removeSingleItem(String productId) {
    if (!_items.containsKey(productId)) return;

    if (_items[productId]!.quantidade > 1) {
      _items.update(
        productId,
        (existingItem) => CartItemModel(
          id: existingItem.id,
          nome: existingItem.nome,
          preco: existingItem.preco,
          imagemUrl: existingItem.imagemUrl,
          quantidade: existingItem.quantidade - 1,
        ),
      );
    } else {
      _items.remove(productId);
    }
    notifyListeners();
  }

  void clearCart() {
    _items.clear();
    notifyListeners();
  }
} 