import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:hellofarmer_app/models/order_model.dart';
import 'package:hellofarmer_app/models/product_model.dart';
import 'package:hellofarmer_app/services/firestore_service.dart';
import 'package:intl/intl.dart';

class ProducerStatsScreen extends StatefulWidget {
  const ProducerStatsScreen({super.key});

  @override
  State<ProducerStatsScreen> createState() => _ProducerStatsScreenState();
}

class _ProducerStatsScreenState extends State<ProducerStatsScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  late final String _producerId;

  bool _isLoading = true;
  double _totalRevenue = 0;
  int _totalOrders = 0;
  double _averageRating = 0;
  int _ratingCount = 0;
  List<ProductModel> _topSoldProducts = [];

  @override
  void initState() {
    super.initState();
    // Garante que o utilizador está autenticado antes de aceder ao UID
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _producerId = user.uid;
      _fetchStats();
    } else {
      // Se por algum motivo não houver user, não faz nada.
      // O AuthGate deve prevenir este caso.
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchStats() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      final orders = await _firestoreService.getProducerOrders(_producerId).first;
      final deliveredOrders =
          orders.where((order) => order.status == 'Entregue').toList();

      if (deliveredOrders.isEmpty) {
        if (mounted) setState(() => _isLoading = false);
        return;
      }

      double totalRevenue = 0;
      Map<String, int> productQuantities = {};

      for (var order in deliveredOrders) {
        for (var item in order.items) {
          if (item.product.produtorId == _producerId) {
            totalRevenue += item.product.preco * item.quantity;
            if (item.product.id != null) {
              productQuantities.update(
                item.product.id!,
                (value) => value + item.quantity,
                ifAbsent: () => item.quantity,
              );
            }
          }
        }
      }

      double totalRating = 0;
      int ratingCount = 0;
      for (var order in deliveredOrders) {
        if (order.producerRating != null) {
          totalRating += order.producerRating!;
          ratingCount++;
        }
      }
      double averageRating = ratingCount > 0 ? totalRating / ratingCount : 0;

      List<ProductModel> topProducts = [];
      if (productQuantities.isNotEmpty) {
        final sortedProductIds = productQuantities.keys.toList(growable: false)
          ..sort((k1, k2) =>
              productQuantities[k2]!.compareTo(productQuantities[k1]!));
        final topIds = sortedProductIds.take(5).toList();
        
        // Em vez de carregar todos os produtos, carregamos apenas os do produtor
        final producerProducts = await _firestoreService.getProdutos(_producerId).first;

        for (var id in topIds) {
           final product = producerProducts.firstWhere((p) => p.id == id, orElse: () => ProductModel(nome: 'Produto não encontrado', descricao: '', preco: 0, unidade: '', imagemUrl: '', produtorId: '', dataCriacao: Timestamp.now(), stock: 0));
            if (product.id != null) {
                topProducts.add(product);
            }
        }
      }

      if (mounted) {
        setState(() {
          _totalRevenue = totalRevenue;
          _totalOrders = deliveredOrders.length;
          _averageRating = averageRating;
          _ratingCount = ratingCount;
          _topSoldProducts = topProducts;
          _isLoading = false;
        });
      }
    } catch (e, stackTrace) {
      print('Erro ao carregar estatísticas: $e\n$stackTrace');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Erro ao carregar estatísticas: $e'),
              backgroundColor: Colors.red),
        );
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_totalOrders == 0) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.bar_chart_outlined, size: 80, color: Colors.grey),
            SizedBox(height: 16),
            Text('Sem dados para exibir.', style: TextStyle(fontSize: 18)),
            Text('As estatísticas aparecerão após a primeira encomenda entregue.',
                textAlign: TextAlign.center),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchStats,
      child: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _buildStatsGrid(),
          const SizedBox(height: 24),
          _buildTopProductsList(),
        ],
      ),
    );
  }

  Widget _buildStatsGrid() {
    final formatadorMoeda = NumberFormat.currency(locale: 'pt_PT', symbol: '€');

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 1.2,
      children: [
        _buildStatCard('Vendas Totais', formatadorMoeda.format(_totalRevenue), Icons.monetization_on_outlined, Colors.green),
        _buildStatCard('Nº Encomendas', _totalOrders.toString(), Icons.receipt_long_outlined, Colors.blue),
        _buildStatCard('Avaliação Média', _averageRating.toStringAsFixed(1), Icons.star_border, Colors.orange, subtext: 'de $_ratingCount avaliações'),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color, {String? subtext}) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey.shade600),
                  ),
                ),
                Icon(icon, color: color),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color)),
                if (subtext != null)
                  Text(subtext, style: TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopProductsList() {
    if (_topSoldProducts.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Produtos Mais Vendidos',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: List.generate(_topSoldProducts.length, (index) {
              final product = _topSoldProducts[index];
              final isLocal = product.imagemUrl.startsWith('assets/');
              return ListTile(
                leading: CircleAvatar(
                  backgroundImage: isLocal ? AssetImage(product.imagemUrl) as ImageProvider : NetworkImage(product.imagemUrl),
                  backgroundColor: Colors.grey.shade200,
                  child: isLocal && product.imagemUrl.isEmpty ? const Icon(Icons.broken_image, size: 20) : null,
                ),
                title: Text(product.nome, style: const TextStyle(fontWeight: FontWeight.w500)),
                trailing: Text(
                  '#${index + 1}',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Theme.of(context).primaryColor),
                ),
              );
            }),
          ),
        ),
      ],
    );
  }
} 