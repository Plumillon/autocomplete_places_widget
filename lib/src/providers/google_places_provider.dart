import 'dart:convert';

import 'package:autocomplete_places_widget/autocomplete_places_widget.dart';
import 'package:autocomplete_places_widget/src/models/google/google_place_details.dart';
import 'package:autocomplete_places_widget/src/models/google/google_prediction.dart';
import 'package:autocomplete_places_widget/src/providers/places_provider.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

class GooglePlacesProviderConfig extends PlacesProviderConfig {
  final bool useNewPlacesAPI;

  GooglePlacesProviderConfig({
    super.apiKey,
    super.proxyURL,
    super.countries,
    super.placeTypes,
    this.useNewPlacesAPI = false,
  });
}

class GooglePlacesProvider extends PlacesProvider {
  String? sessionToken;

  GooglePlacesProvider({required GooglePlacesProviderConfig config})
      : super(config: config) {
    sessionToken = config.useSessionToken ? const Uuid().v4() : null;
  }

  @override
  Future<List<GooglePrediction>> fetchPlaces(String text) async {
    final prefix = config.proxyURL ?? "";
    List<GooglePrediction> predictions = [];

    if ((config as GooglePlacesProviderConfig).useNewPlacesAPI) {
      String url =
          "${prefix}https://places.googleapis.com/v1/places:autocomplete";

      Map<String, dynamic> requestBody = {"input": text};

      if (config.countries.isNotEmpty) {
        requestBody["includedRegionCodes"] = config.countries;
      }
      if (sessionToken != null) {
        requestBody["sessionToken"] = sessionToken;
      }
      if (config.placeTypes.isNotEmpty) {
        requestBody["types"] = config.placeTypes;
      }

      final response = await dio.post(url,
          options: config.apiKey != null
              ? Options(
                  headers: {"X-Goog-Api-Key": config.apiKey},
                )
              : null,
          data: jsonEncode(requestBody));
      predictions = response.data["suggestions"] != null
          ? List<GooglePrediction>.from(response.data["suggestions"]
              .map((prediction) => GoogleNewPrediction.fromJson(prediction)))
          : [];
    } else {
      String url =
          "${prefix}https://maps.googleapis.com/maps/api/place/autocomplete/json?input=$text${config.apiKey != null ? "&key=$config.apiKey" : ""}";

      for (int i = 0; i < config.countries.length; i++) {
        url =
            "${i == 0 ? "$url&components=" : "$url|"}country:${config.countries[i]}";
      }

      if (config.placeTypes.isNotEmpty) {
        url += "&includedPrimaryTypes=${config.placeTypes.join('|')}";
      }

      if (sessionToken != null) {
        url += "&sessiontoken=$sessionToken";
      }

      final response = await dio.get(url);

      predictions = response.data["predictions"] != null
          ? List<GooglePrediction>.from(response.data["predictions"]
              .map((prediction) => GooglePrediction.fromJson(prediction)))
          : [];
    }

    return predictions;
  }

  @override
  Future<Prediction> getPlaceDetailsFromPlaceId(Prediction prediction) async {
    try {
      final prefix = config.proxyURL ?? "";
      final url =
          "${prefix}https://maps.googleapis.com/maps/api/place/details/json?placeid=${prediction.id}${config.apiKey != null ? "&key=${config.apiKey}" : ""}";
      final response = await dio.get(url);
      final placeDetails = GooglePlaceDetails.fromJson(response.data);
      prediction.details = placeDetails;
      prediction.region = placeDetails.result?.addressComponents
          ?.where((element) =>
              element.types?.contains("administrative_area_level_1") ?? false)
          .firstOrNull
          ?.longName;
      prediction.country = placeDetails.result?.addressComponents
          ?.where((element) => element.types?.contains("country") ?? false)
          .firstOrNull
          ?.shortName;
      prediction.postalCode = placeDetails.result?.addressComponents
          ?.where((element) => element.types?.contains("postal_code") ?? false)
          .firstOrNull
          ?.longName;
      prediction.lat = placeDetails.result?.geometry?.location?.lat;
      prediction.lng = placeDetails.result?.geometry?.location?.lng;

      return prediction;
    } catch (e) {
      return prediction;
    }
  }

  @override
  Future<List<Prediction>?> getPredictionsFromSharedPref() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final json = prefs.getStringList(predictionHistoryKey);

    if (json == null) {
      return null;
    }

    return json.map((e) => GooglePrediction.fromJson(jsonDecode(e))).toList();
  }
}
