abstract class PlaceDetails {
  String? region;
  String? country;
  String? postalCode;
  String? lat;
  String? lng;

  PlaceDetails({
    this.region,
    this.country,
    this.postalCode,
    this.lat,
    this.lng,
  });

  PlaceDetails.fromJson(Map<String, dynamic> json);

  Map<String, dynamic> toJson();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is PlaceDetails &&
            runtimeType == other.runtimeType &&
            region == other.region &&
            country == other.country &&
            postalCode == other.postalCode &&
            lat == other.lat &&
            lng == other.lng;
  }

  @override
  int get hashCode =>
      region.hashCode ^
      country.hashCode ^
      postalCode.hashCode ^
      lat.hashCode ^
      lng.hashCode;
}
