import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/foundation.dart';
import 'package:geocoding/geocoding.dart';
import 'package:google_maps_apis/places.dart';
import 'package:uuid/uuid.dart';

// NOTA: Esta API Key precisa de ter a "Places API" ativa na Consola Google Cloud.
// Foi retirada do ficheiro firebase_options.dart.
const String _kGoogleApiKey = "AIzaSyDF2qdqOBav6_32TAHP3FSrLpvYPKuAbH8";

class LocationService {
  static final LocationService _instance = LocationService._internal();
  factory LocationService() => _instance;
  LocationService._internal() {
    _places = GoogleMapsPlaces(apiKey: _kGoogleApiKey);
  }

  Position? _currentPosition;
  bool _isLocationEnabled = false;

  // Instância do serviço do Google Places
  late final GoogleMapsPlaces _places;

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

  /// Gera um token de sessão para as pesquisas na Places API
  String generateSessionToken() {
    return const Uuid().v4();
  }

  /// Pesquisa moradas usando o autocompletar da Google Places API
  Future<List<Prediction>> searchPlaces(String input, {required String sessionToken}) async {
    if (input.isEmpty) {
      return [];
    }
    try {
      final response = await _places.autocomplete(
        input,
        sessionToken: sessionToken,
        language: 'pt',
        components: [Component(Component.country, "pt")], // Restringe a Portugal
      );

      if (response.status == "OK") {
        return response.predictions ?? [];
      } else {
        debugPrint('Erro na API Places: ${response.errorMessage}');
        return [];
      }
    } catch (e) {
      debugPrint('Erro ao pesquisar morada: $e');
      return [];
    }
  }

  /// Obtém os detalhes de uma morada a partir do seu placeId
  Future<PlaceDetails?> getPlaceDetails(String placeId, {required String sessionToken}) async {
    try {
      final response = await _places.getDetailsByPlaceId(
        placeId,
        sessionToken: sessionToken,
        language: 'pt',
      );

      if (response.status == "OK") {
        return response.result;
      } else {
        debugPrint('Erro na API Place Details: ${response.errorMessage}');
        return null;
      }
    } catch (e) {
      debugPrint('Erro ao obter detalhes da morada: $e');
      return null;
    }
  }
} 