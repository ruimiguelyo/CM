import 'package:hellofarmer_app/models/product_model.dart';

class CartItemModel {
  final String id; // Será o id do produto
  final String nome;
  final double preco;
  final String imagemUrl;
  int quantidade;

  CartItemModel({
    required this.id,
    required this.nome,
    required this.preco,
    required this.imagemUrl,
    required this.quantidade,
  });

  // Construtor para criar um item de carrinho a partir de um produto
  factory CartItemModel.fromProduct(ProductModel product) {
    return CartItemModel(
      id: product.id!,
      nome: product.nome,
      preco: product.preco,
      imagemUrl: product.imagemUrl,
      quantidade: 1, // Começa sempre com quantidade 1
    );
  }
} 