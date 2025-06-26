import 'package:flutter/material.dart';
import 'package:hellofarmer_app/models/order_model.dart';
import 'package:hellofarmer_app/models/user_model.dart';
import 'package:hellofarmer_app/services/firestore_service.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' as latlong;

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
    // Adiciona a regra para não permitir alteração se já estiver 'Entregue'
    if (_currentStatus == 'Entregue') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Não é possível alterar o estado de uma encomenda já entregue.'),
            backgroundColor: Colors.orange),
      );
      return;
    }

    try {
      await _firestoreService.updateOrderStatus(widget.order.id!, newStatus);
      if (mounted) {
        setState(() {
          _currentStatus = newStatus;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Estado da encomenda atualizado para $newStatus'),
              backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Erro ao atualizar o estado: $e'),
              backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text('Detalhes da Encomenda'),
        backgroundColor: Colors.grey.shade100,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Encomenda #${widget.order.id!.substring(0, 8).toUpperCase()}', 
                 style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),
            
            // Detalhes do Cliente
            _buildCustomerDetails(context),
            const SizedBox(height: 16),
            
            // Itens da Encomenda
            _buildOrderItems(context),
            const SizedBox(height: 16),

            // Mudar Estado
             _buildStatusChanger(context),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomerDetails(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: StreamBuilder<UserModel>(
          stream: _firestoreService.getUser(widget.order.userId),
          builder: (context, snapshot) {
            if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
            final customer = snapshot.data!;
            final address = widget.order.shippingAddress;
            final isPickup = address['morada'] == 'Levantamento no produtor';
            
            final lat = address['latitude'] as double?;
            final lon = address['longitude'] as double?;
            
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Cliente', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                Text(customer.nome, style: const TextStyle(fontSize: 16)),
                const SizedBox(height: 4),
                Text(customer.telefone, style: const TextStyle(fontSize: 16, color: Colors.grey)),
                const Divider(height: 24),
                Text(address['morada'] ?? 'Morada não especificada'),
                if(!isPickup)
                  Text(address['codigoPostal'] ?? ''),
                const SizedBox(height: 16),
                if(isPickup)
                  _buildProducerLocationMap()
                else if(lat != null && lon != null)
                  _buildMapView(lat, lon, isCustomer: true),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildProducerLocationMap() {
    // Para um levantamento, precisamos da localização do produtor.
    // Assumindo que a encomenda pode ter produtos de vários produtores,
    // vamos pegar no primeiro para mostrar a sua localização como referência.
    final producerId = widget.order.producerIds.first;
    return FutureBuilder<UserModel>(
      future: _firestoreService.getUser(producerId).first,
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox.shrink();
        final producer = snapshot.data!;
        if (producer.latitude == null || producer.longitude == null) {
          return const Text('Localização do produtor não disponível.');
        }
        return _buildMapView(producer.latitude!, producer.longitude!, isCustomer: false);
      }
    );
  }

  Widget _buildMapView(double lat, double lon, {required bool isCustomer}) {
    return AspectRatio(
      aspectRatio: 16 / 9,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: FlutterMap(
          options: MapOptions(
            initialCenter: latlong.LatLng(lat, lon),
            initialZoom: 15.0,
            interactionOptions: const InteractionOptions(flags: InteractiveFlag.all & ~InteractiveFlag.rotate),
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.example.hellofarmer_app',
            ),
            MarkerLayer(markers: [
              Marker(
                width: 80.0,
                height: 80.0,
                point: latlong.LatLng(lat, lon),
                child: Icon(
                  isCustomer ? Icons.location_on : Icons.store, 
                  color: isCustomer ? Colors.red : Theme.of(context).primaryColor, 
                  size: 40
                ),
              )
            ]),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderItems(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
           Padding(
             padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
             child: Text('Produtos', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
           ),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: widget.order.items.length,
            itemBuilder: (context, index) {
              final item = widget.order.items[index];
              return ListTile(
                title: Text(item.product.nome, style: const TextStyle(fontSize: 16)),
                subtitle: Text('x ${item.quantity}'),
                trailing: Text('€${(item.product.preco * item.quantity).toStringAsFixed(2)}', style: const TextStyle(fontSize: 16)),
              );
            },
          ),
          const Divider(height: 1, indent: 16, endIndent: 16),
           Padding(
             padding: const EdgeInsets.all(16.0),
             child: Row(
               mainAxisAlignment: MainAxisAlignment.spaceBetween,
               children: [
                  const Text('Total', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  Text('€${widget.order.total.toStringAsFixed(2)}', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold, color: Theme.of(context).primaryColor)),
               ],
             ),
           )
        ],
      ),
    );
  }

  Widget _buildStatusChanger(BuildContext context) {
    final statuses = ['Pendente', 'Em preparação', 'Enviada', 'Entregue'];
    final bool isDelivered = _currentStatus == 'Entregue';

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Alterar Estado da Encomenda', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            // Envolve o Dropdown com um IgnorePointer se estiver entregue
            DropdownButtonFormField<String>(
              value: _currentStatus,
              isExpanded: true,
              decoration: InputDecoration(
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                filled: isDelivered,
                fillColor: Colors.grey.shade200,
              ),
              items: statuses.map((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
              onChanged: isDelivered ? null : (newValue) { // Desativa o onChanged
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