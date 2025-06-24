import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:hellofarmer_app/models/order_model.dart';
import 'package:hellofarmer_app/models/user_model.dart';
import 'package:hellofarmer_app/providers/cart_provider.dart';
import 'package:hellofarmer_app/services/firestore_service.dart';
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
  bool _isLoading = false;
  final _firestoreService = FirestoreService();

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final userDoc = await _firestoreService.getUser(user.uid).first;
      if (mounted) {
        _moradaController.text = userDoc.morada;
        _codigoPostalController.text = userDoc.codigoPostal;
      }
    }
  }

  @override
  void dispose() {
    _moradaController.dispose();
    _codigoPostalController.dispose();
    super.dispose();
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
      appBar: AppBar(title: const Text('Finalizar Compra')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Morada de Entrega', style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 16),
              TextFormField(
                controller: _moradaController,
                decoration: const InputDecoration(labelText: 'Morada'),
                validator: (value) =>
                    value!.isEmpty ? 'Por favor, insira a morada.' : null,
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _codigoPostalController,
                decoration: const InputDecoration(labelText: 'Código Postal'),
                validator: (value) => value!.isEmpty
                    ? 'Por favor, insira o código postal.'
                    : null,
              ),
              const SizedBox(height: 32),
              Text('Resumo do Pedido',
                  style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 16),
              ...cart.items.values.map((item) => ListTile(
                title: Text(item.product.nome),
                subtitle: Text('x${item.quantity}'),
                trailing: Text('€${(item.product.preco * item.quantity).toStringAsFixed(2)}'),
              )),
              const Divider(),
              ListTile(
                title: Text('Total', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                trailing: Text('€${cart.totalAmount.toStringAsFixed(2)}', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 32),
              Text('Método de Pagamento', style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 16),
              Card(
                child: ListTile(
                  leading: const Icon(Icons.credit_card),
                  title: const Text('MBWay (simulação)'),
                  subtitle: const Text('O pagamento será simulado.'),
                ),
              ),
              const SizedBox(height: 32),
              if (_isLoading)
                const Center(child: CircularProgressIndicator())
              else
                ElevatedButton(
                  style: ElevatedButton.styleFrom(padding: const EdgeInsets.all(16)),
                  onPressed: () => _placeOrder(cart),
                  child: const Text('Confirmar e Pagar', style: TextStyle(fontSize: 18)),
                ),
            ],
          ),
        ),
      ),
    );
  }
} 