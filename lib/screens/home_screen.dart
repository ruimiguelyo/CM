import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:hellofarmer_app/models/user_model.dart';
import 'package:hellofarmer_app/screens/profile_screen.dart';
import 'package:hellofarmer_app/screens/qr_scanner_screen.dart';
import 'package:hellofarmer_app/screens/producer_detail_screen.dart';
import 'package:hellofarmer_app/screens/producer_orders_screen.dart';
import 'package:hellofarmer_app/services/firestore_service.dart';
import 'package:hellofarmer_app/providers/cart_provider.dart';
import 'package:hellofarmer_app/screens/cart_screen.dart';
import 'package:hellofarmer_app/screens/all_products_screen.dart';
import 'package:provider/provider.dart';
import 'package:hellofarmer_app/widgets/custom_badge.dart';
import 'package:hellofarmer_app/services/auth_repository.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final FirestoreService _firestoreService = FirestoreService();

  @override
  Widget build(BuildContext context) {
    final authUser = FirebaseAuth.instance.currentUser;

    if (authUser == null) {
      // Caso de segurança, não deveria acontecer por causa do AuthGate
      return const Scaffold(body: Center(child: Text("Utilizador não autenticado.")));
    }

    return StreamBuilder<UserModel>(
      stream: _firestoreService.getUser(authUser.uid),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        final user = snapshot.data!;

        return Scaffold(
          appBar: AppBar(
            title: const Text('HelloFarmer'),
            actions: [
              // Apenas mostra o ícone do carrinho se for um consumidor
              if (user.tipo == 'consumidor')
                Consumer<CartProvider>(
                  builder: (context, cart, child) => CustomBadge(
                    value: cart.itemCount.toString(),
                    child: IconButton(
                      icon: const Icon(Icons.shopping_cart),
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (context) => const CartScreen()),
                        );
                      },
                    ),
                  ),
                ),
              IconButton(
                icon: const Icon(Icons.person),
                onPressed: () {
                  Navigator.of(context).push(MaterialPageRoute(
                    builder: (context) => const ProfileScreen(),
                  ));
                },
              ),
              IconButton(
                icon: const Icon(Icons.logout),
                onPressed: () {
                  FirebaseAuth.instance.signOut();
                },
              ),
            ],
          ),
          body: _buildBody(context, user),
          // Apenas mostra o botão flutuante se for um consumidor
          floatingActionButton: user.tipo == 'consumidor'
              ? FloatingActionButton.extended(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (context) => const AllProductsScreen()),
                    );
                  },
                  label: const Text('Ver Produtos'),
                  icon: const Icon(Icons.shopping_basket_outlined),
                )
              : null,
        );
      },
    );
  }

  Widget _buildBody(BuildContext context, UserModel user) {
    if (user.tipo == 'consumidor') {
      // Mostra a lista de produtores para o consumidor
      final firestoreService = FirestoreService();
      return StreamBuilder<List<UserModel>>(
        stream: firestoreService.getAgricultores(),
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
                        builder: (context) =>
                            ProducerDetailScreen(producerId: agricultor.uid),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      );
    } else {
      // Mostra um dashboard simples para o produtor
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Bem-vindo, ${user.nome}!'),
            const SizedBox(height: 8),
            const Text('Esta é a sua área de produtor.'),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).push(MaterialPageRoute(
                  builder: (context) => const ProducerOrdersScreen(),
                ));
              },
              child: const Text('Ver Encomendas Recebidas'),
            ),
          ],
        ),
      );
    }
  }
}

