import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:hellofarmer_app/models/order_model.dart';
import 'package:hellofarmer_app/models/user_model.dart';
import 'package:hellofarmer_app/services/firestore_service.dart';
import 'package:intl/intl.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:hellofarmer_app/services/location_service.dart';
// Adicionar o ecrã de avaliação que será criado a seguir
import 'package:hellofarmer_app/screens/evaluation_screen.dart';

class OrderDetailScreen extends StatefulWidget {
  final OrderModel order;
  const OrderDetailScreen({super.key, required this.order});

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  final LocationService _locationService = LocationService();
  GoogleMapController? _mapController;
  Set<Marker> _markers = {};
  LatLng? _deliveryLocation;

  @override
  void initState() {
    super.initState();
    _initializeDeliveryLocation();
  }

  void _initializeDeliveryLocation() async {
    try {
      // Usa as coordenadas de entrega guardadas na encomenda
      if (widget.order.deliveryLatitude != null && widget.order.deliveryLongitude != null) {
        _deliveryLocation = LatLng(widget.order.deliveryLatitude!, widget.order.deliveryLongitude!);
      } else {
        // Fallback para uma localização padrão se não houver coordenadas
        _deliveryLocation = const LatLng(39.5, -8.0); 
      }
      
      if (mounted) {
        setState(() {
          _markers = {
            Marker(
              markerId: const MarkerId('delivery'),
              position: _deliveryLocation!,
              infoWindow: InfoWindow(
                title: 'Local de Entrega',
                snippet: widget.order.shippingAddress['morada'],
              ),
              icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
            ),
          };
        });
      }
    } catch (e) {
      print('Erro ao configurar localização de entrega: $e');
    }
  }

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
            Text('Encomenda #${widget.order.id!.substring(0, 8)}', style: Theme.of(context).textTheme.headlineSmall),
            Text(DateFormat('d MMMM y, HH:mm').format(widget.order.orderDate.toDate())),
            const SizedBox(height: 24),
            
            // Itens da Encomenda
            _buildOrderItems(context),
            const SizedBox(height: 24),

            // Mapa de entrega
            _buildDeliveryMap(context),
            const SizedBox(height: 24),
            
            // Morada de Entrega
            Text('Morada de Entrega', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  '${widget.order.shippingAddress['morada']}\n${widget.order.shippingAddress['codigoPostal']}',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Estado da Encomenda
            Text('Estado da Encomenda', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            _buildStatusTracker(context, widget.order.status),

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
            itemCount: widget.order.items.length,
            separatorBuilder: (context, index) => const Divider(indent: 16, endIndent: 16),
            itemBuilder: (context, index) {
              final item = widget.order.items[index];
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
                Text('€${widget.order.total.toStringAsFixed(2)}', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildDeliveryMap(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 16.0, left: 16.0),
            child: Text("Localização de Entrega", style: Theme.of(context).textTheme.titleLarge),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 200,
            child: _deliveryLocation != null 
              ? _buildMapWidget()
              : Container(
                  color: Colors.grey[200],
                  child: const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.location_on, size: 40, color: Colors.grey),
                        SizedBox(height: 8),
                        Text('A carregar localização...'),
                      ],
                    ),
                  ),
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildMapWidget() {
    try {
      return GoogleMap(
        onMapCreated: (GoogleMapController controller) {
          _mapController = controller;
        },
        initialCameraPosition: CameraPosition(
          target: _deliveryLocation!,
          zoom: 13.0,
        ),
        markers: _markers,
        zoomControlsEnabled: true,
        compassEnabled: true,
        myLocationButtonEnabled: false,
        mapType: MapType.normal,
      );
    } catch (e) {
      // Fallback se o Google Maps não estiver disponível
      return Container(
        color: Colors.grey.shade100,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.map_outlined, size: 50, color: Colors.grey.shade400),
            const SizedBox(height: 8),
            Text(
              'Mapa indisponível',
              style: TextStyle(color: Colors.grey.shade600),
            ),
            if (_deliveryLocation != null)
              Text(
                '${_deliveryLocation!.latitude.toStringAsFixed(4)}, ${_deliveryLocation!.longitude.toStringAsFixed(4)}',
                style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
              ),
            const SizedBox(height: 8),
            Text(
              widget.order.shippingAddress['morada'] ?? '',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }
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
        if (user.tipo == 'consumidor' && widget.order.status == 'Entregue') {
          // Verifica se a encomenda já foi avaliada
          final bool alreadyReviewed = widget.order.orderRating != null;
          
          return Padding(
            padding: const EdgeInsets.only(top: 24.0),
            child: ElevatedButton.icon(
              icon: Icon(alreadyReviewed ? Icons.star : Icons.star_outline),
              label: Text(alreadyReviewed ? 'Editar Avaliação' : 'Avaliar Encomenda'),
              onPressed: () {
                Navigator.of(context).push(MaterialPageRoute(
                  builder: (context) => EvaluationScreen(order: widget.order),
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