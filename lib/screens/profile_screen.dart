import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:hellofarmer_app/models/user_model.dart';
import 'package:hellofarmer_app/screens/product_management_screen.dart';
import 'package:hellofarmer_app/services/firestore_service.dart';

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
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Os Meus Produtos', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            const Text('Adicione, edite ou remova os produtos disponíveis para venda na sua quinta.'),
            const SizedBox(height: 16),
            Center(
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => ProductManagementScreen(userId: user.uid),
                    ),
                  );
                },
                icon: const Icon(Icons.store),
                label: const Text('Gerir Produtos'),
              ),
            )
          ],
        ),
      ),
    );
  }
} 