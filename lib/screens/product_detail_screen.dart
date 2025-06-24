import 'package:flutter/material.dart';
import 'package:hellofarmer_app/models/product_model.dart';
import 'package:hellofarmer_app/models/user_model.dart';
import 'package:hellofarmer_app/services/firestore_service.dart';
import 'package:hellofarmer_app/screens/producer_detail_screen.dart';
import 'package:hellofarmer_app/providers/cart_provider.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ProductDetailScreen extends StatelessWidget {
  final ProductModel product;

  const ProductDetailScreen({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    final FirestoreService firestoreService = FirestoreService();
    final authUser = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: Text(product.nome),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Imagem do Produto
            SizedBox(
              height: 300,
              width: double.infinity,
              child: product.imagemUrl.isNotEmpty
                  ? Image.network(
                      product.imagemUrl,
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return const Center(child: CircularProgressIndicator());
                      },
                      errorBuilder: (context, error, stackTrace) {
                        return const Icon(Icons.broken_image, size: 100, color: Colors.grey);
                      },
                    )
                  : Container(
                      color: Colors.grey[200],
                      child: const Icon(Icons.image_not_supported, size: 100, color: Colors.grey),
                    ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Nome do Produto
                  Text(
                    product.nome,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  // Preço e Unidade
                  Text(
                    '€${product.preco.toStringAsFixed(2)} / ${product.unidade}',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: Theme.of(context).primaryColor,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 16),
                  // Descrição
                  Text(
                    product.descricao,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 24),
                  const Divider(),
                  const SizedBox(height: 16),
                  // Informação do Produtor
                  StreamBuilder<UserModel>(
                    stream: firestoreService.getUser(product.produtorId),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (snapshot.hasError) {
                        return const Text('Não foi possível carregar os dados do produtor.');
                      }
                      final producer = snapshot.data!;
                      return ListTile(
                        leading: const Icon(Icons.store_mall_directory),
                        title: const Text('Vendido por', style: TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text(producer.nome, style: TextStyle(color: Theme.of(context).primaryColor, decoration: TextDecoration.underline)),
                        onTap: () {
                          Navigator.of(context).push(MaterialPageRoute(
                            builder: (context) => ProducerDetailScreen(producerId: producer.uid),
                          ));
                        },
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      // Botão de Adicionar ao Carrinho (condicional)
      bottomNavigationBar: authUser == null
          ? null
          : StreamBuilder<UserModel>(
              stream: firestoreService.getUser(authUser.uid),
              builder: (context, snapshot) {
                if (snapshot.hasData && snapshot.data!.tipo == 'consumidor') {
                  return Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.add_shopping_cart),
                      label: const Text('Adicionar ao Carrinho'),
                      onPressed: () {
                        final cart = context.read<CartProvider>();
                        cart.addItem(product);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('${product.nome} foi adicionado ao carrinho.'),
                            duration: const Duration(seconds: 2),
                            action: SnackBarAction(
                              label: 'VER',
                              onPressed: () {
                                // Navegar para o ecrã do carrinho se necessário
                              },
                            ),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        textStyle: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ),
                  );
                }
                // Retorna null ou um widget vazio para não mostrar nada
                return const SizedBox.shrink();
              },
            ),
    );
  }
} 