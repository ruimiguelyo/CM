import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:hellofarmer_app/models/order_model.dart';
import 'package:hellofarmer_app/services/firestore_service.dart';

class EvaluationScreen extends StatefulWidget {
  final OrderModel order;
  const EvaluationScreen({super.key, required this.order});

  @override
  State<EvaluationScreen> createState() => _EvaluationScreenState();
}

class _EvaluationScreenState extends State<EvaluationScreen> {
  final _firestoreService = FirestoreService();
  final _reviewController = TextEditingController();
  double _orderRating = 3;
  double _producerRating = 3;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Pré-preenche os campos se já houver avaliação
    if (widget.order.orderRating != null) {
      _orderRating = widget.order.orderRating!;
    }
    if (widget.order.producerRating != null) {
      _producerRating = widget.order.producerRating!;
    }
    if (widget.order.reviewText != null) {
      _reviewController.text = widget.order.reviewText!;
    }
  }

  @override
  void dispose() {
    _reviewController.dispose();
    super.dispose();
  }

  Future<void> _submitReview() async {
    setState(() => _isLoading = true);
    try {
      await _firestoreService.submitOrderReview(
        orderId: widget.order.id!,
        orderRating: _orderRating,
        producerRating: _producerRating,
        reviewText: _reviewController.text,
      );
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Avaliação enviada com sucesso!'),
        backgroundColor: Colors.green,
      ));
      Navigator.of(context).pop();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Erro ao enviar avaliação: $e'),
        backgroundColor: Colors.red,
      ));
    } finally {
      if(mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Avaliação da Encomenda')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildOrderSummary(),
            const SizedBox(height: 24),
            _buildRatingSection('Qual a sua avaliação da encomenda?', _orderRating, (rating) {
              setState(() => _orderRating = rating);
            }),
            const SizedBox(height: 24),
            _buildRatingSection('Qual a sua avaliação do produtor?', _producerRating, (rating) {
              setState(() => _producerRating = rating);
            }),
            const SizedBox(height: 24),
            TextField(
              controller: _reviewController,
              decoration: const InputDecoration(
                labelText: 'Escreva algo:',
                alignLabelWithHint: true,
                border: OutlineInputBorder(),
              ),
              maxLines: 4,
            ),
            const SizedBox(height: 16),
            TextButton.icon(
              icon: const Icon(Icons.camera_alt_outlined),
              label: const Text('Adicionar fotografias'),
              onPressed: () {
                // TODO: Implementar upload de imagens
              },
            ),
            const SizedBox(height: 16),
            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else
              ElevatedButton(
                onPressed: _submitReview,
                child: Text(widget.order.orderRating != null ? 'Atualizar avaliação!' : 'Enviar avaliação!'),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderSummary() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            ...widget.order.items.map((item) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(child: Text('${item.product.nome} (x${item.quantity})')),
                  Text('€${(item.product.preco * item.quantity).toStringAsFixed(2)}'),
                ],
              ),
            )),
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Subtotal', style: TextStyle(fontWeight: FontWeight.bold)),
                Text('€${widget.order.total.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRatingSection(String title, double initialRating, ValueChanged<double> onRatingUpdate) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        Center(
          child: RatingBar.builder(
            initialRating: initialRating,
            minRating: 1,
            direction: Axis.horizontal,
            allowHalfRating: true,
            itemCount: 5,
            itemPadding: const EdgeInsets.symmetric(horizontal: 4.0),
            itemBuilder: (context, _) => const Icon(Icons.star, color: Colors.amber),
            onRatingUpdate: onRatingUpdate,
          ),
        ),
      ],
    );
  }
} 