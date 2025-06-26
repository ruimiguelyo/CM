import 'package:flutter/material.dart';
import 'package:hellofarmer_app/providers/cart_provider.dart';
import 'package:provider/provider.dart';
import 'package:hellofarmer_app/screens/checkout_screen.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:hellofarmer_app/models/cart_item_model.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('O Meu Carrinho'),
        backgroundColor: Theme.of(context).colorScheme.surface,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
        elevation: 0,
      ),
      body: Consumer<CartProvider>(
        builder: (context, cart, child) {
          if (cart.items.isEmpty) {
            return _buildEmptyCart(context);
          }
          return Column(
            children: [
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  itemCount: cart.items.length,
                  itemBuilder: (ctx, i) {
                    final item = cart.items.values.toList()[i];
                    return _buildCartItem(context, item, cart)
                        .animate()
                        .fade(duration: 300.ms, delay: (i * 100).ms)
                        .slideX(begin: 0.2, curve: Curves.easeOut);
                  },
                ),
              ),
              _buildSummaryAndCheckout(context, cart),
            ],
          );
        },
      ),
    );
  }

  Widget _buildEmptyCart(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.shopping_cart_outlined, size: 80, color: Colors.grey),
          const SizedBox(height: 24),
          Text('O seu carrinho está vazio', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 8),
          Text(
            'Adicione produtos para os ver aqui.',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.grey),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.storefront_outlined),
            label: const Text('Explorar Produtos'),
          ),
        ],
      ).animate().fade(duration: 500.ms),
    );
  }

  Widget _buildCartItem(BuildContext context, CartItemModel item, CartProvider cart) {
    final product = item.product;
    return Dismissible(
      key: ValueKey(product.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) {
        cart.removeItem(product.id!);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${product.nome} removido do carrinho.'),
            backgroundColor: Colors.redAccent,
          ),
        );
      },
      background: Container(
        color: Colors.redAccent,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete_outline, color: Colors.white, size: 30),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            SizedBox(
              width: 80,
              height: 80,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: (product.imagemUrl.startsWith('assets/'))
                    ? Image.asset(
                        product.imagemUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            const Icon(Icons.broken_image, color: Colors.grey),
                      )
                    : Image.network(
                        product.imagemUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            const Icon(Icons.broken_image, color: Colors.grey),
                      ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(product.nome, style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 4),
                  Text(
                    '€${product.preco.toStringAsFixed(2)}',
                    style: TextStyle(color: Theme.of(context).primaryColor),
                  ),
                ],
              ),
            ),
            _buildQuantityControls(context, item, cart),
          ],
        ),
      ),
    );
  }

  Widget _buildQuantityControls(BuildContext context, CartItemModel item, CartProvider cart) {
    return Row(
      children: [
        IconButton(
          icon: const Icon(Icons.remove_circle_outline),
          onPressed: () => cart.removeSingleItem(item.product.id!),
        ),
        Text(item.quantity.toString(), style: Theme.of(context).textTheme.titleMedium),
        IconButton(
          icon: const Icon(Icons.add_circle_outline),
          onPressed: () => cart.addItem(item.product),
        ),
      ],
    );
  }

  Widget _buildSummaryAndCheckout(BuildContext context, CartProvider cart) {
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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Total', style: Theme.of(context).textTheme.titleLarge),
              Text(
                '€${cart.totalAmount.toStringAsFixed(2)}',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
              ).animate().scale(duration: 300.ms, curve: Curves.easeOut),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.of(context).push(MaterialPageRoute(
                builder: (context) => const CheckoutScreen(),
              )),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text('Finalizar Compra'),
            ),
          ),
        ],
      ),
    ).animate().slideY(begin: 0.5, duration: 400.ms, curve: Curves.easeOut);
  }
} 