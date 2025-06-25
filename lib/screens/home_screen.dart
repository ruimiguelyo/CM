import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:hellofarmer_app/models/user_model.dart';
import 'package:hellofarmer_app/screens/profile_screen.dart';
import 'package:hellofarmer_app/screens/producer_detail_screen.dart';
import 'package:hellofarmer_app/screens/producer_orders_screen.dart';
import 'package:hellofarmer_app/services/firestore_service.dart';
import 'package:hellofarmer_app/providers/cart_provider.dart';
import 'package:hellofarmer_app/screens/cart_screen.dart';
import 'package:hellofarmer_app/screens/all_products_screen.dart';
import 'package:hellofarmer_app/screens/sensors_demo_screen.dart';
import 'package:provider/provider.dart';
import 'package:hellofarmer_app/widgets/custom_badge.dart';
import 'package:hellofarmer_app/screens/favorites_screen.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:hellofarmer_app/services/location_service.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter/widgets.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final LocationService _locationService = LocationService();
  
  // Controller para o mapa
  final Completer<GoogleMapController> _mapController = Completer();

  // O Set<Marker> é a única coisa que precisa ser um estado para o mapa
  Set<Marker> _markers = {};

  Position? _currentPosition;
  
  // Coordenadas padrão (centro de Portugal)
  static const CameraPosition _defaultCameraPosition = CameraPosition(
    target: LatLng(39.5, -8.0),
    zoom: 7,
  );

  bool _isMapView = false;
  List<UserModel> _producers = [];
  List<UserModel> _filteredProducers = [];
  List<String> _availableCategories = [];
  String? _selectedCategory;
  double _maxDistance = 50.0; // km
  bool _isLoadingProducers = true;
  bool _isLoadingCategories = true;
  bool _showFilters = false;
  UserModel? _currentUserModel;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    // Carregamos tudo em paralelo para um arranque mais rápido
    await Future.wait([
      _initializeLocationAndMoveCamera(),
      _loadProducersAndApplyFilters(), // Combina o carregamento e o filtro inicial
      _loadCategories(),
      _loadCurrentUser(),
    ]);
  }

  // NOVO: Carrega os dados do utilizador atual uma vez
  Future<void> _loadCurrentUser() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final userModel = await _firestoreService.getUser(user.uid).first;
      if (mounted) {
        setState(() {
          _currentUserModel = userModel;
        });
      }
    }
  }

  // Combina o carregamento de produtores com a aplicação inicial de filtros
  Future<void> _loadProducersAndApplyFilters() async {
    setState(() {
      _isLoadingProducers = true;
    });
    try {
      final producers = await _firestoreService.getAgricultores().first;
      if (!mounted) return;

      setState(() {
        _producers = producers;
      });
      
      // Após carregar todos, aplicamos os filtros (distância, etc.)
      await _applyFilters();

    } catch (e) {
      print('Erro fatal ao carregar produtores: $e');
      if (mounted) {
        setState(() {
          _isLoadingProducers = false;
        });
      }
    }
  }

  Future<void> _initializeLocationAndMoveCamera() async {
    Position? userPosition;
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      final userModel = await _firestoreService.getUser(currentUser.uid).first;
      if (userModel.latitude != null && userModel.longitude != null) {
        userPosition = Position(
          latitude: userModel.latitude!,
          longitude: userModel.longitude!,
          timestamp: DateTime.now(),
          accuracy: 0.0,
          altitude: 0.0,
          altitudeAccuracy: 0.0,
          heading: 0.0,
          headingAccuracy: 0.0,
          speed: 0.0,
          speedAccuracy: 0.0,
        );
      }
    }

    if (userPosition == null) {
      try {
        userPosition = await _locationService.getCurrentLocation();
      } catch (e) {
        print('Erro ao obter localização do dispositivo: $e');
      }
    }

    if (mounted) {
      setState(() {
        _currentPosition = userPosition;
      });

      // Mover a câmara do mapa para a nova posição
      if (userPosition != null) {
        final controller = await _mapController.future;
        controller.animateCamera(
          CameraUpdate.newCameraPosition(
            CameraPosition(
              target: LatLng(userPosition.latitude, userPosition.longitude),
              zoom: 12.0, // Zoom mais apropriado para uma localização específica
            ),
          ),
        );
      }
    }
  }

  Future<void> _loadCategories() async {
    try {
      final categories = await FirestoreService().getAvailableCategories();
      if (mounted) {
        setState(() {
          _availableCategories = categories;
          _isLoadingCategories = false;
        });
      }
    } catch (e) {
      print('Erro ao carregar categorias: $e');
      if (mounted) {
        setState(() {
          _isLoadingCategories = false;
        });
      }
    }
  }

  Future<void> _applyFilters() async {
    setState(() {
      _isLoadingProducers = true;
    });

    // 1. FAZER TODO O TRABALHO ASSÍNCRONO PRIMEIRO
    List<UserModel> filtered = List.from(_producers);

    if (_selectedCategory != null) {
      final categoryProducers = await FirestoreService().getProducersByCategory(_selectedCategory!);
      final categoryIds = categoryProducers.map((p) => p.uid).toSet();
      filtered = filtered.where((p) => categoryIds.contains(p.uid)).toList();
    }

    if (_currentPosition != null) {
      filtered = filtered.where((producer) {
        if (producer.latitude == null || producer.longitude == null) {
          return true; 
        }
        final distanceInKm = _locationService.calculateDistance(
              _currentPosition!.latitude,
              _currentPosition!.longitude,
              producer.latitude!,
              producer.longitude!,
            ) / 1000;
        return distanceInKm <= _maxDistance;
      }).toList();
    }
    
    // 2. GERAR OS MARCADORES A PARTIR DOS DADOS FINAIS
    final newMarkers = _generateMarkers(filtered);

    // 3. CHAMAR SETSTATE APENAS UMA VEZ COM OS DADOS FINAIS
    if (mounted) {
      setState(() {
        _filteredProducers = filtered;
        _markers = newMarkers;
        _isLoadingProducers = false;
      });
    }
  }

  void _clearFilters() {
    setState(() {
      _selectedCategory = null;
      _maxDistance = 50.0;
    });
    // Re-aplicar filtros para voltar ao estado inicial (considerando distância)
    _applyFilters();
  }

  // Renomeado e modificado para não chamar setState
  Set<Marker> _generateMarkers(List<UserModel> producers) {
    return producers
        .where((p) => p.latitude != null && p.longitude != null)
        .map((producer) => Marker(
              markerId: MarkerId(producer.uid),
              position: LatLng(producer.latitude!, producer.longitude!),
              infoWindow: InfoWindow(
                title: producer.nome,
                snippet: 'Clique para ver detalhes',
                onTap: () {
                  Navigator.of(context).push(MaterialPageRoute(
                    builder: (context) => ProducerDetailScreen(producerId: producer.uid),
                  ));
                },
              ),
            ))
        .toSet();
  }

  Widget _buildFilterBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.filter_list, color: Colors.green.shade700),
              const SizedBox(width: 8),
              Text(
                'Filtros',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.green.shade700,
                ),
              ),
              const Spacer(),
              IconButton(
                onPressed: () {
                  setState(() {
                    _showFilters = !_showFilters;
                  });
                },
                icon: Icon(
                  _showFilters ? Icons.expand_less : Icons.expand_more,
                  color: Colors.green.shade700,
                ),
              ),
            ],
          ),
          if (_showFilters) ...[
            const SizedBox(height: 16),
            // Filtro por categoria
            Row(
              children: [
                const Icon(Icons.category, size: 20),
                const SizedBox(width: 8),
                const Text('Categoria:', style: TextStyle(fontWeight: FontWeight.w500)),
                const SizedBox(width: 8),
                Expanded(
                  child: _isLoadingCategories
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : DropdownButton<String>(
                          value: _selectedCategory,
                          hint: const Text('Todas as categorias'),
                          isExpanded: true,
                          items: [
                            const DropdownMenuItem<String>(
                              value: null,
                              child: Text('Todas as categorias'),
                            ),
                            ..._availableCategories.map((category) =>
                                DropdownMenuItem<String>(
                                  value: category,
                                  child: Text(category),
                                ),
                            ),
                          ],
                          onChanged: (value) {
                            setState(() {
                              _selectedCategory = value;
                            });
                            _applyFilters();
                          },
                        ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Filtro por distância
            Row(
              children: [
                const Icon(Icons.location_on, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Distância: ${_maxDistance.round()} km',
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                Expanded(
                  child: Slider(
                    value: _maxDistance,
                    min: 1,
                    max: 100,
                    divisions: 99,
                    activeColor: Colors.green.shade700,
                    onChanged: (value) {
                      setState(() {
                        _maxDistance = value;
                      });
                    },
                    onChangeEnd: (value) {
                      _applyFilters();
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Botões de ação
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                TextButton.icon(
                  onPressed: _clearFilters,
                  icon: const Icon(Icons.clear),
                  label: const Text('Limpar'),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.grey.shade600,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _applyFilters,
                  icon: const Icon(Icons.search),
                  label: const Text('Aplicar'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade700,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBodyContent() {
    if (_isMapView) {
      return _buildMapView();
    }
    return _buildListView();
  }

  Widget _buildMapView() {
    return GoogleMap(
      mapType: MapType.normal,
      initialCameraPosition: _defaultCameraPosition,
      onMapCreated: (GoogleMapController controller) {
        if (!_mapController.isCompleted) {
          _mapController.complete(controller);
        }
      },
      markers: _markers,
      myLocationEnabled: true,
      myLocationButtonEnabled: true,
      padding: const EdgeInsets.only(bottom: 60), // Para não sobrepor o FAB
    );
  }

  Widget _buildListView() {
    if (_isLoadingProducers) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_filteredProducers.isEmpty) {
      return const Center(child: Text('Nenhum produtor encontrado com os filtros aplicados.'));
    }
    return _buildProducersList(_filteredProducers);
  }

  Widget _buildProducersList(List<UserModel> producers) {
    return ListView.builder(
      itemCount: producers.length,
      itemBuilder: (context, index) {
        final producer = producers[index];
        return ProducerCard(
          producer: producer,
          currentPosition: _currentPosition,
          locationService: _locationService,
        ).animate().fadeIn(duration: 300.ms);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Em vez de StreamBuilder, usamos a variável de estado _currentUserModel.
    if (_currentUserModel == null) {
      // Ecrã de carregamento enquanto o utilizador não é carregado
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // A lógica para determinar a UI é feita aqui, uma vez por build.
    final bool isConsumer = _currentUserModel!.tipo == 'consumidor';

    return Scaffold(
      appBar: AppBar(
        title: const Text('HelloFarmer'),
        actions: [
          // Ícone para GPS (removido temporariamente se não for usado)
          // IconButton(
          //   icon: const Icon(Icons.map),
          //   onPressed: () {
          //     Navigator.of(context).push(MaterialPageRoute(
          //       builder: (context) => const SensorsDemoScreen(),
          //     ));
          //   },
          //   tooltip: 'GPS e Localização',
          // ),
          // Apenas mostra o ícone do carrinho se for um consumidor
          if (isConsumer)
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
          if (isConsumer)
            IconButton(
              icon: const Icon(Icons.favorite_border),
              onPressed: () {
                Navigator.of(context).push(MaterialPageRoute(
                  builder: (context) => const FavoritesScreen(),
                ));
              },
            ),
          // Toggle entre vista de lista e mapa para consumidores
          if (isConsumer)
            IconButton(
              icon: Icon(_isMapView ? Icons.list : Icons.map_outlined),
              tooltip: _isMapView ? 'Ver Lista' : 'Ver Mapa',
              onPressed: () {
                setState(() {
                  _isMapView = !_isMapView;
                });
              },
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
        automaticallyImplyLeading: false,
      ),
      // O corpo da UI depende se é consumidor ou produtor
      body: isConsumer
          ? Column(
              children: [
                _buildFilterBar(),
                Expanded(child: _buildBodyContent()),
              ],
            )
          : _buildProducerDashboard(), // Dashboard para o produtor
      
      // Apenas mostra o botão flutuante se for consumidor E NÃO estiver no mapa
      floatingActionButton: isConsumer && !_isMapView
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
  }

  // NOVO: Widget para o dashboard do produtor
  Widget _buildProducerDashboard() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Bem-vindo, ${_currentUserModel!.nome}!', style: Theme.of(context).textTheme.headlineSmall),
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
            // Adicionar mais botões e informações relevantes aqui
          ],
        ),
      ),
    );
  }
}

class ProducerCard extends StatelessWidget {
  final UserModel producer;
  final Position? currentPosition;
  final LocationService locationService;

  const ProducerCard({
    Key? key,
    required this.producer,
    required this.currentPosition,
    required this.locationService,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        Navigator.of(context).push(MaterialPageRoute(
          builder: (context) => ProducerDetailScreen(producerId: producer.uid),
        ));
      },
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                producer.nome,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
              if (currentPosition != null &&
                  producer.latitude != null &&
                  producer.longitude != null)
                Row(
                  children: [
                    Icon(Icons.location_on, color: Theme.of(context).primaryColor, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      '${(locationService.calculateDistance(currentPosition!.latitude, currentPosition!.longitude, producer.latitude!, producer.longitude!) / 1000).toStringAsFixed(1)} km de distância',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}

