// lib/services/google_places_stub.dart
// Este ficheiro serve como um "placeholder" para as classes do package google_maps_apis
// que foi removido. Isto permite que o código que ainda depende dessas classes
// continue a compilar sem erros. A funcionalidade (como o autocompletar de moradas)
// ficará desativada até que este stub seja substituído por uma nova implementação.

class Prediction {
  final String? description;
  final String? placeId;
  Prediction({this.description, this.placeId});
}

class AddressComponent {
  final List<String>? types;
  final String? longName;
  AddressComponent({this.types, this.longName});
}

class Location {
  final double lat;
  final double lng;
  Location({required this.lat, required this.lng});
}

class Geometry {
  final Location? location;
  Geometry({this.location});
}

class PlaceDetails {
  final List<AddressComponent>? addressComponents;
  final Geometry? geometry;
  PlaceDetails({this.addressComponents, this.geometry});
}

class PlacesAutocompleteResponse {
  final String? status;
  final List<Prediction>? predictions;
  final String? errorMessage;
  PlacesAutocompleteResponse({this.status, this.predictions, this.errorMessage});
}

class PlacesDetailsResponse {
  final String? status;
  final PlaceDetails? result;
  final String? errorMessage;
  PlacesDetailsResponse({this.status, this.result, this.errorMessage});
}

class GoogleMapsPlaces {
  GoogleMapsPlaces({required String apiKey});

  Future<PlacesAutocompleteResponse> autocomplete(
    String input, {
    String? sessionToken,
    String? language,
    List<dynamic>? components,
  }) async {
    // Retorna uma resposta vazia e bem-sucedida para não quebrar a UI
    return PlacesAutocompleteResponse(status: 'OK', predictions: []);
  }

  Future<PlacesDetailsResponse> getDetailsByPlaceId(
    String placeId, {
    String? sessionToken,
    String? language,
  }) async {
    // Retorna uma resposta nula para indicar que não encontrou detalhes
    return PlacesDetailsResponse(status: 'ZERO_RESULTS');
  }
}

// Classe vazia para o tipo Component que era usado no search
class Component {
  static const String country = 'country';
  Component(String type, String value);
} 