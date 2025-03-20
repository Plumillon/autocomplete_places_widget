import 'dart:convert';

import 'package:autocomplete_places_widget/src/models/prediction.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../models/mapbox/mapbox_place_details.dart';
import '../models/mapbox/mapbox_prediction.dart';
import 'places_provider.dart';

/// For [PlacesProviderConfig.types] see https://developers.google.com/places/web-service/supported_types
class MapboxPlacesProviderConfig extends PlacesProviderConfig {
  MapboxPlacesProviderConfig({
    super.apiKey,
    super.proxyURL,
    super.countries,
    super.placeTypes,
  });
}

class MapboxPlacesProvider extends PlacesProvider {
  String? sessionToken;

  MapboxPlacesProvider({required MapboxPlacesProviderConfig config})
      : super(config: config) {
    sessionToken = config.useSessionToken ? const Uuid().v4() : null;
  }

  @override
  Future<List<MapboxPrediction>> fetchPlaces(String text) async {
    final prefix = config.proxyURL ?? "";

    String url =
        "${prefix}https://api.mapbox.com/search/searchbox/v1/suggest?q=$text${config.apiKey != null ? "&access_token=${config.apiKey}" : ""}";

    if (config.countries.isNotEmpty) {
      url += "&country=${config.countries.join(',')}";
    }

    if (config.placeTypes.isNotEmpty) {
      url += "&types=${config.placeTypes.join(',')}";
    }

    if (sessionToken != null) {
      url += "&session_token=$sessionToken";
    }

    final response = await dio.get(url);

    return response.data["suggestions"] != null
        ? List<MapboxPrediction>.from(response.data["suggestions"]
            .map((suggestion) => MapboxPrediction.fromJson(suggestion)))
        : [];
  }

  @override
  Future<Prediction> getPlaceDetailsFromPlaceId(Prediction prediction) async {
    try {
      final prefix = config.proxyURL ?? "";
      final url =
          "${prefix}https://api.mapbox.com/search/searchbox/v1/retrieve/${prediction.id}${config.apiKey != null ? "?access_token=${config.apiKey}" : ""}${config.useSessionToken ? "&session_token=$sessionToken" : ""}";
      final response = await dio.get(url);
      final placeDetails = MapboxPlaceDetails.fromJson(response.data);
      prediction.details = placeDetails;
      final Feature? feature = placeDetails.features.firstOrNull;
      prediction.region = feature?.properties.context?.region;
      prediction.country = feature?.properties.context?.country;
      prediction.postalCode = feature?.properties.context?.postcode;
      prediction.lat = feature?.geometry.coordinates[1];
      prediction.lng = feature?.geometry.coordinates[0];

      return prediction;
    } catch (e) {
      return prediction;
    }
  }

  @override
  Future<List<Prediction>?> getPredictionsFromSharedPref() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final json = prefs.getStringList(predictionHistoryKey);
    List<Prediction>? predictions;

    if (json == null) {
      return null;
    }

    try {
      predictions = json
          .map(
              (prediction) => MapboxPrediction.fromJson(jsonDecode(prediction)))
          .toList();
    } catch (e) {
      predictions = null;
    }

    return predictions;
  }
}
