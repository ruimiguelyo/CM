import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:hellofarmer_app/services/location_service.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:async';

class SensorsDemoScreen extends StatefulWidget {
  const SensorsDemoScreen({super.key});

  @override
  State<SensorsDemoScreen> createState() => _SensorsDemoScreenState();
}

class _SensorsDemoScreenState extends State<SensorsDemoScreen> {
  final LocationService _locationService = LocationService();
  
  Position? _currentPosition;
  bool _isLoadingLocation = false;
  String _locationError = '';
  
  GoogleMapController? _mapController;
  Set<Marker> _markers = {};
  
  // Coordenadas padrão (centro de Portugal)
  static const LatLng _defaultLocation = LatLng(39.5, -8.0);

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    if (!mounted) return;
    
    setState(() {
      _isLoadingLocation = true;
      _locationError = '';
    });

    try {
      final position = await _locationService.getCurrentLocation();
      if (position != null && mounted) {
        setState(() {
          _currentPosition = position;
        });
        _updateMapMarker(position);
        
        // Move a câmara para a localização atual
        if (_mapController != null) {
          _mapController!.animateCamera(
            CameraUpdate.newLatLngZoom(
              LatLng(position.latitude, position.longitude),
              15.0,
            ),
          );
        }
      } else if (mounted) {
        setState(() {
          _locationError = 'Não foi possível obter a localização';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _locationError = 'Erro: $e';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingLocation = false;
        });
      }
    }
  }

  void _updateMapMarker(Position position) {
    if (!mounted) return;
    
    setState(() {
      _markers = {
        Marker(
          markerId: const MarkerId('current_location'),
          position: LatLng(position.latitude, position.longitude),
          infoWindow: const InfoWindow(
            title: 'Minha Localização',
            snippet: 'Você está aqui',
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
        ),
      };
    });
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
    if (_currentPosition != null) {
      _updateMapMarker(_currentPosition!);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('GPS e Localização'),
        actions: [
          IconButton(
            icon: const Icon(Icons.my_location),
            onPressed: _isLoadingLocation ? null : _getCurrentLocation,
          ),
        ],
      ),
      body: Column(
        children: [
          // Informações GPS
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16.0),
            color: Theme.of(context).primaryColor.withOpacity(0.1),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.location_on, color: Colors.blue),
                    const SizedBox(width: 8),
                    Text(
                      'Localização GPS',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                if (_isLoadingLocation)
                  const Row(
                    children: [
                      SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      SizedBox(width: 8),
                      Text('Obtendo localização...'),
                    ],
                  )
                else if (_locationError.isNotEmpty)
                  Text(
                    _locationError,
                    style: const TextStyle(color: Colors.red),
                  )
                else if (_currentPosition != null)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Latitude: ${_currentPosition!.latitude.toStringAsFixed(6)}'),
                      Text('Longitude: ${_currentPosition!.longitude.toStringAsFixed(6)}'),
                      Text('Altitude: ${_currentPosition!.altitude.toStringAsFixed(2)}m'),
                      Text('Precisão: ${_currentPosition!.accuracy.toStringAsFixed(2)}m'),
                    ],
                  )
                else
                  const Text('Toque no ícone de localização para obter sua posição'),
              ],
            ),
          ),
          
          // Mapa
          Expanded(
            child: _buildMapWidget(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _isLoadingLocation ? null : _getCurrentLocation,
        tooltip: 'Atualizar Localização',
        child: _isLoadingLocation 
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Icon(Icons.my_location),
      ),
    );
  }

  Widget _buildMapWidget() {
    try {
      return GoogleMap(
        onMapCreated: _onMapCreated,
        initialCameraPosition: CameraPosition(
          target: _currentPosition != null 
              ? LatLng(_currentPosition!.latitude, _currentPosition!.longitude)
              : _defaultLocation,
          zoom: _currentPosition != null ? 15.0 : 6.0,
        ),
        markers: _markers,
        myLocationEnabled: true,
        myLocationButtonEnabled: false, // Usamos nosso próprio botão
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
            if (_currentPosition != null)
              Text(
                'Lat: ${_currentPosition!.latitude.toStringAsFixed(4)}\nLng: ${_currentPosition!.longitude.toStringAsFixed(4)}',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
              ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _getCurrentLocation,
              icon: const Icon(Icons.refresh),
              label: const Text('Tentar Novamente'),
            ),
          ],
        ),
      );
    }
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }
} 