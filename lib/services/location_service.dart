import 'dart:convert';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/foundation.dart';
import 'package:geocoding/geocoding.dart';
import 'package:http/http.dart' as http;

/// Classe para modelar as sugestões de morada do Nominatim
class AddressSuggestion {
  final String placeId; // Usaremos o osm_id do Nominatim
  final String description;
  final double latitude;
  final double longitude;

  AddressSuggestion({
    required this.placeId,
    required this.description,
    required this.latitude,
    required this.longitude,
  });

  factory AddressSuggestion.fromJson(Map<String, dynamic> json) {
    return AddressSuggestion(
      placeId: json['osm_id'].toString(),
      description: json['display_name'],
      latitude: double.parse(json['lat']),
      longitude: double.parse(json['lon']),
    );
  }
}

class LocationService {
  static final LocationService _instance = LocationService._internal();
  factory LocationService() => _instance;
  LocationService._internal();

  Position? _currentPosition;
  bool _isLocationEnabled = false;

  Position? get currentPosition => _currentPosition;
  bool get isLocationEnabled => _isLocationEnabled;

  /// Verifica e pede permissões de localização
  Future<bool> requestLocationPermission() async {
    if (kIsWeb) {
      // Para web, usa a API de geolocalização do browser
      return await _requestWebLocationPermission();
    }

    // Para mobile, usa o permission_handler
    final status = await Permission.location.status;
    
    if (status.isGranted) {
      return true;
    }
    
    if (status.isDenied) {
      final result = await Permission.location.request();
      return result.isGranted;
    }
    
    if (status.isPermanentlyDenied) {
      // Abre as configurações para o utilizador ativar manualmente
      await openAppSettings();
      return false;
    }
    
    return false;
  }

  /// Verifica permissões específicas para web
  Future<bool> _requestWebLocationPermission() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return false;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return false;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        return false;
      }

      return true;
    } catch (e) {
      print('Erro ao verificar permissões de localização na web: $e');
      return false;
    }
  }

  /// Obtém a localização atual do utilizador
  Future<Position?> getCurrentLocation() async {
    try {
      // Verifica se o serviço de localização está ativo
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _isLocationEnabled = false;
        throw Exception('Serviços de localização estão desativados.');
      }

      // Verifica permissões
      final hasPermission = await requestLocationPermission();
      if (!hasPermission) {
        throw Exception('Permissão de localização negada.');
      }

      // Obtém a posição atual
      _currentPosition = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      _isLocationEnabled = true;
      return _currentPosition;
    } catch (e) {
      print('Erro ao obter localização: $e');
      _isLocationEnabled = false;
      return null;
    }
  }

  /// Stream para acompanhar mudanças de localização em tempo real
  Stream<Position> getLocationStream() {
    return Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10,
      ),
    );
  }

  /// Calcula a distância entre duas coordenadas
  double calculateDistance(
    double startLatitude,
    double startLongitude,
    double endLatitude,
    double endLongitude,
  ) {
    return Geolocator.distanceBetween(
      startLatitude,
      startLongitude,
      endLatitude,
      endLongitude,
    );
  }

  /// Formata a distância para exibição
  String formatDistance(double distanceInMeters) {
    if (distanceInMeters < 1000) {
      return '${distanceInMeters.round()} m';
    } else {
      return '${(distanceInMeters / 1000).toStringAsFixed(1)} km';
    }
  }

  /// Obtém o endereço a partir de coordenadas (geocoding reverso)
  /// Retorna um objeto Placemark que contém os detalhes da morada.
  Future<Placemark?> getAddressFromCoordinates(double latitude, double longitude) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        latitude,
        longitude,
      );

      if (placemarks.isNotEmpty) {
        return placemarks.first;
      }
      return null;
    } catch (e) {
      print('Erro no geocoding reverso: $e');
      return null;
    }
  }

  /// Pesquisa moradas usando a API do Nominatim (OpenStreetMap)
  Future<List<AddressSuggestion>> searchPlaces(String query) async {
    if (query.length < 3) {
      return [];
    }

    final url = Uri.parse(
        'https://nominatim.openstreetmap.org/search?q=$query&format=json&addressdetails=1&countrycodes=pt');

    try {
      final response = await http.get(
        url,
        headers: {
          // O User-Agent é importante para a API do Nominatim
          'User-Agent': 'HelloFarmerApp/1.0 (seu.email@exemplo.com)',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => AddressSuggestion.fromJson(json)).toList();
      } else {
        debugPrint('Erro na API Nominatim: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      debugPrint('Erro ao pesquisar morada via Nominatim: $e');
      return [];
    }
  }
} 