import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:hellofarmer_app/models/order_model.dart';
import 'package:hellofarmer_app/models/user_model.dart';
import 'package:hellofarmer_app/services/firestore_service.dart';
import 'package:intl/intl.dart';
// Adicionar o ecrã de avaliação que será criado a seguir
import 'package:hellofarmer_app/screens/evaluation_screen.dart';

class OrderDetailScreen extends StatelessWidget {
  final OrderModel order;
  const OrderDetailScreen({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalhes da Encomenda'),
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

            // Mapa estático (simulação)
            _buildMapPlaceholder(context),
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

            // Estado da Encomenda
            Text('Estado da Encomenda', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            _buildStatusTracker(context, order.status),

            // Botão para avaliar a encomenda (visível apenas para consumidores e se a encomenda estiver entregue)
            _buildEvaluationButton(context),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderItems(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
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
                leading: Image.network(item.product.imagemUrl, width: 50, height: 50, fit: BoxFit.cover, 
                  errorBuilder: (context, error, stackTrace) => const Icon(Icons.broken_image),
                ),
                title: Text(item.product.nome),
                subtitle: Text('Quantidade: ${item.quantity}'),
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
                Text('Total', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                Text('€${order.total.toStringAsFixed(2)}', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildMapPlaceholder(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 16.0, left: 16.0),
            child: Text("Localização", style: Theme.of(context).textTheme.titleLarge),
          ),
          const SizedBox(height: 8),
          // Usamos uma imagem estática para simular o mapa
          Image.asset('assets/map_placeholder.png', 
            fit: BoxFit.cover, 
            width: double.infinity,
            height: 150,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                height: 150,
                color: Colors.grey[200],
                child: const Center(child: Text('Não foi possível carregar o mapa.')),
              );
            }
          ),
        ],
      ),
    );
  }

  Widget _buildStatusTracker(BuildContext context, String currentStatus) {
    final statuses = ['Pendente', 'Em preparação', 'Enviada', 'Centro de distribuição', 'Entregue'];
    int currentIndex = statuses.indexOf(currentStatus);
    if(currentIndex == -1) currentIndex = 0; // Default

    return Column(
      children: List.generate(statuses.length, (index) {
        bool isActive = index <= currentIndex;
        final bool isLast = index == statuses.length - 1;

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              children: [
                Icon(
                  isActive ? Icons.check_circle : Icons.radio_button_unchecked,
                  color: isActive ? Theme.of(context).primaryColor : Colors.grey[400],
                  size: 24,
                ),
                 if (!isLast)
                  Container(
                    width: 2,
                    height: 30, // Espaçamento entre os ícones
                    color: (index < currentIndex) ? Theme.of(context).primaryColor : Colors.grey[300],
                  ),
              ],
            ),
            const SizedBox(width: 16),
            Padding(
              padding: const EdgeInsets.only(top: 2.0),
              child: Text(
                statuses[index], 
                style: TextStyle(
                  fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                  color: isActive ? Colors.black : Colors.grey[600],
                )
              ),
            ),
          ],
        );
      }),
    );
  }

  Widget _buildEvaluationButton(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      return const SizedBox.shrink(); // Não mostra nada se não houver utilizador
    }

    return StreamBuilder<UserModel>(
      stream: FirestoreService().getUser(currentUser.uid),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox.shrink(); // Não mostra enquanto carrega ou se houver erro
        }

        final user = snapshot.data!;
        // Apenas mostra o botão se for um consumidor e a encomenda estiver entregue
        if (user.tipo == 'consumidor' && order.status == 'Entregue') {
          // Verifica se a encomenda já foi avaliada
          final bool alreadyReviewed = order.orderRating != null;
          
          return Padding(
            padding: const EdgeInsets.only(top: 24.0),
            child: ElevatedButton.icon(
              icon: Icon(alreadyReviewed ? Icons.star : Icons.star_outline),
              label: Text(alreadyReviewed ? 'Editar Avaliação' : 'Avaliar Encomenda'),
              onPressed: () {
                Navigator.of(context).push(MaterialPageRoute(
                  builder: (context) => EvaluationScreen(order: order),
                ));
              },
            ),
          );
        }
        
        return const SizedBox.shrink(); // Não mostra para produtores ou noutros estados
      },
    );
  }
} 