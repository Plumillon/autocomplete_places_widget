import 'package:autocomplete_places_widget/src/models/place_details.dart';

class MapboxPlaceDetails extends PlaceDetails {
  final String type;
  final List<Feature> features;
  final String? attribution;

  MapboxPlaceDetails({
    required this.type,
    required this.features,
    this.attribution,
  });

  factory MapboxPlaceDetails.fromJson(Map<String, dynamic> json) {
    return MapboxPlaceDetails(
      type: json['type'],
      features:
          (json['features'] as List).map((e) => Feature.fromJson(e)).toList(),
      attribution: json['attribution'],
    );
  }

  @override
  Map<String, dynamic> toJson() => {
        'type': type,
        'features': features.map((e) => e.toJson()).toList(),
        if (attribution != null) 'attribution': attribution,
      };
}

class Feature {
  final String type;
  final Geometry geometry;
  final Properties properties;
  final List<double>? bbox;

  Feature({
    required this.type,
    required this.geometry,
    required this.properties,
    this.bbox,
  });

  factory Feature.fromJson(Map<String, dynamic> json) {
    return Feature(
      type: json['type'],
      geometry: Geometry.fromJson(json['geometry']),
      properties: Properties.fromJson(json['properties']),
      bbox: json['bbox'] != null ? List<double>.from(json['bbox']) : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'type': type,
        'geometry': geometry.toJson(),
        'properties': properties.toJson(),
        if (bbox != null) 'bbox': bbox,
      };
}

class Geometry {
  final String type;
  final List<double> coordinates;

  Geometry({
    required this.type,
    required this.coordinates,
  });

  factory Geometry.fromJson(Map<String, dynamic> json) {
    return Geometry(
      type: json['type'],
      coordinates: List<double>.from(json['coordinates']),
    );
  }

  Map<String, dynamic> toJson() => {
        'type': type,
        'coordinates': coordinates,
      };
}

class Properties {
  final String name;
  final String? mapboxId;
  final String? featureType;
  final String? address;
  final String? fullAddress;
  final String? placeFormatted;
  final Context? context;
  final Coordinates? coordinates;
  final String? maki;
  final List<String>? poiCategory;
  final List<String>? poiCategoryIds;
  final Map<String, dynamic>? externalIds;
  final Map<String, dynamic>? metadata;

  Properties({
    required this.name,
    this.mapboxId,
    this.featureType,
    this.address,
    this.fullAddress,
    this.placeFormatted,
    this.context,
    this.coordinates,
    this.maki,
    this.poiCategory,
    this.poiCategoryIds,
    this.externalIds,
    this.metadata,
  });

  factory Properties.fromJson(Map<String, dynamic> json) {
    return Properties(
      name: json['name'],
      mapboxId: json['mapbox_id'],
      featureType: json['feature_type'],
      address: json['address'],
      fullAddress: json['full_address'],
      placeFormatted: json['place_formatted'],
      context:
          json['context'] != null ? Context.fromJson(json['context']) : null,
      coordinates: json['coordinates'] != null
          ? Coordinates.fromJson(json['coordinates'])
          : null,
      maki: json['maki'],
      poiCategory: json['poi_category'] != null
          ? List<String>.from(json['poi_category'])
          : null,
      poiCategoryIds: json['poi_category_ids'] != null
          ? List<String>.from(json['poi_category_ids'])
          : null,
      externalIds: json['external_ids'],
      metadata: json['metadata'],
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        if (mapboxId != null) 'mapbox_id': mapboxId,
        if (featureType != null) 'feature_type': featureType,
        if (address != null) 'address': address,
        if (fullAddress != null) 'full_address': fullAddress,
        if (placeFormatted != null) 'place_formatted': placeFormatted,
        if (context != null) 'context': context!.toJson(),
        if (coordinates != null) 'coordinates': coordinates!.toJson(),
        if (maki != null) 'maki': maki,
        if (poiCategory != null) 'poi_category': poiCategory,
        if (poiCategoryIds != null) 'poi_category_ids': poiCategoryIds,
        if (externalIds != null) 'external_ids': externalIds,
        if (metadata != null) 'metadata': metadata,
      };
}

class Coordinates {
  final double latitude;
  final double longitude;

  Coordinates({
    required this.latitude,
    required this.longitude,
  });

  factory Coordinates.fromJson(Map<String, dynamic> json) {
    return Coordinates(
      latitude: json['latitude'],
      longitude: json['longitude'],
    );
  }

  Map<String, dynamic> toJson() => {
        'latitude': latitude,
        'longitude': longitude,
      };
}

class Context {
  final String? country;
  final String? region;
  final String? place;
  final String? postcode;
  final String? neighborhood;
  final String? street;

  Context(
      {this.country,
      this.region,
      this.place,
      this.postcode,
      this.neighborhood,
      this.street});

  factory Context.fromJson(Map<String, dynamic> json) => Context(
        region: json['region'] != null ? json['region']['region_code'] : null,
        place: json['place'] != null ? json['place']['name'] : null,
        country:
            json['country'] != null ? json['country']['country_code'] : null,
        postcode: json['postcode'] != null ? json['postcode']['name'] : null,
        neighborhood:
            json['neighborhood'] != null ? json['neighborhood']['name'] : null,
        street: json['street'] != null ? json['street']['name'] : null,
      );

  Map<String, dynamic> toJson() => {
        if (country != null) 'country': country,
        if (region != null) 'region': region,
        if (place != null) 'place': place,
        if (postcode != null) 'postcode': postcode,
        if (neighborhood != null) 'neighborhood': neighborhood,
        if (street != null) 'street': street,
      };
}
