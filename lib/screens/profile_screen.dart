import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:hellofarmer_app/models/user_model.dart';
import 'package:hellofarmer_app/screens/product_management_screen.dart';
import 'package:hellofarmer_app/services/firestore_service.dart';
import 'package:hellofarmer_app/services/auth_repository.dart';
import 'package:provider/provider.dart';
import 'package:hellofarmer_app/screens/orders_screen.dart';
import 'package:hellofarmer_app/screens/producer_orders_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final String _uid = FirebaseAuth.instance.currentUser!.uid;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('O Meu Perfil'),
      ),
      body: StreamBuilder<UserModel>(
        stream: _firestoreService.getUser(_uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Ocorreu um erro: ${snapshot.error}'));
          }
          if (!snapshot.hasData) {
            return const Center(child: Text('Utilizador não encontrado.'));
          }

          final user = snapshot.data!;

          return ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              _buildProfileHeader(user),
              const SizedBox(height: 24),
              _buildInfoCard(user),
              const SizedBox(height: 24),
              if (user.tipo == 'agricultor')
                _buildProductManagementCard(user),
              // Opção para ver as encomendas (apenas para consumidores)
              if (user.tipo == 'consumidor')
                ListTile(
                  leading: const Icon(Icons.receipt_long),
                  title: const Text('Minhas Encomendas'),
                  onTap: () {
                    Navigator.of(context).push(MaterialPageRoute(
                      builder: (context) => const OrdersScreen(),
                    ));
                  },
                ),
              const Divider(),
            ],
          );
        },
      ),
    );
  }

  Widget _buildProfileHeader(UserModel user) {
    return Column(
      children: [
        CircleAvatar(
          radius: 50,
          backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.2),
          child: const Icon(
            Icons.person,
            size: 50,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          user.nome,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        Text(user.email),
        const SizedBox(height: 8),
        Chip(
          label: Text(
            user.tipo == 'agricultor' ? 'Produtor' : 'Consumidor',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        ),
      ],
    );
  }

  Widget _buildInfoCard(UserModel user) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Informações de Contacto', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.phone),
              title: Text(user.telefone),
            ),
            ListTile(
              leading: const Icon(Icons.location_on),
              title: Text('${user.morada}, ${user.codigoPostal}'),
            ),
            ListTile(
              leading: const Icon(Icons.badge),
              title: Text('NIF: ${user.nif}'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductManagementCard(UserModel user) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        children: [
          const ListTile(
            leading: Icon(Icons.business_center),
            title: Text('Área do Produtor'),
          ),
          const Divider(height: 1, indent: 16, endIndent: 16),
          ListTile(
            leading: const Icon(Icons.inventory_2_outlined),
            title: const Text('Gerir Produtos'),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () {
              Navigator.of(context).push(MaterialPageRoute(
                builder: (context) => ProductManagementScreen(userId: user.uid),
              ));
            },
          ),
          ListTile(
            leading: const Icon(Icons.receipt_outlined),
            title: const Text('Encomendas Recebidas'),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () {
               Navigator.of(context).push(MaterialPageRoute(
                builder: (context) => const ProducerOrdersScreen(),
              ));
            },
          ),
        ],
      ),
    );
  }
} 