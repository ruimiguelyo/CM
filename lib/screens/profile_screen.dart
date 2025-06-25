import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:hellofarmer_app/models/user_model.dart';
import 'package:hellofarmer_app/screens/product_management_screen.dart';
import 'package:hellofarmer_app/services/firestore_service.dart';
import 'package:hellofarmer_app/screens/orders_screen.dart';
import 'package:hellofarmer_app/screens/producer_orders_screen.dart';
import 'package:hellofarmer_app/screens/producer_reviews_screen.dart';

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
        backgroundColor: Theme.of(context).colorScheme.surface,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_outlined),
            onPressed: () {
              FirebaseAuth.instance.signOut();
              // AuthGate will handle navigation
              Navigator.of(context).popUntil((route) => route.isFirst);
            },
            tooltip: 'Terminar Sessão',
          ),
        ],
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

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(vertical: 24.0),
            child: Column(
              children: [
                _buildProfileHeader(context, user),
                const SizedBox(height: 32),
                _buildInfoCard(context, user),
                const SizedBox(height: 16),
                if (user.tipo == 'agricultor')
                  _buildProducerActions(context, user)
                else
                  _buildConsumerActions(context),
                const SizedBox(height: 24),
              ].animate().fade(duration: 400.ms),
            ),
          );
        },
      ),
    );
  }

  Widget _buildProfileHeader(BuildContext context, UserModel user) {
    return Column(
      children: [
        CircleAvatar(
          radius: 40,
          backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
          child: Text(
            user.nome.isNotEmpty ? user.nome[0].toUpperCase() : 'U',
            style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                  color: Theme.of(context).primaryColor,
                ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          user.nome,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(user.email, style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.grey.shade600)),
        const SizedBox(height: 12),
        Chip(
          label: Text(
            user.tipo == 'agricultor' ? 'Produtor' : 'Consumidor',
            style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary),
          ),
          backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        ),
      ],
    );
  }

  Widget _buildInfoCard(BuildContext context, UserModel user) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          side: BorderSide(color: Colors.grey.shade200, width: 1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Informações de Contacto', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              const Divider(),
              _buildInfoTile(context, Icons.phone_outlined, 'Telefone', user.telefone),
              _buildInfoTile(context, Icons.location_on_outlined, 'Morada', '${user.morada}, ${user.codigoPostal}'),
              _buildInfoTile(context, Icons.badge_outlined, 'NIF', user.nif),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoTile(BuildContext context, IconData icon, String title, String subtitle) {
    return ListTile(
      leading: Icon(icon, color: Theme.of(context).primaryColor),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text(subtitle, style: Theme.of(context).textTheme.bodyLarge),
      contentPadding: EdgeInsets.zero,
    );
  }
  
  Widget _buildConsumerActions(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          side: BorderSide(color: Colors.grey.shade200, width: 1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            _buildActionTile(
              context,
              icon: Icons.receipt_long_outlined,
              title: 'Minhas Encomendas',
              onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (context) => const OrdersScreen())),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProducerActions(BuildContext context, UserModel user) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          side: BorderSide(color: Colors.grey.shade200, width: 1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Text('Área do Produtor', style: Theme.of(context).textTheme.titleLarge),
            ),
            _buildActionTile(
              context,
              icon: Icons.inventory_2_outlined,
              title: 'Gerir Produtos',
              onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (context) => ProductManagementScreen(userId: user.uid))),
            ),
            _buildActionTile(
              context,
              icon: Icons.local_shipping_outlined,
              title: 'Encomendas Recebidas',
              onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (context) => const ProducerOrdersScreen())),
            ),
            _buildActionTile(
              context,
              icon: Icons.star_border_outlined,
              title: 'Minhas Avaliações',
              onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (context) => const ProducerReviewsScreen())),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionTile(BuildContext context, {required IconData icon, required String title, required VoidCallback onTap}) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title, style: Theme.of(context).textTheme.bodyLarge),
      trailing: const Icon(Icons.chevron_right_rounded, color: Colors.grey),
      onTap: onTap,
    );
  }
} 