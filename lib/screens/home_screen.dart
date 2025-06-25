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

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final LocationService _locationService = LocationService();
  
  GoogleMapController? _mapController;
  Set<Marker> _markers = {};
  Position? _currentPosition;
  bool _showMap = false;
  
  // Coordenadas padrão (centro de Portugal)
  static const LatLng _defaultLocation = LatLng(39.5, -8.0);

  final bool _isMapView = false;
  List<UserModel> _producers = [];
  List<UserModel> _filteredProducers = [];
  List<String> _availableCategories = [];
  String? _selectedCategory;
  double _maxDistance = 50.0; // km
  bool _isLoadingProducers = true;
  bool _isLoadingCategories = true;
  bool _showFilters = false;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    // 1. Obter a localização primeiro, pois é essencial para os filtros
    await _initializeLocation();

    // 2. Carregar produtores e categorias em paralelo
    await Future.wait([
      _loadProducers(),
      _loadCategories(),
    ]);

    // 3. Aplicar os filtros iniciais (especialmente o de distância)
    if (mounted) {
      await _applyFilters();
    }
  }

  Future<void> _initializeLocation() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      final userModel = await _firestoreService.getUser(currentUser.uid).first;
      // Prioridade para a localização guardada no perfil do utilizador
      if (userModel.latitude != null && userModel.longitude != null) {
        if (mounted) {
          setState(() {
            _currentPosition = Position(
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
          });
        }
        return; // Sair após usar a localização guardada
      }
    }

    // Fallback: se não houver utilizador ou se o utilizador não tiver localização,
    // tenta obter a localização do dispositivo físico.
    try {
      final position = await _locationService.getCurrentLocation();
      if (mounted) {
        setState(() {
          _currentPosition = position;
        });
      }
    } catch (e) {
      print('Erro ao obter localização do dispositivo: $e');
    }
  }

  Future<void> _loadProducers() async {
    try {
      final producers = await _firestoreService.getAgricultores().first;
      if (mounted) {
        setState(() {
          _producers = producers;
          _filteredProducers = producers;
          _isLoadingProducers = false;
        });
      }
    } catch (e) {
      print('Erro ao carregar produtores: $e');
      if (mounted) {
        setState(() {
          _isLoadingProducers = false;
        });
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

    try {
      List<UserModel> filteredProducers = [];

      // Começar sempre com todos os produtores
      filteredProducers = await _firestoreService.getAgricultores().first;

      // Aplicar filtro de categoria se selecionado
      if (_selectedCategory != null) {
        final categoryProducers = await FirestoreService().getProducersByCategory(_selectedCategory!);
        final categoryIds = categoryProducers.map((p) => p.uid).toSet();
        filteredProducers = filteredProducers.where((p) => categoryIds.contains(p.uid)).toList();
      }

      // Aplicar filtro de distância APENAS se a localização atual estiver disponível
      // Se não houver localização, mantém todos os produtores (não aplica filtro de distância)
      if (_currentPosition != null) {
        filteredProducers = filteredProducers.where((producer) {
          // Se o produtor não tem coordenadas, mantém na lista (não exclui)
          if (producer.latitude == null || producer.longitude == null) {
            return true; 
          }

          final distanceInMeters = _locationService.calculateDistance(
            _currentPosition!.latitude,
            _currentPosition!.longitude,
            producer.latitude!,
            producer.longitude!,
          );

          // Converter metros para quilómetros para comparar com _maxDistance
          final distanceInKm = distanceInMeters / 1000;

          return distanceInKm <= _maxDistance;
        }).toList();
      }
      // Se não há posição atual, não aplica filtro de distância (mantém todos)

      if (mounted) {
        setState(() {
          _filteredProducers = filteredProducers;
          _isLoadingProducers = false;
        });
      }
    } catch (e) {
      print('Erro ao aplicar filtros: $e');
      if (mounted) {
        setState(() {
          _filteredProducers = _producers; // Fallback para todos os produtores
          _isLoadingProducers = false;
        });
      }
    }
  }

  void _clearFilters() {
    setState(() {
      _selectedCategory = null;
      _maxDistance = 50.0;
      _filteredProducers = _producers;
    });
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

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
  }

  void _updateProducerMarkers(List<UserModel> producers) {
    final Set<Marker> newMarkers = {};
    
    // Adicionar marcador da localização atual se disponível
    if (_currentPosition != null) {
      newMarkers.add(
        Marker(
          markerId: const MarkerId('current_location'),
          position: LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
          infoWindow: const InfoWindow(
            title: 'Minha Localização',
            snippet: 'Você está aqui',
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
        ),
      );
    }
    
    // Adicionar marcadores dos produtores
    for (final producer in producers) {
      if (producer.latitude != null && producer.longitude != null) {
        newMarkers.add(
          Marker(
            markerId: MarkerId('producer_${producer.uid}'),
            position: LatLng(producer.latitude!, producer.longitude!),
            infoWindow: InfoWindow(
              title: producer.nome,
              snippet: producer.morada,
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => ProducerDetailScreen(producerId: producer.uid),
                  ),
                );
              },
            ),
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
          ),
        );
      }
    }
    
    // Usar addPostFrameCallback para evitar setState durante build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() {
          _markers = newMarkers;
        });
      }
    });
  }

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
              // Ícone para GPS
              IconButton(
                icon: const Icon(Icons.map),
                onPressed: () {
                  Navigator.of(context).push(MaterialPageRoute(
                    builder: (context) => const SensorsDemoScreen(),
                  ));
                },
                tooltip: 'GPS e Localização',
              ),
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
              if (user.tipo == 'consumidor')
                IconButton(
                  icon: const Icon(Icons.favorite_border),
                  onPressed: () {
                    Navigator.of(context).push(MaterialPageRoute(
                      builder: (context) => const FavoritesScreen(),
                    ));
                  },
                ),
              // Toggle entre vista de lista e mapa para consumidores
              if (user.tipo == 'consumidor')
                IconButton(
                  icon: Icon(_showMap ? Icons.list : Icons.map_outlined),
                  onPressed: () {
                    setState(() {
                      _showMap = !_showMap;
                    });
                    // Se mudou para o modo mapa, força atualização dos marcadores
                    if (_showMap) {
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        // Trigger rebuild para atualizar marcadores
                        if (mounted) {
                          setState(() {});
                        }
                      });
                    }
                  },
                  tooltip: _showMap ? 'Ver Lista' : 'Ver Mapa',
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
      // Mostra a lista de produtores para o consumidor com filtros
      return Column(
        children: [
          _buildFilterBar(),
          Expanded(
            child: _isLoadingProducers 
              ? const Center(child: CircularProgressIndicator())
              : _filteredProducers.isEmpty
                ? const Center(
                    child: Text('Nenhum produtor encontrado com os filtros aplicados.'),
                  )
                                 : _buildContent(),
          ),
        ],
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

  Widget _buildContent() {
    // Atualizar marcadores se estivermos na vista do mapa
    if (_showMap) {
      _updateProducerMarkers(_filteredProducers);
      return _buildProducersMap();
    } else {
      return _buildProducersList(_filteredProducers);
    }
  }

  Widget _buildProducersMap() {
    try {
      return GoogleMap(
        onMapCreated: _onMapCreated,
        initialCameraPosition: CameraPosition(
          target: _currentPosition != null 
              ? LatLng(_currentPosition!.latitude, _currentPosition!.longitude)
              : _defaultLocation,
          zoom: _currentPosition != null ? 10.0 : 6.0,
        ),
        markers: _markers,
        myLocationEnabled: true,
        myLocationButtonEnabled: true,
        zoomControlsEnabled: true,
        compassEnabled: true,
        mapType: MapType.normal,
      );
    } catch (e) {
      // Fallback se o Google Maps não estiver disponível
      return Container(
        color: Colors.grey.shade100,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.map_outlined, size: 80, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              'Mapa indisponível',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'A API do Google Maps não está configurada',
              style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  _showMap = false;
                });
              },
              icon: const Icon(Icons.list),
              label: const Text('Ver Lista'),
            ),
          ],
        ),
      );
    }
  }

  Widget _buildProducersList(List<UserModel> agricultores) {
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
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(agricultor.morada),
                if (agricultor.latitude != null && agricultor.longitude != null && _currentPosition != null)
                  Text(
                    'Distância: ${_locationService.formatDistance(_locationService.calculateDistance(
                      _currentPosition!.latitude,
                      _currentPosition!.longitude,
                      agricultor.latitude!,
                      agricultor.longitude!,
                    ))}',
                    style: TextStyle(
                      color: Theme.of(context).primaryColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
              ],
            ),
            trailing: agricultor.latitude != null && agricultor.longitude != null 
                ? const Icon(Icons.location_on, color: Colors.green)
                : null,
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
  }
}

