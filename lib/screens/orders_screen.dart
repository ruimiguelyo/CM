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

                return ListView.builder(
                  itemCount: orders.length,
                  itemBuilder: (context, index) {
                    final order = orders[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: ListTile(
                        title: Text('Encomenda #${order.id!.substring(0, 8)}'),
                        subtitle: Text('Total: ${order.total.toStringAsFixed(2)} €'),
                        trailing: Text(DateFormat('dd/MM/yyyy').format(order.orderDate.toDate())),
                        onTap: () {
                          Navigator.of(context).push(MaterialPageRoute(
                            builder: (context) => OrderDetailScreen(order: order),
                          ));
                        },
                      ),
                    );
                  },
                );
              },
            ),
    );
  }
} 