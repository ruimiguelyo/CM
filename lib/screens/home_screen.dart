import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:hellofarmer_app/models/user_model.dart';
import 'package:hellofarmer_app/screens/profile_screen.dart';
import 'package:hellofarmer_app/screens/qr_scanner_screen.dart';
import 'package:hellofarmer_app/screens/producer_detail_screen.dart';
import 'package:hellofarmer_app/services/firestore_service.dart';
import 'package:hellofarmer_app/providers/cart_provider.dart';
import 'package:hellofarmer_app/screens/cart_screen.dart';
import 'package:hellofarmer_app/screens/all_products_screen.dart';
import 'package:provider/provider.dart';
import 'package:hellofarmer_app/widgets/custom_badge.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final FirestoreService _firestoreService = FirestoreService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Produtores'),
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code_scanner),
            tooltip: 'Ler QR Code',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const QrScannerScreen()),
              );
            },
          ),
          Consumer<CartProvider>(
            builder: (_, cart, ch) => CustomBadge(
              value: cart.itemCount.toString(),
              child: ch!,
            ),
            child: IconButton(
              icon: const Icon(Icons.shopping_cart_outlined),
              tooltip: 'O Meu Carrinho',
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => const CartScreen()),
                );
              },
            ),
          ),
          IconButton(
            icon: const Icon(Icons.person_outline),
            tooltip: 'O Meu Perfil',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const ProfileScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Sair',
            onPressed: () {
              FirebaseAuth.instance.signOut();
            },
          ),
        ],
      ),
      body: StreamBuilder<List<UserModel>>(
        stream: _firestoreService.getAgricultores(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Erro: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Text('Ainda não há produtores disponíveis.'),
            );
          }
          
          final agricultores = snapshot.data!;
          return ListView.builder(
            itemCount: agricultores.length,
            itemBuilder: (context, index) {
              final agricultor = agricultores[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  leading: const CircleAvatar(
                    child: Icon(Icons.storefront),
                  ),
                  title: Text(agricultor.nome),
                  subtitle: Text(agricultor.morada),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => ProducerDetailScreen(producerId: agricultor.uid),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (context) => const AllProductsScreen()),
          );
        },
        label: const Text('Ver Produtos'),
        icon: const Icon(Icons.shopping_basket_outlined),
      ),
    );
  }
}

