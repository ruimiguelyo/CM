import 'dart:async';
import 'package:geolocator/geolocator.dart';

class SensorService {
  static final SensorService _instance = SensorService._internal();
  factory SensorService() => _instance;
  SensorService._internal();

  // Stream controllers for GPS data
  final StreamController<Position> _positionController = StreamController<Position>.broadcast();
  
  Stream<Position> get positionStream => _positionController.stream;
  
  StreamSubscription<Position>? _positionSubscription;

  Future<void> initializeServices() async {
    await _startLocationTracking();
  }

  Future<void> _startLocationTracking() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception('Serviços de localização estão desativados.');
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Permissões de localização foram negadas');
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw Exception('Permissões de localização foram permanentemente negadas');
      }

      const LocationSettings locationSettings = LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10,
      );

      _positionSubscription = Geolocator.getPositionStream(
        locationSettings: locationSettings,
      ).listen((Position position) {
        _positionController.add(position);
      });
    } catch (e) {
      print('Erro ao inicializar rastreamento de localização: $e');
    }
  }

  Future<Position?> getCurrentPosition() async {
    try {
      return await Geolocator.getCurrentPosition();
    } catch (e) {
      print('Erro ao obter posição atual: $e');
      return null;
    }
  }

  void dispose() {
    _positionSubscription?.cancel();
    _positionController.close();
  }
} 