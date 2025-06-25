import 'package:flutter/material.dart';
import 'package:hellofarmer_app/models/product_model.dart';
import 'package:hellofarmer_app/models/user_model.dart';
import 'package:hellofarmer_app/services/firestore_service.dart';
import 'package:hellofarmer_app/screens/producer_detail_screen.dart';
import 'package:hellofarmer_app/providers/cart_provider.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_animate/flutter_animate.dart';

class ProductDetailScreen extends StatelessWidget {
  final ProductModel product;

  const ProductDetailScreen({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(context),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(context),
                  const SizedBox(height: 24),
                  _buildStockInfo(context),
                  const SizedBox(height: 24),
                  const Divider(),
                  const SizedBox(height: 16),
                  _buildProducerInfo(context),
                  const SizedBox(height: 24),
                  if (product.descricao.isNotEmpty) _buildDescription(context),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomBar(context),
    );
  }

  Widget _buildSliverAppBar(BuildContext context) {
    final authUser = FirebaseAuth.instance.currentUser;

    return SliverAppBar(
      expandedHeight: 300,
      pinned: true,
      stretch: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      foregroundColor: Theme.of(context).colorScheme.onSurface,
      flexibleSpace: FlexibleSpaceBar(
        background: Hero(
          tag: 'product_image_${product.id}',
          child: product.imagemUrl.isNotEmpty
              ? Image.network(
                  product.imagemUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const Icon(Icons.agriculture_outlined, size: 80, color: Colors.grey),
                )
              : Container(
                  color: Colors.grey.shade200,
                  child: const Icon(Icons.agriculture_outlined, size: 80, color: Colors.grey),
                ),
        ),
      ),
      actions: [
        if (authUser != null) _buildFavoriteButton(context, authUser.uid),
      ],
    );
  }

  Widget _buildFavoriteButton(BuildContext context, String userId) {
    final firestoreService = FirestoreService();
    return StreamBuilder<UserModel>(
      stream: firestoreService.getUser(userId),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox.shrink();

        final user = snapshot.data!;
        final isFavorite = user.favoritos.contains(product.id);

        return IconButton(
          icon: Icon(
            isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
            color: isFavorite ? Colors.redAccent : Theme.of(context).colorScheme.onSurface,
          ),
          onPressed: () {
            if (isFavorite) {
              firestoreService.removerProdutoDosFavoritos(user.uid, product.id!);
            } else {
              firestoreService.addProdutoAosFavoritos(user.uid, product.id!);
            }
          },
        ).animate(target: isFavorite ? 1 : 0).scale(duration: 300.ms, curve: Curves.easeOutBack);
      },
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          product.nome,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          '€${product.preco.toStringAsFixed(2)} / ${product.unidade}',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.w600,
              ),
        ),
      ],
    );
  }

  Widget _buildStockInfo(BuildContext context) {
    final bool isAvailable = product.stock > 0;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: (isAvailable ? Colors.green : Colors.red).withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isAvailable ? Icons.check_circle_outline_rounded : Icons.highlight_off_rounded,
            color: isAvailable ? Colors.green.shade700 : Colors.red.shade700,
            size: 20,
          ),
          const SizedBox(width: 8),
          Text(
            isAvailable ? 'Disponível (${product.stock.toStringAsFixed(0)} un.)' : 'Produto Esgotado',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: isAvailable ? Colors.green.shade800 : Colors.red.shade800,
                  fontWeight: FontWeight.bold,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildProducerInfo(BuildContext context) {
    return StreamBuilder<UserModel>(
      stream: FirestoreService().getUser(product.produtorId),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        if (snapshot.hasError) return const Text('Dados do produtor indisponíveis.');
        
        final producer = snapshot.data!;
        return InkWell(
          onTap: () => Navigator.of(context).push(MaterialPageRoute(
            builder: (context) => ProducerDetailScreen(producerId: producer.uid),
          )),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Row(
              children: [
                const CircleAvatar(child: Icon(Icons.storefront_outlined)),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Vendido por', style: TextStyle(color: Colors.grey)),
                      const SizedBox(height: 2),
                      Text(
                        producer.nome,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded, color: Colors.grey),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDescription(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(),
        const SizedBox(height: 16),
        Text(
          'Sobre o produto',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          product.descricao,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                height: 1.5,
              ),
        ),
      ],
    );
  }

  Widget _buildBottomBar(BuildContext context) {
    final authUser = FirebaseAuth.instance.currentUser;
    if (authUser == null) return const SizedBox.shrink();

    return StreamBuilder<UserModel>(
      stream: FirestoreService().getUser(authUser.uid),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.tipo != 'consumidor') {
          return const SizedBox.shrink();
        }

        final bool canAddToCart = product.stock > 0;
        return Container(
          padding: const EdgeInsets.all(16).copyWith(bottom: 16 + MediaQuery.of(context).padding.bottom),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, -5),
              ),
            ],
          ),
          child: ElevatedButton.icon(
            icon: Icon(canAddToCart ? Icons.add_shopping_cart_rounded : Icons.remove_shopping_cart_outlined),
            label: Text(canAddToCart ? 'Adicionar ao Carrinho' : 'Esgotado'),
            onPressed: canAddToCart
                ? () {
                    context.read<CartProvider>().addItem(product);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('${product.nome} adicionado!'),
                        behavior: SnackBarBehavior.floating,
                        backgroundColor: Theme.of(context).colorScheme.primary,
                      ),
                    );
                  }
                : null,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              backgroundColor: canAddToCart ? Theme.of(context).colorScheme.primary : Colors.grey.shade400,
              foregroundColor: Colors.white,
            ),
          ).animate().slideY(
                begin: 1,
                duration: 400.ms,
                delay: 200.ms,
                curve: Curves.easeOut,
              ),
        );
      },
    );
  }
} 