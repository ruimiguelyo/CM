import 'package:flutter/material.dart';
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestão de Produtos'),
      ),
      body: StreamBuilder<List<ProductModel>>(
        stream: _firestoreService.getProdutos(widget.userId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Ocorreu um erro: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  'Ainda não tem produtos adicionados.\nClique no botão "+" para começar a vender!',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16),
                ),
              ),
            );
          }

          final produtos = snapshot.data!;

          return ListView.builder(
            itemCount: produtos.length,
            itemBuilder: (context, index) {
              final produto = produtos[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  leading: const Icon(Icons.shopping_basket_outlined, size: 40),
                  title: Text(produto.nome, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('${produto.preco.toStringAsFixed(2)} € / ${produto.unidade}'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit_outlined),
                        tooltip: 'Editar Produto',
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => AddEditProductScreen(
                                userId: widget.userId,
                                product: produto,
                              ),
                            ),
                          );
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, color: Colors.red),
                        tooltip: 'Remover Produto',
                        onPressed: () => _showDeleteConfirmationDialog(produto),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => AddEditProductScreen(userId: widget.userId),
            ),
          );
        },
        child: const Icon(Icons.add),
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