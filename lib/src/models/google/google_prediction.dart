import '../prediction.dart';
import 'matched_substrings.dart';
import 'structured_formatting.dart';
import 'term.dart';

class GooglePrediction extends Prediction {
  List<MatchedSubstring>? matchedSubstrings;
  StructuredFormatting? structuredFormatting;
  List<Term>? terms;

  GooglePrediction({
    required super.id,
    required super.name,
    super.types,
    super.details,
    this.matchedSubstrings,
    this.structuredFormatting,
    this.terms,
  });

  @override
  GooglePrediction.fromJson(Map<String, dynamic> json)
      : super(
          id: json['place_id'],
          name: json['description'],
          types: json['types'].cast<String>(),
        ) {
    matchedSubstrings = json['matched_substrings'] != null
        ? List<MatchedSubstring>.from(
            json['matched_substrings'].map((x) => MatchedSubstring.fromJson(x)))
        : null;
    structuredFormatting = json['structured_formatting'] != null
        ? StructuredFormatting.fromJson(json['structured_formatting'])
        : null;
    terms = json['terms'] != null
        ? List<Term>.from(json['terms'].map((x) => Term.fromJson(x)))
        : null;
  }

  @override
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['description'] = name;
    data['id'] = id;
    if (matchedSubstrings != null) {
      data['matched_substrings'] =
          matchedSubstrings!.map((v) => v.toJson()).toList();
    }
    data['place_id'] = id;
    if (structuredFormatting != null) {
      data['structured_formatting'] = structuredFormatting!.toJson();
    }
    if (terms != null) {
      data['terms'] = terms!.map((v) => v.toJson()).toList();
    }
    data['types'] = types;
    data['details'] = details?.toJson();

    return data;
  }

  @override
  bool operator ==(Object other) {
    return super == other &&
        other is GooglePrediction &&
        runtimeType == other.runtimeType &&
        matchedSubstrings == other.matchedSubstrings &&
        structuredFormatting == other.structuredFormatting &&
        terms == other.terms;
  }

  @override
  int get hashCode =>
      super.hashCode ^
      matchedSubstrings.hashCode ^
      structuredFormatting.hashCode ^
      terms.hashCode;
}

class GoogleNewPrediction extends GooglePrediction {
  GoogleNewPrediction({required super.id, required super.name});

  @override
  GoogleNewPrediction.fromJson(Map<String, dynamic> json)
      : super(
          id: json['placeId'],
          name: json['text'] != null ? json['text']['text'] : '',
          types: json['types'].cast<String>(),
        ) {
    structuredFormatting = json['structuredFormat'] != null
        ? StructuredFormatting.fromJsonNewApi(json['structuredFormat'])
        : null;
  }
}
