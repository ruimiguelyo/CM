import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:hellofarmer_app/models/order_model.dart';
import 'package:hellofarmer_app/services/firestore_service.dart';
import 'package:intl/intl.dart';
import 'package:hellofarmer_app/screens/producer_order_detail_screen.dart';

class ProducerOrdersScreen extends StatelessWidget {
  const ProducerOrdersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Scaffold(body: Center(child: Text("Utilizador não encontrado.")));
    }
    final firestoreService = FirestoreService();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Encomendas Recebidas'),
      ),
      body: StreamBuilder<List<OrderModel>>(
        stream: firestoreService.getProducerOrders(user.uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Ocorreu um erro: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('Ainda não recebeu nenhuma encomenda.'));
          }

          final orders = snapshot.data!;

          return ListView.builder(
            itemCount: orders.length,
            itemBuilder: (context, index) {
              final order = orders[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  leading: const Icon(Icons.receipt_outlined),
                  title: Text('Encomenda #${order.id!.substring(0, 8)}'),
                  subtitle: Text('Status: ${order.status}'),
                  trailing: Text(DateFormat('dd/MM/yyyy').format(order.orderDate.toDate())),
                  onTap: () {
                     Navigator.of(context).push(MaterialPageRoute(
                        builder: (context) => ProducerOrderDetailScreen(order: order),
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