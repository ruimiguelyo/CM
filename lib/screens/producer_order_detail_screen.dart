import 'package:flutter/material.dart';
import 'package:hellofarmer_app/models/order_model.dart';
import 'package:hellofarmer_app/models/user_model.dart';
import 'package:hellofarmer_app/services/firestore_service.dart';
import 'package:intl/intl.dart';

class ProducerOrderDetailScreen extends StatefulWidget {
  final OrderModel order;
  const ProducerOrderDetailScreen({super.key, required this.order});

  @override
  State<ProducerOrderDetailScreen> createState() => _ProducerOrderDetailScreenState();
}

class _ProducerOrderDetailScreenState extends State<ProducerOrderDetailScreen> {
  late String _currentStatus;
  final FirestoreService _firestoreService = FirestoreService();

  @override
  void initState() {
    super.initState();
    _currentStatus = widget.order.status;
  }

  Future<void> _updateStatus(String newStatus) async {
    try {
      await _firestoreService.updateOrderStatus(widget.order.id!, newStatus);
      setState(() {
        _currentStatus = newStatus;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Estado da encomenda atualizado para $newStatus'),
            backgroundColor: Colors.green),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Erro ao atualizar o estado: $e'),
            backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Detalhes da Encomenda'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Encomenda #${widget.order.id!.substring(0, 8)}', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 16),
            
            // Detalhes do Cliente
            _buildCustomerDetails(context),
            const SizedBox(height: 24),
            
            // Itens da Encomenda
            _buildOrderItems(context),
            const SizedBox(height: 24),

            // Mudar Estado
             _buildStatusChanger(context),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomerDetails(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: StreamBuilder<UserModel>(
          stream: _firestoreService.getUser(widget.order.userId),
          builder: (context, snapshot) {
            if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
            final customer = snapshot.data!;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Cliente', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 8),
                Text(customer.nome, style: Theme.of(context).textTheme.bodyLarge),
                Text(customer.telefone, style: Theme.of(context).textTheme.bodyLarge),
                const SizedBox(height: 8),
                Text(widget.order.shippingAddress['morada']!),
                Text(widget.order.shippingAddress['codigoPostal']!),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildOrderItems(BuildContext context) {
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
           Padding(
             padding: const EdgeInsets.only(top: 16.0, left: 16.0),
             child: Text('Produtos', style: Theme.of(context).textTheme.titleLarge),
           ),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: widget.order.items.length,
            itemBuilder: (context, index) {
              final item = widget.order.items[index];
              return ListTile(
                title: Text(item.product.nome),
                subtitle: Text('x ${item.quantity}'),
                trailing: Text('€${(item.product.preco * item.quantity).toStringAsFixed(2)}'),
              );
            },
          ),
          const Divider(height: 1),
           Padding(
             padding: const EdgeInsets.all(16.0),
             child: Row(
               mainAxisAlignment: MainAxisAlignment.spaceBetween,
               children: [
                  Text('Total', style: Theme.of(context).textTheme.titleLarge),
                  Text('€${widget.order.total.toStringAsFixed(2)}', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
               ],
             ),
           )
        ],
      ),
    );
  }

  Widget _buildStatusChanger(BuildContext context) {
    final statuses = ['Pendente', 'Em preparação', 'Enviada', 'Entregue'];
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Alterar Estado da Encomenda', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            DropdownButton<String>(
              value: _currentStatus,
              isExpanded: true,
              items: statuses.map((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
              onChanged: (newValue) {
                if (newValue != null) {
                  _updateStatus(newValue);
                }
              },
            ),
          ],
        ),
      ),
    );
  }
} 