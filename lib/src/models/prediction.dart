import 'package:autocomplete_places_widget/src/models/place_details.dart';

abstract class Prediction {
  late final String name;
  late final String id;
  late final List<String> types;

  /// This field is filled during the second request
  PlaceDetails? details;

  /// Those fields could be used to have details
  /// without the need to fetch them in a second request
  /// They are not always filled
  String? region;
  String? country;
  String? postalCode;
  double? lat;
  double? lng;

  bool get hasLatLng => lat != null && lng != null;

  Prediction({
    required this.name,
    required this.id,
    this.types = const [],
    this.details,
    this.region,
    this.country,
    this.postalCode,
    this.lat,
    this.lng,
  });

  Prediction.fromJson(Map<String, dynamic> json);

  Map<String, dynamic> toJson();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is Prediction &&
            runtimeType == other.runtimeType &&
            id == other.id &&
            name == other.name &&
            types == other.types &&
            region == other.region &&
            country == other.country &&
            postalCode == other.postalCode &&
            lat == other.lat &&
            lng == other.lng;
  }

  @override
  int get hashCode =>
      id.hashCode ^
      name.hashCode ^
      types.hashCode ^
      region.hashCode ^
      country.hashCode ^
      postalCode.hashCode ^
      lat.hashCode ^
      lng.hashCode;
}
