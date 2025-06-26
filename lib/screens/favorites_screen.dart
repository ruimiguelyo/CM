import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:hellofarmer_app/models/product_model.dart';
import 'package:hellofarmer_app/models/user_model.dart';
import 'package:hellofarmer_app/services/firestore_service.dart';
import 'package:hellofarmer_app/screens/product_detail_screen.dart';
import 'package:provider/provider.dart';
import 'package:hellofarmer_app/providers/cart_provider.dart';

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final firestoreService = FirestoreService();
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Favoritos')),
        body: const Center(child: Text('Por favor, faça login para ver os seus favoritos.')),
      );
    }

    return StreamBuilder<UserModel>(
      stream: firestoreService.getUser(user.uid),
      builder: (context, userSnapshot) {
        if (userSnapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        
        if (userSnapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.grey),
                const SizedBox(height: 16),
                Text('Erro ao carregar favoritos: ${userSnapshot.error}'),
              ],
            ),
          );
        }

        if (!userSnapshot.hasData) {
          return const Center(child: Text('Dados do utilizador não encontrados.'));
        }

        final favoriteIds = userSnapshot.data!.favoritos;

        if (favoriteIds.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.favorite_border, size: 64, color: Colors.grey.shade400),
                const SizedBox(height: 16),
                const Text(
                  'Ainda não tem produtos favoritos.',
                  style: TextStyle(fontSize: 18),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Explore produtos e adicione aos seus favoritos!',
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
          );
        }
        
        return StreamBuilder<List<ProductModel>>(
          stream: firestoreService.getAllProducts(),
          builder: (context, productSnapshot) {
            if (productSnapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (productSnapshot.hasError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, size: 64, color: Colors.grey),
                    const SizedBox(height: 16),
                    Text('Erro ao carregar produtos: ${productSnapshot.error}'),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        // Força um rebuild do widget
                        (context as Element).markNeedsBuild();
                      },
                      child: const Text('Tentar Novamente'),
                    ),
                  ],
                ),
              );
            }

            final allProducts = productSnapshot.data ?? [];
            final products = allProducts.where((product) => favoriteIds.contains(product.id)).toList();

            if (products.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.favorite_border, size: 64, color: Colors.grey.shade400),
                    const SizedBox(height: 16),
                    const Text(
                      'Ainda não tem produtos favoritos.',
                      style: TextStyle(fontSize: 18),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Explore produtos e adicione aos seus favoritos!',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: products.length,
              itemBuilder: (context, index) {
                final product = products[index];
                return _buildFavoriteItem(context, product);
              },
            );
          },
        );
      },
    );
  }

  Widget _buildFavoriteItem(BuildContext context, ProductModel product) {
    final cart = context.read<CartProvider>();
    final firestoreService = FirestoreService();
    final userId = FirebaseAuth.instance.currentUser!.uid;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(MaterialPageRoute(
            builder: (context) => ProductDetailScreen(product: product),
          ));
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: SizedBox(
                  width: 80,
                  height: 80,
                  child: product.imagemUrl.startsWith('assets/')
                      ? Image.asset(
                          product.imagemUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => _buildErrorIcon(),
                        )
                      : Image.network(
                          product.imagemUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => _buildErrorIcon(),
                        ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.nome, 
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${product.preco.toStringAsFixed(2)} € / ${product.unidade}',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Theme.of(context).primaryColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      product.stock > 0 ? 'Disponível: ${product.stock.toStringAsFixed(0)}' : 'Esgotado',
                      style: TextStyle(
                        color: product.stock > 0 ? Colors.green : Colors.red,
                        fontWeight: FontWeight.w500,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: product.stock > 0 ? () {
                          cart.addItem(product);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('${product.nome} adicionado ao carrinho!'),
                              duration: const Duration(seconds: 2),
                            ),
                          );
                        } : null,
                        icon: Icon(product.stock > 0 ? Icons.add_shopping_cart : Icons.remove_shopping_cart),
                        label: Text(product.stock > 0 ? 'Adicionar ao carrinho' : 'Esgotado'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: product.stock > 0 ? Theme.of(context).primaryColor : Colors.grey,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                        ),
                      ),
                    )
                  ],
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.favorite, color: Colors.redAccent),
                onPressed: () async {
                  await firestoreService.removerProdutoDosFavoritos(userId, product.id!);
                  // Não é necessário setState, o StreamBuilder do user irá reconstruir
                  if(context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('${product.nome} removido dos favoritos!'),
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorIcon() {
    return Container(
      width: 80,
      height: 80,
      color: Colors.grey.shade200,
      child: const Icon(Icons.broken_image, color: Colors.grey),
    );
  }
} 