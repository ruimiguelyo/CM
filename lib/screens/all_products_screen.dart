import 'package:flutter/material.dart';
import 'package:hellofarmer_app/models/product_model.dart';
import 'package:hellofarmer_app/services/firestore_service.dart';
import 'package:hellofarmer_app/providers/cart_provider.dart';
import 'package:provider/provider.dart';
import 'package:hellofarmer_app/screens/product_detail_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hellofarmer_app/models/user_model.dart';
import 'package:flutter_animate/flutter_animate.dart';

class AllProductsScreen extends StatefulWidget {
  const AllProductsScreen({super.key});

  @override
  State<AllProductsScreen> createState() => _AllProductsScreenState();
}

class _AllProductsScreenState extends State<AllProductsScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final authUser = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Todos os Produtos'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
              decoration: InputDecoration(
                labelText: 'Pesquisar produtos...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder<List<ProductModel>>(
              stream: _firestoreService.getAllProducts(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Erro: ${snapshot.error}'));
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(
                    child: Text('Ainda não há produtos disponíveis.'),
                  );
                }

                var products = snapshot.data!;
                if (_searchQuery.isNotEmpty) {
                  products = products.where((product) {
                    return product.nome.toLowerCase().contains(_searchQuery.toLowerCase());
                  }).toList();
                }

                return GridView.builder(
                  padding: const EdgeInsets.all(10.0),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.7,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                  ),
                  itemCount: products.length,
                  itemBuilder: (context, index) {
                    final product = products[index];
                    return _buildProductCard(context, product, authUser);
                  },
                ).animate().slideY(
                      duration: 500.ms,
                      begin: 0.1,
                      curve: Curves.easeOut,
                    );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductCard(BuildContext context, ProductModel product, User? authUser) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => ProductDetailScreen(product: product),
          ),
        );
      },
      child: Card(
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        elevation: 0,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Hero(
                tag: 'product_image_${product.id}',
                child: Container(
                  color: Colors.grey.shade100,
                  child: product.imagemUrl.isNotEmpty
                      ? Image.network(
                          product.imagemUrl,
                          fit: BoxFit.cover,
                          loadingBuilder: (context, child, progress) {
                            return progress == null ? child : const Center(child: CircularProgressIndicator());
                          },
                          errorBuilder: (context, error, stackTrace) {
                            return Icon(Icons.agriculture_outlined, size: 40, color: Colors.grey.shade400);
                          },
                        )
                      : Icon(Icons.agriculture_outlined, size: 40, color: Colors.grey.shade400),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.nome,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '€${product.preco.toStringAsFixed(2)} / ${product.unidade}',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.primary,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildStockIndicator(context, product),
                      _buildAddToCartButton(context, product, authUser),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ).animate().fade(duration: 400.ms).scale(
          begin: const Offset(0.95, 0.95),
          curve: Curves.easeInOut,
        );
  }

  Widget _buildStockIndicator(BuildContext context, ProductModel product) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: (product.stock > 0 ? Colors.green : Colors.red).withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        product.stock > 0 ? 'Disponível' : 'Esgotado',
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: product.stock > 0 ? Colors.green.shade700 : Colors.red.shade700,
              fontWeight: FontWeight.bold,
            ),
      ),
    );
  }

  Widget _buildAddToCartButton(BuildContext context, ProductModel product, User? authUser) {
    return StreamBuilder<UserModel>(
      stream: _firestoreService.getUser(authUser!.uid),
      builder: (context, userSnapshot) {
        if (userSnapshot.hasData && userSnapshot.data!.tipo == 'consumidor') {
          bool canAddToCart = product.stock > 0;
          return SizedBox(
            width: 40,
            height: 40,
            child: IconButton(
              icon: Icon(
                canAddToCart ? Icons.add_shopping_cart_rounded : Icons.remove_shopping_cart_outlined,
              ),
              color: canAddToCart ? Theme.of(context).colorScheme.primary : Colors.grey,
              onPressed: canAddToCart
                  ? () {
                      try {
                        context.read<CartProvider>().addItem(product);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('${product.nome} adicionado ao carrinho!'),
                            backgroundColor: Theme.of(context).colorScheme.primary,
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Erro: $e'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    }
                  : null,
            ),
          );
        }
        return const SizedBox.shrink();
      },
    );
  }
} 