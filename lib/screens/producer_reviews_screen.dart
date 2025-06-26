import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:hellofarmer_app/models/order_model.dart';
import 'package:hellofarmer_app/models/user_model.dart';
import 'package:hellofarmer_app/services/firestore_service.dart';

class ProducerReviewsScreen extends StatelessWidget {
  const ProducerReviewsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final firestoreService = FirestoreService();
    final producerId = FirebaseAuth.instance.currentUser!.uid;

    return StreamBuilder<List<OrderModel>>(
      stream: firestoreService.getProducerReviews(producerId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Text('Ainda não recebeu nenhuma avaliação.', style: TextStyle(fontSize: 16)),
            ),
          );
        }
        final reviews = snapshot.data!;
        return ListView.builder(
          itemCount: reviews.length,
          itemBuilder: (context, index) {
            final review = reviews[index];
            return _buildReviewCard(context, review, firestoreService);
          },
        );
      },
    );
  }

  Widget _buildReviewCard(BuildContext context, OrderModel review, FirestoreService service) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            StreamBuilder<UserModel>(
              stream: service.getUser(review.userId),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Text('A avaliar por...', style: TextStyle(fontStyle: FontStyle.italic));
                final consumer = snapshot.data!;
                return Row(
                  children: [
                    CircleAvatar(child: Text(consumer.nome.isNotEmpty ? consumer.nome.substring(0, 1).toUpperCase() : 'U')),
                    const SizedBox(width: 8),
                    Text(consumer.nome.isNotEmpty ? consumer.nome : 'Utilizador Anónimo', 
                         style: const TextStyle(fontWeight: FontWeight.bold)),
                  ],
                );
              }
            ),
            const SizedBox(height: 8),
            RatingBarIndicator(
              rating: review.producerRating ?? 0,
              itemBuilder: (context, index) => const Icon(Icons.star, color: Colors.amber),
              itemCount: 5,
              itemSize: 20.0,
            ),
            const SizedBox(height: 8),
            if (review.reviewText != null && review.reviewText!.isNotEmpty)
              Text(review.reviewText!, style: Theme.of(context).textTheme.bodyLarge),
            const Divider(),
            if (review.producerReplyText != null && review.producerReplyText!.isNotEmpty)
              _buildProducerReply(context, review)
            else
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  child: const Text('RESPONDER'),
                  onPressed: () => _showReplyDialog(context, review, service),
                ),
              ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildProducerReply(BuildContext context, OrderModel review) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('A sua resposta:', style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 4),
        Text(review.producerReplyText!, style: Theme.of(context).textTheme.bodyMedium),
      ],
    );
  }

  void _showReplyDialog(BuildContext context, OrderModel review, FirestoreService service) {
    final replyController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Responder à Avaliação'),
          content: TextField(
            controller: replyController,
            autofocus: true,
            decoration: const InputDecoration(hintText: 'Escreva a sua resposta...'),
            maxLines: 3,
          ),
          actions: [
            TextButton(
              child: const Text('Cancelar'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            ElevatedButton(
              child: const Text('Enviar'),
              onPressed: () async {
                if (replyController.text.isNotEmpty) {
                  await service.submitProducerReply(review.id!, replyController.text);
                  Navigator.of(context).pop();
                }
              },
            ),
          ],
        );
      },
    );
  }
} 