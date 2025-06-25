import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:hellofarmer_app/models/order_model.dart';
import 'package:hellofarmer_app/services/firestore_service.dart';
import 'package:intl/intl.dart';
import 'package:hellofarmer_app/screens/order_detail_screen.dart';

class OrdersScreen extends StatelessWidget {
  const OrdersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final firestoreService = FirestoreService();

    return Scaffold(
      appBar: AppBar(
        title: const Text('As Minhas Encomendas'),
      ),
      body: user == null
          ? const Center(child: Text('Por favor, faça login para ver as suas encomendas.'))
          : StreamBuilder<List<OrderModel>>(
              stream: firestoreService.getUserOrders(user.uid),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Ocorreu um erro: ${snapshot.error}'));
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text('Ainda não fez nenhuma encomenda.'));
                }

                final orders = snapshot.data!;
                // Separa as encomendas com base no estado
                final activeOrders = orders.where((o) => o.status != 'Entregue').toList();
                final deliveredOrders = orders.where((o) => o.status == 'Entregue').toList();

                return ListView(
                  children: [
                    if (activeOrders.isNotEmpty)
                      _buildSectionTitle(context, 'A caminho!'),
                    ...activeOrders.map((order) => _buildOrderCard(context, order)),
                    if (deliveredOrders.isNotEmpty)
                      _buildSectionTitle(context, 'Entregues'),
                    ...deliveredOrders.map((order) => _buildOrderCard(context, order)),
                  ],
                );
              },
            ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
      child: Text(
        title,
        style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildOrderCard(BuildContext context, OrderModel order) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(MaterialPageRoute(
          builder: (context) => OrderDetailScreen(order: order),
        ));
      },
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Encomenda #${order.id!.substring(0, 8)}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(DateFormat('d MMMM y, HH:mm').format(order.orderDate.toDate())),
              const Divider(),
              // Lista de produtos na encomenda
              ...order.items.map((item) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(child: Text('${item.product.nome} (x${item.quantity})')),
                    Text('€${(item.product.preco * item.quantity).toStringAsFixed(2)}'),
                  ],
                ),
              )),
              const Divider(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Total', style: TextStyle(fontWeight: FontWeight.bold)),
                  Text('€${order.total.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
} 