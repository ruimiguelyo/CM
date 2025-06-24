import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:hellofarmer_app/models/order_model.dart';
import 'package:hellofarmer_app/providers/cart_provider.dart';
import 'package:hellofarmer_app/services/firestore_service.dart';
import 'package:provider/provider.dart';
import 'package:hellofarmer_app/screens/checkout_screen.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('O Meu Carrinho'),
      ),
      body: Consumer<CartProvider>(
        builder: (context, cart, child) {
          if (cart.items.isEmpty) {
            return child!;
          }
          return Column(
            children: [
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
                        onPressed: cart.items.isEmpty
                            ? null
                            : () {
                                Navigator.of(context).push(MaterialPageRoute(
                                  builder: (context) => const CheckoutScreen(),
                                ));
                              },
                        child: const Text('FINALIZAR COMPRA'),
                      )
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Expanded(
                child: ListView.builder(
                  itemCount: cart.items.length,
                  itemBuilder: (ctx, i) {
                    final item = cart.items.values.toList()[i];
                    final product = item.product;
                    return Card(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 15, vertical: 4),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundImage: product.imagemUrl.isNotEmpty
                              ? NetworkImage(product.imagemUrl)
                              : null,
                          child: product.imagemUrl.isEmpty
                              ? const Icon(Icons.image_not_supported)
                              : null,
                        ),
                        title: Text(product.nome),
                        subtitle: Text(
                            'Total: ${(product.preco * item.quantity).toStringAsFixed(2)}€'),
                        trailing: Text('${item.quantity} x'),
                      ),
                    );
                  },
                ),
              )
            ],
          );
        },
        child: const Center(
          child:
              Text('O seu carrinho está vazio.', style: TextStyle(fontSize: 18)),
        ),
      ),
    );
  }
} 