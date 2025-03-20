import 'dart:convert';
import 'dart:developer';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/prediction.dart';

abstract class PlacesProviderConfig {
  /// The API key to use for the API.
  final String? apiKey;

  /// Whether to use a session token for the API request.
  /// This can help with billing.
  /// Default is true.
  final bool useSessionToken;

  /// The proxy URL to use for the API request.
  /// This can be used to bypass CORS restrictions or manage your API key server side.
  /// Example: "https://cors-anywhere.herokuapp.com/"
  final String? proxyURL;

  /// The countries to restrict the search to.
  /// Two-character region code.
  final List<String> countries;

  /// The types of place results to return.
  /// If null, all types will be returned.
  final List<String> placeTypes;

  PlacesProviderConfig({
    required this.apiKey,
    this.useSessionToken = true,
    required this.proxyURL,
    this.countries = const [],
    this.placeTypes = const [],
  })  : assert(!kIsWeb || kIsWeb && proxyURL != null,
            'On web a CORS enabled proxy must be provided'),
        assert(apiKey != null || proxyURL != null,
            'apiKey or proxyURL must be provided');
}

abstract class PlacesProvider {
  final String predictionHistoryKey = "apPrediction";
  final PlacesProviderConfig config;
  final Dio dio = Dio();

  PlacesProvider({required this.config});

  Future<List<Prediction>> fetchPlaces(String text);

  Future<Prediction> getPlaceDetailsFromPlaceId(Prediction prediction);

  /// [Prediction] will be saved in shared preferences
  Future<void> savePrediction(Prediction prediction, {bool? liteMode}) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final json = prediction.toJson();

    if (liteMode ?? false) {
      json.removeWhere((key, value) =>
          key != "description" &&
          key != "place_id" &&
          key != "lat" &&
          key != "lng");
    }
    json.removeWhere((key, value) => value == null);
    String jsonString = jsonEncode(json);
    // Get the current list of predictions
    List<String> currentPredictions =
        prefs.getStringList(predictionHistoryKey) ?? [];
    // max 5 predictions
    if (currentPredictions.length >= 5) {
      currentPredictions.removeAt(0);
    }
    // Add the new prediction to the list
    currentPredictions.add(jsonString);
    // Save the updated list
    prefs.setStringList(predictionHistoryKey, currentPredictions);
    log("History saved: $jsonString");
  }

  /// Get the previous predictions from shared preferences
  Future<List<Prediction>?> getPredictionsFromSharedPref();
}
