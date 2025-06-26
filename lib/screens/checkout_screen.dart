import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:hellofarmer_app/models/order_model.dart';
import 'package:hellofarmer_app/providers/cart_provider.dart';
import 'package:hellofarmer_app/services/firestore_service.dart';
import 'package:hellofarmer_app/services/location_service.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:hellofarmer_app/screens/order_success_screen.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _formKey = GlobalKey<FormState>();
  final _moradaController = TextEditingController();
  final _codigoPostalController = TextEditingController();
  final _firestoreService = FirestoreService();
  final _locationService = LocationService();

  // Estado do UI
  bool _isLoading = false;
  bool _isSearching = false;

  // Variáveis para a pesquisa de moradas
  Timer? _debounce;
  List<AddressSuggestion> _predictions = [];
  final FocusNode _moradaFocusNode = FocusNode();

  // NOVO: Estado para controlar o modo de entrega
  bool _isDelivery = true; 
  double _shippingCost = 5.0; // Custo de entrega padrão

  // Guardar as coordenadas de entrega
  double? _deliveryLatitude;
  double? _deliveryLongitude;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _moradaFocusNode.addListener(() {
      if (!_moradaFocusNode.hasFocus) {
        setState(() => _predictions = []);
      }
    });
  }

  @override
  void dispose() {
    _moradaController.dispose();
    _codigoPostalController.dispose();
    _debounce?.cancel();
    _moradaFocusNode.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final userDoc = await _firestoreService.getUser(user.uid).first;
      if (mounted) {
        setState(() {
          _moradaController.text = userDoc.morada;
          _codigoPostalController.text = userDoc.codigoPostal;
          _deliveryLatitude = userDoc.latitude;
          _deliveryLongitude = userDoc.longitude;
        });
      }
    }
  }

  void _onMoradaChanged(String input) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () async {
      if (input.isNotEmpty && _moradaFocusNode.hasFocus) {
        setState(() {
          _isSearching = true;
          _predictions = [];
        });
        final result = await _locationService.searchPlaces(input);
        if (mounted) {
          setState(() {
            _predictions = result;
            _isSearching = false;
          });
        }
      } else {
        if(mounted) setState(() => _predictions = []);
      }
    });
  }

  void _onPredictionSelected(AddressSuggestion prediction) async {
    FocusScope.of(context).unfocus();
    setState(() {
      _moradaController.text = prediction.description;
      _deliveryLatitude = prediction.latitude;
      _deliveryLongitude = prediction.longitude;
      _predictions = [];
      _isSearching = false;
    });

    final placemark = await _locationService.getAddressFromCoordinates(prediction.latitude, prediction.longitude);
    if (placemark != null && placemark.postalCode != null) {
      if (mounted) {
        setState(() {
          _codigoPostalController.text = placemark.postalCode!;
        });
      }
    }
  }


  Future<void> _placeOrder(CartProvider cart) async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Erro: Utilizador não autenticado.')));
      setState(() => _isLoading = false);
      return;
    }
    
    final Map<String, dynamic> shippingAddress;
    if (_isDelivery) {
      shippingAddress = {
        'morada': _moradaController.text,
        'codigoPostal': _codigoPostalController.text,
        'latitude': _deliveryLatitude,
        'longitude': _deliveryLongitude,
      };
    } else {
      // Se for levantamento, guarda uma morada especial e coordenadas nulas
      shippingAddress = {
        'morada': 'Levantamento no produtor',
        'codigoPostal': '',
        'latitude': null,
        'longitude': null,
      };
    }

    final producerIds = cart.items.values.map((item) => item.product.produtorId).toSet().toList();

    try {
      await _firestoreService.placeOrder(
        OrderModel(
          userId: user.uid,
          items: cart.items.values.toList(),
          total: cart.totalAmount + (_isDelivery ? _shippingCost : 0),
          orderDate: Timestamp.now(),
          shippingAddress: shippingAddress,
          producerIds: producerIds,
        ),
      );
      
      cart.clear();

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const OrderSuccessScreen()),
        (route) => false,
      );

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro ao realizar encomenda: $e')));
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    final cart = Provider.of<CartProvider>(context, listen: false);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Finalizar Compra'),
        backgroundColor: Theme.of(context).colorScheme.surface,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              _buildSectionHeader(context, '1', 'Método de Entrega'),
              const SizedBox(height: 16),
              _buildDeliveryToggle(),
              const SizedBox(height: 16),
              
              // O formulário de morada só aparece se for entrega
              if (_isDelivery) ...[
                _buildAddressSearch(),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _codigoPostalController,
                  decoration: const InputDecoration(labelText: 'Código Postal', prefixIcon: Icon(Icons.local_post_office_outlined)),
                  validator: (value) {
                    if (_isDelivery && (value == null || value.isEmpty)) {
                      return 'Insira o código postal.';
                    }
                    return null;
                  }
                ),
              ] else ...[
                _buildPickupInfo(),
              ],

              const SizedBox(height: 32),
              _buildSectionHeader(context, '2', 'Resumo do Pedido'),
              const SizedBox(height: 16),
              _buildOrderSummary(context, cart),
              const SizedBox(height: 32),
              _buildSectionHeader(context, '3', 'Método de Pagamento'),
              const SizedBox(height: 16),
              _buildPaymentMethod(context),
            ].animate(interval: 80.ms).fade(duration: 400.ms).slideY(begin: 0.1),
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomBar(context, cart),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String number, String title) {
    return Row(
      children: [
        CircleAvatar(
          radius: 14,
          backgroundColor: Theme.of(context).primaryColor,
          child: Text(number, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        ),
        const SizedBox(width: 12),
        Text(title, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildDeliveryToggle() {
    return SwitchListTile(
      title: const Text('Entrega ao Domicílio'),
      subtitle: Text(_isDelivery ? 'A sua encomenda será entregue na sua morada.' : 'Irá levantar a sua encomenda na banca do produtor.'),
      value: _isDelivery,
      onChanged: (bool value) {
        setState(() {
          _isDelivery = value;
          // Limpar previsões se o utilizador alternar
          if (_predictions.isNotEmpty) _predictions = [];
        });
      },
      secondary: Icon(_isDelivery ? Icons.local_shipping_outlined : Icons.store_mall_directory_outlined),
    );
  }

  Widget _buildPickupInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: Colors.blue.shade700),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'A morada para levantamento será combinada após a confirmação da encomenda.',
              style: TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddressSearch() {
    return Column(
      children: [
        TextFormField(
          controller: _moradaController,
          focusNode: _moradaFocusNode,
          onChanged: _onMoradaChanged,
          decoration: InputDecoration(
            labelText: 'Pesquisar Morada',
            prefixIcon: const Icon(Icons.location_on_outlined),
            suffixIcon: _isSearching ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : null,
          ),
          validator: (value) {
            if (_isDelivery && (value == null || value.isEmpty)) {
              return 'Insira a morada.';
            }
            return null;
          }
        ),
        if (_predictions.isNotEmpty)
          SizedBox(
            height: 200,
            child: ListView.builder(
              itemCount: _predictions.length,
              itemBuilder: (context, index) {
                final prediction = _predictions[index];
                return ListTile(
                  title: Text(prediction.description),
                  onTap: () => _onPredictionSelected(prediction),
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _buildOrderSummary(BuildContext context, CartProvider cart) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            ...cart.items.values.map((item) => Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(child: Text('${item.product.nome} (x${item.quantity})')),
                  Text('€${(item.product.preco * item.quantity).toStringAsFixed(2)}'),
                ],
              ),
            )),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Subtotal'),
                Text('€${cart.totalAmount.toStringAsFixed(2)}'),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Custo de Entrega'),
                Text(_isDelivery ? '€${_shippingCost.toStringAsFixed(2)}' : '€0.00'),
              ],
            ),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Total', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                Text('€${(cart.totalAmount + (_isDelivery ? _shippingCost : 0)).toStringAsFixed(2)}', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentMethod(BuildContext context) {
    // Por agora, um placeholder. No futuro, isto pode ser expandido.
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: Colors.grey.shade200, width: 1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const ListTile(
        leading: Icon(Icons.delivery_dining_outlined),
        title: Text('Pagamento na Entrega'),
        subtitle: Text('O pagamento será efetuado no momento da entrega.'),
      ),
    );
  }

  Widget _buildBottomBar(BuildContext context, CartProvider cart) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5)),
          ]
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('TOTAL', style: TextStyle(color: Colors.grey, fontSize: 12)),
              Text(
                '€${(cart.totalAmount + (_isDelivery ? _shippingCost : 0)).toStringAsFixed(2)}',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          ElevatedButton.icon(
            onPressed: _isLoading ? null : () => _placeOrder(cart),
            icon: _isLoading
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Icon(Icons.lock_outline),
            label: Text(_isLoading ? 'A PROCESSAR...' : 'PAGAR E FINALIZAR'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
            ),
          ),
        ],
      ),
    );
  }
} 