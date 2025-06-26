import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:hellofarmer_app/models/product_model.dart';
import 'package:hellofarmer_app/screens/add_edit_product_screen.dart';
import 'package:hellofarmer_app/services/firestore_service.dart';

class ProductManagementScreen extends StatefulWidget {
  final String userId;
  const ProductManagementScreen({super.key, required this.userId});

  @override
  State<ProductManagementScreen> createState() => _ProductManagementScreenState();
}

class _ProductManagementScreenState extends State<ProductManagementScreen> {
  final FirestoreService _firestoreService = FirestoreService();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<ProductModel>>(
      stream: _firestoreService.getProdutos(widget.userId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Ocorreu um erro: ${snapshot.error}'));
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return _buildEmptyState(context);
        }

        final produtos = snapshot.data!;

        return Scaffold(
          body: GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 0.8,
            ),
            itemCount: produtos.length,
            itemBuilder: (context, index) {
              final produto = produtos[index];
              return _buildProductCard(context, produto)
                  .animate()
                  .fade(delay: (100 * index).ms, duration: 400.ms)
                  .scale(begin: const Offset(0.9, 0.9));
            },
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (context) => AddEditProductScreen(userId: widget.userId)),
            ),
            label: const Text('Adicionar'),
            icon: const Icon(Icons.add),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.inventory_2_outlined, size: 80, color: Colors.grey),
          const SizedBox(height: 24),
          Text(
            'Sem produtos na sua banca',
            style: Theme.of(context).textTheme.headlineSmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Adicione produtos para começar a vender.',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.grey),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    ).animate().fade(duration: 500.ms);
  }

  Widget _buildProductCard(BuildContext context, ProductModel produto) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: Colors.grey.shade200, width: 1),
        borderRadius: BorderRadius.circular(12),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (context) => AddEditProductScreen(userId: widget.userId, product: produto)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Container(
                color: Colors.grey.shade100,
                child: produto.imagemUrl.isNotEmpty
                    ? Image.network(produto.imagemUrl, fit: BoxFit.cover)
                    : const Icon(Icons.agriculture_outlined, size: 40, color: Colors.grey),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(produto.nome, style: Theme.of(context).textTheme.titleMedium, maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 4),
                  Text(
                    '€${produto.preco.toStringAsFixed(2)} / ${produto.unidade}',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Theme.of(context).primaryColor),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Stock: ${produto.stock.toStringAsFixed(0)}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
            // Adicionar uma linha de botões para ações rápidas
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit_outlined, size: 20),
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (context) => AddEditProductScreen(userId: widget.userId, product: produto)),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, size: 20, color: Colors.redAccent),
                    onPressed: () => _showDeleteConfirmationDialog(produto),
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirmationDialog(ProductModel product) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirmar Remoção'),
          content: Text('Tem a certeza de que deseja remover o produto "${product.nome}"? Esta ação não pode ser desfeita.'),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancelar'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Remover', style: TextStyle(color: Colors.red)),
              onPressed: () async {
                try {
                  await _firestoreService.removerProduto(widget.userId, product.id!);
                  Navigator.of(context).pop(); // Fecha o diálogo
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Produto removido com sucesso!'), backgroundColor: Colors.green),
                  );
                } catch (e) {
                  Navigator.of(context).pop(); // Fecha o diálogo
                   ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Erro ao remover o produto: $e'), backgroundColor: Colors.red),
                  );
                }
              },
            ),
          ],
        );
      },
    );
  }
} 