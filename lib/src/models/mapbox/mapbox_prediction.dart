import '../prediction.dart';

class MapboxPrediction extends Prediction {
  MapboxPrediction({
    required super.id,
    required super.name,
    super.types,
    super.details,
    super.region,
    super.country,
    super.postalCode,
    super.lat,
    super.lng,
  });

  @override
  MapboxPrediction.fromJson(Map<String, dynamic> json)
      : super(
          id: json['mapbox_id'],
          name: json['name_preferred'] ?? json['name'],
          types: [json['type']],
          region: json['context']['region'] != null
              ? json['context']['region']['region_code']
              : null,
          country: json['context']['country'] != null
              ? json['context']['country']['country_code']
              : null,
          postalCode: json['context']['postcode'] != null
              ? json['context']['postcode']['name']
              : null,
        );

  @override
  Map<String, dynamic> toJson() {
    return {
      'mapbox_id': id,
      'name': name,
      'type': types.first,
      'context': {
        if (region != null) 'region': {'region_code': region},
        if (country != null) 'country': {'country_code': country},
        if (postalCode != null) 'postcode': {'name': postalCode},
      },
    };
  }

  @override
  bool operator ==(Object other) {
    return super == other &&
        other is MapboxPrediction &&
        runtimeType == other.runtimeType;
  }

  @override
  int get hashCode => super.hashCode;
}
