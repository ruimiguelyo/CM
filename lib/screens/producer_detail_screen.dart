import 'package:flutter/material.dart';
import 'package:hellofarmer_app/models/product_model.dart';
import 'package:hellofarmer_app/models/user_model.dart';
import 'package:hellofarmer_app/providers/cart_provider.dart';
import 'package:hellofarmer_app/services/firestore_service.dart';
import 'package:provider/provider.dart';

class ProducerDetailScreen extends StatelessWidget {
  final String producerId;
  const ProducerDetailScreen({super.key, required this.producerId});

  @override
  Widget build(BuildContext context) {
    final firestoreService = FirestoreService();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Perfil do Produtor'),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Secção de cabeçalho com os dados do produtor
            StreamBuilder<UserModel>(
              stream: firestoreService.getUser(producerId),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                final producer = snapshot.data!;
                return _buildProducerHeader(context, producer);
              },
            ),
            const Divider(height: 1),
            // Secção da lista de produtos
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'Produtos Disponíveis',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            _buildProductsList(firestoreService),
          ],
        ),
      ),
    );
  }

  Widget _buildProducerHeader(BuildContext context, UserModel producer) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          CircleAvatar(
            radius: 40,
            child: const Icon(Icons.storefront, size: 40),
          ),
          const SizedBox(height: 8),
          Text(producer.nome, style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 4),
          Text(producer.morada),
          // TODO: Adicionar mais detalhes, como descrição, horário, etc.
        ],
      ),
    );
  }

  Widget _buildProductsList(FirestoreService firestoreService) {
    return StreamBuilder<List<ProductModel>>(
      stream: firestoreService.getProdutos(producerId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('Este produtor ainda não tem produtos à venda.'));
        }

        final products = snapshot.data!;
        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: products.length,
          itemBuilder: (context, index) {
            final product = products[index];
            final cart = Provider.of<CartProvider>(context, listen: false);

            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: ListTile(
                leading: const Icon(Icons.shopping_basket_outlined, size: 40),
                title: Text(product.nome),
                subtitle: Text('${product.preco.toStringAsFixed(2)} € / ${product.unidade}'),
                trailing: IconButton(
                  icon: const Icon(Icons.add_shopping_cart),
                  color: Theme.of(context).primaryColor,
                  tooltip: 'Adicionar ao Carrinho',
                  onPressed: () {
                    cart.addItem(product);
                    ScaffoldMessenger.of(context).hideCurrentSnackBar();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('${product.nome} adicionado ao carrinho!'),
                        duration: const Duration(seconds: 2),
                        action: SnackBarAction(
                          label: 'VER',
                          onPressed: () {
                            // TODO: Navegar para o ecrã do carrinho
                          },
                        ),
                      ),
                    );
                  },
                ),
              ),
            );
          },
        );
      },
    );
  }
} 