import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:hellofarmer_app/models/order_model.dart';
import 'package:hellofarmer_app/providers/cart_provider.dart';
import 'package:hellofarmer_app/services/firestore_service.dart';
import 'package:hellofarmer_app/services/location_service.dart';
import 'package:provider/provider.dart';

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
    
    final shippingAddress = {
      'morada': _moradaController.text,
      'codigoPostal': _codigoPostalController.text,
    };

    final producerIds = cart.items.values.map((item) => item.product.produtorId).toSet().toList();

    try {
      await _firestoreService.placeOrder(
        OrderModel(
          userId: user.uid,
          items: cart.items.values.toList(),
          total: cart.totalAmount,
          orderDate: Timestamp.now(),
          shippingAddress: shippingAddress,
          producerIds: producerIds,
          deliveryLatitude: _deliveryLatitude,
          deliveryLongitude: _deliveryLongitude,
        ),
      );
      
      cart.clear();
      Navigator.of(context).popUntil((route) => route.isFirst);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Encomenda realizada com sucesso!'), backgroundColor: Colors.green),
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
              _buildSectionHeader(context, '1', 'Endereço de Entrega'),
              const SizedBox(height: 16),
              _buildAddressSearch(),
              const SizedBox(height: 16),
              TextFormField(
                controller: _codigoPostalController,
                decoration: const InputDecoration(labelText: 'Código Postal', prefixIcon: Icon(Icons.local_post_office_outlined)),
                validator: (value) => value!.isEmpty ? 'Insira o código postal.' : null,
              ),
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
          validator: (value) => value!.isEmpty ? 'Insira a morada.' : null,
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
        side: BorderSide(color: Colors.grey.shade200, width: 1),
        borderRadius: BorderRadius.circular(12),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          ...cart.items.values.map((item) {
            return ListTile(
              leading: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: Image.network(item.product.imagemUrl, width: 40, height: 40, fit: BoxFit.cover),
              ),
              title: Text(item.product.nome),
              subtitle: Text('x${item.quantity}'),
              trailing: Text('€${(item.product.preco * item.quantity).toStringAsFixed(2)}'),
            );
          }),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Total', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                Text(
                  '€${cart.totalAmount.toStringAsFixed(2)}',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          )
        ],
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
      padding: const EdgeInsets.all(16).copyWith(bottom: 16 + MediaQuery.of(context).padding.bottom),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
        border: Border(top: BorderSide(color: Colors.grey.shade200, width: 1)),
      ),
      child: ElevatedButton.icon(
        icon: _isLoading ? const SizedBox.shrink() : const Icon(Icons.check_circle_outline_rounded),
        label: _isLoading
            ? const SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
              )
            : const Text('Confirmar Encomenda'),
        onPressed: _isLoading ? null : () => _placeOrder(cart),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
      ),
    );
  }
} 