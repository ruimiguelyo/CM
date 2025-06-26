import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:hellofarmer_app/models/order_model.dart';
import 'package:hellofarmer_app/services/firestore_service.dart';
import 'package:intl/intl.dart';
import 'package:hellofarmer_app/screens/order_detail_screen.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return _buildLoginPrompt(context);
    }

    return Material(
      child: Column(
        children: [
          TabBar(
            controller: _tabController,
            labelColor: Theme.of(context).primaryColor,
            unselectedLabelColor: Colors.grey,
            indicatorColor: Theme.of(context).primaryColor,
            tabs: const [
              Tab(text: 'ATIVAS'),
              Tab(text: 'ENTREGUES'),
            ],
          ),
          Expanded(
            child: StreamBuilder<List<OrderModel>>(
              stream: FirestoreService().getUserOrders(user.uid),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Ocorreu um erro: ${snapshot.error}'));
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return _buildEmptyOrders(context);
                }

                final orders = snapshot.data!;
                final activeOrders = orders.where((o) => o.status != 'Entregue').toList();
                final deliveredOrders = orders.where((o) => o.status == 'Entregue').toList();

                return TabBarView(
                  controller: _tabController,
                  children: [
                    _buildOrderList(context, activeOrders, 'Nenhuma encomenda ativa de momento.'),
                    _buildOrderList(context, deliveredOrders, 'Ainda não tem encomendas entregues.'),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderList(BuildContext context, List<OrderModel> orders, String emptyMessage) {
    if (orders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.receipt_long_outlined, size: 60, color: Colors.grey),
            const SizedBox(height: 16),
            Text(emptyMessage, style: Theme.of(context).textTheme.titleMedium),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: orders.length,
      itemBuilder: (context, index) {
        return _buildOrderCard(context, orders[index])
            .animate()
            .fade(delay: (100 * index).ms, duration: 400.ms)
            .slideY(begin: 0.2, curve: Curves.easeOut);
      },
    );
  }
  
  Widget _buildOrderCard(BuildContext context, OrderModel order) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: Colors.grey.shade200, width: 1),
        borderRadius: BorderRadius.circular(12),
      ),
      margin: const EdgeInsets.only(bottom: 16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => Navigator.of(context).push(MaterialPageRoute(
          builder: (context) => OrderDetailScreen(order: order),
        )),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Encomenda #${order.id!.substring(0, 8)}',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    '€${order.total.toStringAsFixed(2)}',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                DateFormat('d MMMM y, HH:mm').format(order.orderDate.toDate()),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey),
              ),
              const Divider(height: 24),
              Row(
                children: [
                  ..._buildProductAvatars(order.items),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      order.items.map((i) => i.product.nome).join(', '),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerRight,
                child: Chip(
                  label: Text(order.status),
                  backgroundColor: _getStatusColor(order.status).withOpacity(0.1),
                  labelStyle: TextStyle(color: _getStatusColor(order.status), fontWeight: FontWeight.bold),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildProductAvatars(List<dynamic> items) {
    return List.generate(items.length > 3 ? 3 : items.length, (index) {
      return Align(
        widthFactor: 0.7,
        child: CircleAvatar(
          radius: 15,
          backgroundImage: NetworkImage(items[index].product.imagemUrl),
          backgroundColor: Colors.grey.shade200,
        ),
      );
    });
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Entregue':
        return Colors.green;
      case 'Enviada':
      case 'Centro de distribuição':
        return Colors.orange;
      case 'Pendente':
      case 'Em preparação':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  Widget _buildLoginPrompt(BuildContext context) {
    return const Center(child: Text('Por favor, faça login para ver as suas encomendas.'));
  }

  Widget _buildEmptyOrders(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.receipt_long_outlined, size: 80, color: Colors.grey),
          const SizedBox(height: 24),
          Text(
            'Ainda não fez encomendas',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            'As suas encomendas aparecerão aqui.',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.grey),
          ),
        ],
      ),
    );
  }
} 