import 'package:flutter/material.dart';
import 'package:hellofarmer_app/models/product_model.dart';
import 'package:hellofarmer_app/models/user_model.dart';
import 'package:hellofarmer_app/providers/cart_provider.dart';
import 'package:hellofarmer_app/services/firestore_service.dart';
import 'package:provider/provider.dart';
import 'package:hellofarmer_app/models/order_model.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' as latlong;
import 'package:hellofarmer_app/screens/product_detail_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ProducerDetailScreen extends StatefulWidget {
  final String producerId;
  const ProducerDetailScreen({super.key, required this.producerId});

  @override
  State<ProducerDetailScreen> createState() => _ProducerDetailScreenState();
}

class _ProducerDetailScreenState extends State<ProducerDetailScreen> {
  final MapController _mapController = MapController();
  List<Marker> _markers = [];

  void _updateMapMarker(UserModel producer) {
    if (producer.latitude != null && producer.longitude != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            _markers = [
              Marker(
                width: 80.0,
                height: 80.0,
                point: latlong.LatLng(producer.latitude!, producer.longitude!),
                child: Column(
                  children: [
                    Icon(Icons.location_pin, color: Theme.of(context).primaryColor, size: 40),
                    Text(producer.nome, style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, backgroundColor: Colors.white.withOpacity(0.7))),
                  ],
                )
              ),
            ];
          });
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final firestoreService = FirestoreService();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Perfil do Produtor'),
        actions: [
          _buildFavoriteProducerButton(context, firestoreService),
          IconButton(
            icon: const Icon(Icons.qr_code),
            onPressed: () => _showQRCode(context),
            tooltip: 'QR Code do Produtor',
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Secção de cabeçalho com os dados do produtor
            StreamBuilder<UserModel>(
              stream: firestoreService.getUser(widget.producerId),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                final producer = snapshot.data!;
                
                // Só atualiza o mapa se os marcadores estão vazios (primeira vez)
                if (_markers.isEmpty) {
                  _updateMapMarker(producer);
                }
                
                return _buildProducerHeader(context, producer);
              },
            ),
            
            // Mapa com localização do produtor
            StreamBuilder<UserModel>(
              stream: firestoreService.getUser(widget.producerId),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const SizedBox.shrink();
                final producer = snapshot.data!;
                
                if (producer.latitude == null || producer.longitude == null) {
                  return const SizedBox.shrink();
                }
                
                return _buildLocationMap(producer);
              },
            ),
            
            const Divider(height: 1),
            // Secção da lista de produtos
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'Produtos Disponíveis',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            _buildProductsList(firestoreService),
            const Divider(height: 1),
            // Secção de Avaliações
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'Avaliações',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            _buildReviewsList(firestoreService),
          ],
        ),
      ),
    );
  }

  Widget _buildFavoriteProducerButton(BuildContext context, FirestoreService firestoreService) {
    final authUser = FirebaseAuth.instance.currentUser;
    // Se não houver utilizador logado, não mostra o botão.
    if (authUser == null) return const SizedBox.shrink();

    return StreamBuilder<UserModel>(
      stream: firestoreService.getUser(authUser.uid),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox.shrink();

        final user = snapshot.data!;
        // Um produtor não se pode favoritar a si mesmo.
        if (user.tipo == 'agricultor') return const SizedBox.shrink();

        final isFavorite = user.favoriteProducers.contains(widget.producerId);

        return IconButton(
          tooltip: isFavorite ? 'Remover dos favoritos' : 'Adicionar aos favoritos',
          icon: Icon(
            isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
            color: isFavorite ? Colors.redAccent : null,
          ),
          onPressed: () {
            if (isFavorite) {
              firestoreService.removerProdutorDosFavoritos(user.uid, widget.producerId);
            } else {
              firestoreService.addProdutorAosFavoritos(user.uid, widget.producerId);
            }
          },
        );
      },
    );
  }

  Widget _buildProducerHeader(BuildContext context, UserModel producer) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          CircleAvatar(
            radius: 40,
            child: const Icon(Icons.storefront, size: 40),
          ),
          const SizedBox(height: 8),
          Text(producer.nome, style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 4),
          Text(producer.morada),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton.icon(
                onPressed: () => _showQRCode(context),
                icon: const Icon(Icons.qr_code, size: 18),
                label: const Text('QR Code'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLocationMap(UserModel producer) {
    return Container(
      height: 200,
      margin: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: _buildMapWidget(producer),
      ),
    );
  }

  Widget _buildMapWidget(UserModel producer) {
    try {
      return FlutterMap(
        mapController: _mapController,
        options: MapOptions(
          initialCenter: latlong.LatLng(producer.latitude!, producer.longitude!),
          initialZoom: 14.0,
        ),
        children: [
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'com.example.hellofarmer_app',
          ),
          MarkerLayer(markers: _markers),
        ],
      );
    } catch (e) {
      // Fallback se o Google Maps não estiver disponível
      return Container(
        color: Colors.grey.shade100,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.map_outlined, size: 50, color: Colors.grey.shade400),
            const SizedBox(height: 8),
            Text(
              'Mapa indisponível',
              style: TextStyle(color: Colors.grey.shade600),
            ),
            Text(
              '${producer.latitude!.toStringAsFixed(4)}, ${producer.longitude!.toStringAsFixed(4)}',
              style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
            ),
          ],
        ),
      );
    }
  }

  void _showQRCode(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('QR Code do Produtor'),
        content: SizedBox(
          width: 200,
          height: 200,
          child: QrImageView(
            data: 'producer:${widget.producerId}',
            version: QrVersions.auto,
            size: 200.0,
            backgroundColor: Colors.white,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Fechar'),
          ),
          ElevatedButton(
            onPressed: () {
              // TODO: Implementar partilha do QR code
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Funcionalidade de partilha em desenvolvimento')),
              );
            },
            child: const Text('Partilhar'),
          ),
        ],
      ),
    );
  }

  Widget _buildProductsList(FirestoreService firestoreService) {
    return StreamBuilder<List<ProductModel>>(
      stream: firestoreService.getProdutos(widget.producerId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('Este produtor ainda não tem produtos à venda.'));
        }

        final products = snapshot.data!;
        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: products.length,
          itemBuilder: (context, index) {
            return _buildProductCard(context, products[index]);
          },
        );
      },
    );
  }

  Widget _buildProductCard(BuildContext context, ProductModel product) {
    final bool isAvailable = product.stock > 0;
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(MaterialPageRoute(
            builder: (context) => ProductDetailScreen(product: product),
          ));
        },
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            children: [
              // Imagem do Produto
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: SizedBox(
                  width: 70,
                  height: 70,
                  child: product.imagemUrl.isNotEmpty
                      ? (product.imagemUrl.startsWith('assets/')
                          ? Image.asset(
                              product.imagemUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => _buildPlaceholderImage(),
                            )
                          : Image.network(
                              product.imagemUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => _buildPlaceholderImage(),
                            ))
                      : _buildPlaceholderImage(),
                ),
              ),
              const SizedBox(width: 16),
              // Informação do Produto
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.nome,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text('€${product.preco.toStringAsFixed(2)} / ${product.unidade}'),
                    const SizedBox(height: 4),
                    Text(
                      isAvailable ? 'Disponível: ${product.stock.toStringAsFixed(0)}' : 'Esgotado',
                      style: TextStyle(
                        color: isAvailable ? Colors.green.shade700 : Colors.red,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Ícone de Adicionar ao Carrinho
              if (isAvailable)
                IconButton(
                  icon: const Icon(Icons.add_shopping_cart),
                  color: Theme.of(context).primaryColor,
                  onPressed: () {
                    context.read<CartProvider>().addItem(product);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('${product.nome} adicionado ao carrinho!'),
                        backgroundColor: Theme.of(context).primaryColor,
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlaceholderImage() {
    return Container(
      width: 70,
      height: 70,
      color: Colors.grey.shade200,
      child: const Icon(Icons.inventory_2_outlined, color: Colors.grey),
    );
  }

  Widget _buildReviewsList(FirestoreService firestoreService) {
    return StreamBuilder<List<OrderModel>>(
      stream: firestoreService.getProducerReviews(widget.producerId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Padding(
            padding: EdgeInsets.all(16.0),
            child: Text('Este produtor ainda não tem avaliações.'),
          ));
        }

        final reviews = snapshot.data!;
        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: reviews.length,
          itemBuilder: (context, index) {
            final review = reviews[index];
            return _buildReviewItem(context, review);
          },
        );
      },
    );
  }

  Widget _buildReviewItem(BuildContext context, OrderModel review) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            StreamBuilder<UserModel>(
              stream: FirestoreService().getUser(review.userId),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const SizedBox(height: 20); // Placeholder
                }
                final consumer = snapshot.data!;
                print('Debug: Consumer name: ${consumer.nome}, UID: ${consumer.uid}'); // Debug
                return Row(
                  children: [
                    CircleAvatar(child: Text(consumer.nome.isNotEmpty ? consumer.nome.substring(0, 1).toUpperCase() : 'U')),
                    const SizedBox(width: 8),
                    Text(consumer.nome.isNotEmpty ? consumer.nome : 'Utilizador Anónimo', 
                         style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                  ],
                );
              },
            ),
            const SizedBox(height: 8),
            RatingBarIndicator(
              rating: review.producerRating ?? 0,
              itemBuilder: (context, index) => const Icon(
                Icons.star,
                color: Colors.amber,
              ),
              itemCount: 5,
              itemSize: 20.0,
            ),
            const SizedBox(height: 8),
            if (review.reviewText != null && review.reviewText!.isNotEmpty)
              Text(
                review.reviewText!,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            const SizedBox(height: 12),
            if(review.producerReplyText != null && review.producerReplyText!.isNotEmpty)
              _buildProducerReply(context, review),
          ],
        ),
      ),
    );
  }

  Widget _buildProducerReply(BuildContext context, OrderModel review) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(8),
        border: Border(left: BorderSide(color: Theme.of(context).primaryColor, width: 4))
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Resposta do produtor:', style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 4),
          Text(
            review.producerReplyText!,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
} 