library google_maps_apis.places;

// Este ficheiro é um stub mínimo para permitir que as importações
// `package:google_maps_apis/places.dart` continuem a compilar sem depender
// de bibliotecas externas já descontinuadas.  **NÃO** fornece ligações reais
// à API Google Places.  Se precisar de funcionalidade real, substitua este
// stub por um package mantido, como `google_place` ou `flutter_google_places`.

class Prediction {
  final String? description;
  final String? placeId;
  Prediction({this.description, this.placeId});
}

class AddressComponent {
  final String? longName;
  final List<String>? types;
  AddressComponent({this.longName, this.types});
}

class Location {
  final double lat;
  final double lng;
  Location({required this.lat, required this.lng});
}

class Geometry {
  final Location location;
  Geometry({required this.location});
}

class PlaceDetails {
  final List<AddressComponent>? addressComponents;
  final Geometry? geometry;
  PlaceDetails({this.addressComponents, this.geometry});
}

class PlacesAutocompleteResponse {
  final String status;
  final String? errorMessage;
  final List<Prediction>? predictions;
  PlacesAutocompleteResponse({
    required this.status,
    this.errorMessage,
    this.predictions,
  });
}

class GoogleMapsPlaces {
  final String apiKey;
  GoogleMapsPlaces({required this.apiKey});

  // Autocomplete devolve lista vazia
  Future<PlacesAutocompleteResponse> autocomplete(
    String input, {
    String? sessionToken,
    String? language,
    List<Component>? components,
  }) async {
    return PlacesAutocompleteResponse(status: "OK", predictions: []);
  }

  // Detalhes de local devolvem nulo
  Future<PlacesDetailsResponse> getDetailsByPlaceId(
    String placeId, {
    String? sessionToken,
    String? language,
  }) async {
    return PlacesDetailsResponse(status: "OK", result: null);
  }
}

class PlacesDetailsResponse {
  final String status;
  final String? errorMessage;
  final PlaceDetails? result;
  PlacesDetailsResponse({required this.status, this.errorMessage, this.result});
}

class Component {
  static const country = "country";
  final String? component;
  final String? value;
  Component(this.component, this.value);
} 