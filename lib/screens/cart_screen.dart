import 'package:flutter/material.dart';
import 'package:hellofarmer_app/providers/cart_provider.dart';
import 'package:provider/provider.dart';

class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Usamos um Consumer para aceder e ouvir as alterações do CartProvider
    return Scaffold(
      appBar: AppBar(
        title: const Text('O Meu Carrinho'),
      ),
      body: Consumer<CartProvider>(
        builder: (context, cart, child) {
          if (cart.items.isEmpty) {
            return child!; // Mostra o widget 'child' definido abaixo
          }
          return Column(
            children: [
              // Card com o resumo do total
              Card(
                margin: const EdgeInsets.all(15),
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Total', style: TextStyle(fontSize: 20)),
                      const Spacer(),
                      Chip(
                        label: Text(
                          '${cart.totalAmount.toStringAsFixed(2)} €',
                          style: const TextStyle(color: Colors.white),
                        ),
                        backgroundColor: Theme.of(context).primaryColor,
                      ),
                      TextButton(
                        onPressed: () {
                          // TODO: Implementar lógica de checkout
                        },
                        child: const Text('FINALIZAR COMPRA'),
                      )
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 10),
              // Lista dos itens no carrinho
              Expanded(
                child: ListView.builder(
                  itemCount: cart.items.length,
                  itemBuilder: (ctx, i) {
                    final item = cart.items.values.toList()[i];
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 4),
                      child: ListTile(
                        leading: CircleAvatar(
                          child: Padding(
                            padding: const EdgeInsets.all(5),
                            child: FittedBox(child: Text('${item.preco.toStringAsFixed(2)}€')),
                          ),
                        ),
                        title: Text(item.nome),
                        subtitle: Text('Total: ${(item.preco * item.quantidade).toStringAsFixed(2)}€'),
                        trailing: Text('${item.quantidade} x'),
                      ),
                    );
                  },
                ),
              )
            ],
          );
        },
        // Este é o widget que é mostrado quando o carrinho está vazio
        child: const Center(
          child: Text('O seu carrinho está vazio.', style: TextStyle(fontSize: 18)),
        ),
      ),
    );
  }
} 