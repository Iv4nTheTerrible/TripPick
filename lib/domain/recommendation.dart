class PlacePhoto {
  const PlacePhoto({required this.url, required this.attribution});

  final String url;
  final String attribution;

  factory PlacePhoto.fromJson(Map<String, Object?> json) {
    return PlacePhoto(
      url: json['url'] as String? ?? '',
      attribution: json['attribution'] as String? ?? '',
    );
  }
}

class DestinationHighlight {
  const DestinationHighlight({
    required this.placeId,
    required this.name,
    required this.mapsUri,
    required this.photoUrl,
  });

  final String placeId;
  final String name;
  final String mapsUri;
  final String photoUrl;

  factory DestinationHighlight.fromJson(Map<String, Object?> json) {
    return DestinationHighlight(
      placeId: _requiredString(json, 'placeId'),
      name: _requiredString(json, 'name'),
      mapsUri: _requiredString(json, 'mapsUri'),
      photoUrl: json['photoUrl'] as String? ?? '',
    );
  }
}

class DestinationRecommendation {
  const DestinationRecommendation({
    required this.placeId,
    required this.city,
    required this.countryCode,
    required this.reason,
    required this.photo,
    required this.mapsUri,
    required this.highlights,
  });

  final String placeId;
  final String city;
  final String countryCode;
  final String reason;
  final PlacePhoto photo;
  final String mapsUri;
  final List<DestinationHighlight> highlights;

  factory DestinationRecommendation.fromJson(Map<String, Object?> json) {
    final photoJson = json['photo'];
    final highlightJson = json['highlights'];
    if (photoJson is! Map || highlightJson is! List) {
      throw const FormatException('Invalid recommendation payload.');
    }
    final highlights = highlightJson
        .map(
          (item) => DestinationHighlight.fromJson(
            Map<String, Object?>.from(item as Map),
          ),
        )
        .toList(growable: false);
    if (highlights.length != 3) {
      throw const FormatException('A destination must have three highlights.');
    }
    return DestinationRecommendation(
      placeId: _requiredString(json, 'placeId'),
      city: _requiredString(json, 'city'),
      countryCode: _requiredString(json, 'countryCode'),
      reason: _requiredString(json, 'reason'),
      photo: PlacePhoto.fromJson(Map<String, Object?>.from(photoJson)),
      mapsUri: _requiredString(json, 'mapsUri'),
      highlights: highlights,
    );
  }
}

String _requiredString(Map<String, Object?> json, String key) {
  final value = json[key];
  if (value is! String || value.trim().isEmpty) {
    throw FormatException('Missing $key.');
  }
  return value;
}
