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
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' as latlong;
import 'package:hellofarmer_app/services/location_service.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter/widgets.dart';

class HomeScreen extends StatefulWidget {
  final bool isMapView;
  const HomeScreen({super.key, this.isMapView = false});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final LocationService _locationService = LocationService();
  
  // Controller para o flutter_map
  final MapController _mapController = MapController();

  // A lista de marcadores para o flutter_map
  List<Marker> _markers = [];

  Position? _currentPosition;
  
  // Coordenadas padrão (centro de Portugal)
  static final latlong.LatLng _defaultLocation = latlong.LatLng(39.5, -8.0);
  
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
    _isMapView = widget.isMapView; // Define o estado inicial da vista
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    // Carrega dados que não dependem da localização primeiro.
    // O await aqui garante que temos categorias e o utilizador carregado antes de fazer o primeiro render.
    // A lista de produtores também começa a ser carregada em paralelo.
    Future.wait([
      _loadCurrentUser(),
      _loadCategories(),
      _updateProducersList(), // Carrega a lista inicial, que pode ser re-filtrada depois.
    ]);

    // Agora, tenta obter a localização em segundo plano.
    // Se for bem-sucedido, a lista será atualizada para refletir a distância.
    _initializeLocationAndMoveCamera().then((locationFound) {
      if (locationFound && mounted) {
        // A localização foi encontrada, disparamos uma nova atualização da lista para aplicar o filtro de distância.
        _updateProducersList();
      }
    });
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
  Future<void> _updateProducersList() async {
    if (!mounted) return;
    setState(() {
      _isLoadingProducers = true;
    });

    try {
      // Passo 1: Obter TODOS os produtores da base de dados.
      List<UserModel> allProducers = await _firestoreService.getAgricultores().first;
      List<UserModel> filteredProducers = List.from(allProducers);

      // Passo 2: Aplicar o filtro de categoria, se existir
      if (_selectedCategory != null) {
        final categoryProducers = await _firestoreService.getProducersByCategory(_selectedCategory!);
        final categoryIds = categoryProducers.map((p) => p.uid).toSet();
        filteredProducers = filteredProducers.where((p) => categoryIds.contains(p.uid)).toList();
      }

      // Passo 3: Aplicar o filtro de distância
      if (_currentPosition != null) {
        filteredProducers = filteredProducers.where((producer) {
          if (producer.latitude == null || producer.longitude == null) {
            return false;
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
      
      // Passo 4: Gerar os marcadores para o mapa a partir dos dados filtrados.
      // A função _generateMarkers já cuida de adicionar o pino do utilizador.
      final newMarkers = _generateMarkers(filteredProducers);

      // Passo 5: Atualizar o estado da UI com os dados finais
      if (mounted) {
        setState(() {
          _producers = allProducers;
          _filteredProducers = filteredProducers;
          _markers = newMarkers;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao carregar produtores: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingProducers = false;
        });
      }
    }
  }

  Future<bool> _initializeLocationAndMoveCamera() async {
    Position? userPosition;
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      try {
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
      } catch (e) {
        // É normal não ter a localização na BD, não é um erro crítico.
        debugPrint("Não foi possível obter a localização do perfil do utilizador: $e");
      }
    }

    if (userPosition == null) {
      try {
        // Este é o ponto que pode "prender" a app se o utilizador não responder à permissão.
        // Ao estar num `then`, não bloqueia o build inicial.
        userPosition = await _locationService.getCurrentLocation();
      } catch (e) {
        debugPrint('Erro ao obter localização do dispositivo: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Não foi possível obter a sua localização. Verifique as permissões.'),
            backgroundColor: Colors.orange,
          ));
        }
      }
    }

    if (mounted) {
      setState(() {
        _currentPosition = userPosition;
      });

      // Mover a câmara do mapa para a nova posição - APENAS se estivermos na vista do mapa
      if (userPosition != null && _isMapView) {
        try {
          _mapController.move(
            latlong.LatLng(userPosition.latitude, userPosition.longitude),
            12.0, // Zoom mais apropriado para uma localização específica
          );
        } catch (e) {
          // Ignora erros do MapController se o widget não estiver renderizado
          debugPrint('MapController não está pronto ainda: $e');
        }
        return true; // Indica que a localização foi obtida com sucesso.
      }
    }
    return false; // Indica que a localização não foi obtida.
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

  void _clearFilters() {
    setState(() {
      _selectedCategory = null;
      _maxDistance = 50.0;
    });
    // Re-aplicar filtros para voltar ao estado inicial (considerando distância)
    _updateProducersList();
  }

  List<Marker> _generateMarkers(List<UserModel> producers) {
    final markers = producers
        .where((p) => p.latitude != null && p.longitude != null)
        .map((producer) => Marker(
              width: 80.0,
              height: 80.0,
              point: latlong.LatLng(producer.latitude!, producer.longitude!),
              child: GestureDetector(
                onTap: () {
                    Navigator.of(context).push(MaterialPageRoute(
                      builder: (context) => ProducerDetailScreen(producerId: producer.uid),
                    ));
                },
                child: Column(
                  children: [
                    Icon(Icons.location_pin, color: Theme.of(context).primaryColor, size: 40),
                    Text(producer.nome, style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, backgroundColor: Colors.white.withOpacity(0.7))),
                  ],
                )
              ),
            ))
        .toList();

    // Adiciona o marcador do utilizador se a localização for conhecida
    if (_currentPosition != null) {
      markers.add(
        Marker(
          width: 80,
          height: 80,
          point: latlong.LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
          child: const Icon(Icons.my_location, color: Colors.blueAccent, size: 30),
        )
      );
    }
    return markers;
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
                            _updateProducersList();
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
                      _updateProducersList();
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
                  onPressed: _updateProducersList,
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
    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: _currentPosition != null
            ? latlong.LatLng(_currentPosition!.latitude, _currentPosition!.longitude)
            : _defaultLocation,
        initialZoom: _currentPosition != null ? 12.0 : 7.0,
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.example.hellofarmer_app',
        ),
        MarkerLayer(markers: _markers),
      ],
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

    // O corpo da UI depende se é consumidor ou produtor
    return isConsumer
        ? Column(
            children: [
              _buildFilterBar(),
              Expanded(child: _buildBodyContent()),
            ],
          )
        : _buildProducerDashboard(); // Dashboard para o produtor
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

