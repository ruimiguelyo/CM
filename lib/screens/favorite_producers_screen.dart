import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:hellofarmer_app/models/user_model.dart';
import 'package:hellofarmer_app/services/firestore_service.dart';
import 'package:hellofarmer_app/screens/producer_detail_screen.dart';

class FavoriteProducersScreen extends StatelessWidget {
  const FavoriteProducersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final firestoreService = FirestoreService();
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Center(child: Text('Por favor, faça login para ver os seus favoritos.'));
    }

    return StreamBuilder<UserModel>(
      stream: firestoreService.getUser(user.uid),
      builder: (context, userSnapshot) {
        if (!userSnapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final favoriteProducerIds = userSnapshot.data!.favoriteProducers;

        if (favoriteProducerIds.isEmpty) {
          return const Center(child: Text('Ainda não tem produtores favoritos.'));
        }

        return ListView.builder(
          itemCount: favoriteProducerIds.length,
          itemBuilder: (context, index) {
            final producerId = favoriteProducerIds[index];
            return StreamBuilder<UserModel>(
              stream: firestoreService.getUser(producerId),
              builder: (context, producerSnapshot) {
                if (!producerSnapshot.hasData) {
                  return const ListTile(title: Text('A carregar produtor...'));
                }
                final producer = producerSnapshot.data!;
                return ListTile(
                  title: Text(producer.nome),
                  subtitle: Text(producer.morada),
                  onTap: () {
                    Navigator.of(context).push(MaterialPageRoute(
                      builder: (context) => ProducerDetailScreen(producerId: producer.uid),
                    ));
                  },
                );
              },
            );
          },
        );
      },
    );
  }
} 