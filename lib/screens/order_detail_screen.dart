import 'package:flutter/material.dart';
import 'package:hellofarmer_app/models/order_model.dart';
import 'package:intl/intl.dart';

class OrderDetailScreen extends StatelessWidget {
  final OrderModel order;
  const OrderDetailScreen({super.key, required this.order});

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
            // Cabeçalho
            Text('Encomenda #${order.id!.substring(0, 8)}', style: Theme.of(context).textTheme.headlineSmall),
            Text(DateFormat('d MMMM y, HH:mm').format(order.orderDate.toDate())),
            const SizedBox(height: 24),
            
            // Itens da Encomenda
            _buildOrderItems(context),
            const SizedBox(height: 24),
            
            // Morada de Entrega
            Text('Morada de Entrega', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  '${order.shippingAddress['morada']}\n${order.shippingAddress['codigoPostal']}',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Estado da Encomenda (inspirado no mockup)
            Text('Estado da Encomenda', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            _buildStatusTracker(context, order.status),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderItems(BuildContext context) {
    return Card(
      child: Column(
        children: [
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: order.items.length,
            separatorBuilder: (context, index) => const Divider(indent: 16, endIndent: 16),
            itemBuilder: (context, index) {
              final item = order.items[index];
              return ListTile(
                leading: Image.network(item.product.imagemUrl, width: 50, height: 50, fit: BoxFit.cover),
                title: Text(item.product.nome),
                subtitle: Text('Quantidade: ${item.quantity}'),
                trailing: Text('€${(item.product.preco * item.quantity).toStringAsFixed(2)}'),
              );
            },
          ),
          const Divider(),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Subtotal', style: Theme.of(context).textTheme.bodyLarge),
                Text('€${order.total.toStringAsFixed(2)}', style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold)),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildStatusTracker(BuildContext context, String currentStatus) {
    final statuses = ['Pendente', 'Em preparação', 'Enviada', 'Entregue'];
    int currentIndex = statuses.indexOf(currentStatus);
    if(currentIndex == -1) currentIndex = 0; // Default a pendente se o estado for inválido

    return Column(
      children: List.generate(statuses.length, (index) {
        bool isActive = index <= currentIndex;
        return Row(
          children: [
            Column(
              children: [
                if (index != 0)
                  Container(
                    width: 2,
                    height: 20,
                    color: isActive ? Theme.of(context).primaryColor : Colors.grey[300],
                  ),
                Icon(
                  isActive ? Icons.check_circle : Icons.radio_button_unchecked,
                  color: isActive ? Theme.of(context).primaryColor : Colors.grey[300],
                ),
                 if (index != statuses.length - 1)
                  Container(
                    width: 2,
                    height: 20,
                    color: (index < currentIndex) ? Theme.of(context).primaryColor : Colors.grey[300],
                  ),
              ],
            ),
            const SizedBox(width: 16),
            Text(statuses[index], style: TextStyle(fontWeight: isActive ? FontWeight.bold : FontWeight.normal)),
          ],
        );
      }),
    );
  }
} 