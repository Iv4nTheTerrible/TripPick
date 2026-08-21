import 'dart:convert';

import 'package:http/http.dart' as http;

import 'models.dart';
import 'wikimedia_image_service.dart';

abstract interface class CandidateGenerator {
  Future<List<DestinationCandidate>> generate(RecommendationRequest request);
}

class LiveRecommendationEngine implements RecommendationEngine {
  const LiveRecommendationEngine({
    required CandidateGenerator generator,
    DestinationImageResolver imageResolver =
        const EmptyDestinationImageResolver(),
  }) : _generator = generator,
       _imageResolver = imageResolver;

  final CandidateGenerator _generator;
  final DestinationImageResolver _imageResolver;

  @override
  Future<List<Map<String, Object?>>> recommend(
    RecommendationRequest request,
  ) async {
    final candidates = <DestinationCandidate>[];
    final unique = <String>{};

    for (var attempt = 0; attempt < 2 && candidates.length < 3; attempt++) {
      final generated = await _generator.generate(request);
      for (final candidate in generated) {
        if (!_matchesScope(candidate.countryCode, request)) continue;
        final key = '${candidate.city.toLowerCase()}|${candidate.countryCode}';
        if (unique.add(key)) candidates.add(candidate);
      }
    }

    if (candidates.length < 3) {
      throw const RecommendationEngineException(
        code: 'INSUFFICIENT_RESULTS',
        status: 503,
      );
    }
    return Future.wait(candidates.take(3).map(_toRecommendation));
  }

  bool _matchesScope(String countryCode, RecommendationRequest request) {
    return request.scope == 'domestic'
        ? countryCode == request.originCountry
        : countryCode != request.originCountry;
  }

  Future<Map<String, Object?>> _toRecommendation(
    DestinationCandidate candidate,
  ) async {
    final cityQuery = Uri.encodeComponent(
      '${candidate.city}, ${candidate.countryCode}',
    );
    final slug = _slug(candidate.city);
    WikimediaPhoto photo;
    try {
      photo = await _imageResolver.resolve(
        imageSearchTerm: candidate.imageSearchTerm,
        countryCode: candidate.countryCode,
      );
    } catch (_) {
      photo = const WikimediaPhoto.empty();
    }
    return {
      'placeId': 'gemini-${candidate.countryCode.toLowerCase()}-$slug',
      'city': candidate.city,
      'countryCode': candidate.countryCode,
      'reason': candidate.reason,
      'photo': photo.toJson(),
      'mapsUri': 'https://www.google.com/maps/search/?api=1&query=$cityQuery',
      'highlights': candidate.highlights.indexed
          .map((entry) {
            final index = entry.$1;
            final name = entry.$2.length > 100
                ? entry.$2.substring(0, 100)
                : entry.$2;
            final query = Uri.encodeComponent(
              '$name, ${candidate.city}, ${candidate.countryCode}',
            );
            return <String, Object?>{
              'placeId':
                  'gemini-${candidate.countryCode.toLowerCase()}-$slug-$index',
              'name': name,
              'mapsUri':
                  'https://www.google.com/maps/search/?api=1&query=$query',
              'photoUrl': '',
            };
          })
          .toList(growable: false),
    };
  }

  String _slug(String value) => value
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
      .replaceAll(RegExp(r'^-|-$'), '');
}

class GeminiCandidateGenerator implements CandidateGenerator {
  GeminiCandidateGenerator({
    required this.apiKey,
    required this.model,
    http.Client? client,
  }) : _client = client ?? http.Client();

  final String apiKey;
  final String model;
  final http.Client _client;

  @override
  Future<List<DestinationCandidate>> generate(
    RecommendationRequest request,
  ) async {
    final endpoint = Uri.https(
      'generativelanguage.googleapis.com',
      '/v1beta/models/$model:generateContent',
      {'key': apiKey},
    );
    final month = request.travelMonth?.toString() ?? 'not specified';
    final language = request.locale == 'ja' ? 'Japanese' : 'English';
    final prompt =
        '''
Recommend six distinct, real travel destination cities using your general knowledge.
Origin country: ${request.originCountry}
Scope: ${request.scope}; domestic must remain in the origin country and international must exclude it.
Budget preference: ${request.budgetLevel}. Treat this only as a soft ranking preference and never claim exact prices.
Trip length: ${request.tripDays} days
Travel month: $month
Interests: ${request.interests.join(', ')}
Write each short reason and all attraction names in $language.
For each city, provide exactly three well-known real attractions, an ISO 3166-1 alpha-2 country code, and imageSearchTerm containing the canonical English Wikipedia city article title.
imageSearchTerm must always be English even when the other text is Japanese.
Do not invent businesses, prices, ratings, opening hours, or current availability.
''';
    final body = <String, Object?>{
      'contents': [
        {
          'role': 'user',
          'parts': [
            {'text': prompt},
          ],
        },
      ],
      'generationConfig': {
        'temperature': 0.7,
        'responseMimeType': 'application/json',
        'responseSchema': {
          'type': 'OBJECT',
          'required': ['destinations'],
          'properties': {
            'destinations': {
              'type': 'ARRAY',
              'minItems': 6,
              'maxItems': 6,
              'items': {
                'type': 'OBJECT',
                'required': [
                  'city',
                  'countryCode',
                  'reason',
                  'imageSearchTerm',
                  'highlights',
                ],
                'properties': {
                  'city': {'type': 'STRING'},
                  'countryCode': {'type': 'STRING'},
                  'reason': {'type': 'STRING'},
                  'imageSearchTerm': {'type': 'STRING'},
                  'highlights': {
                    'type': 'ARRAY',
                    'minItems': 3,
                    'maxItems': 3,
                    'items': {'type': 'STRING'},
                  },
                },
              },
            },
          },
        },
      },
    };

    http.Response response;
    try {
      response = await _client
          .post(
            endpoint,
            headers: const {'content-type': 'application/json'},
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 25));
    } catch (_) {
      throw const RecommendationEngineException(
        code: 'UPSTREAM_UNAVAILABLE',
        status: 503,
      );
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw const RecommendationEngineException(
        code: 'UPSTREAM_UNAVAILABLE',
        status: 503,
      );
    }

    try {
      final envelope = jsonDecode(response.body) as Map<String, Object?>;
      final candidates = envelope['candidates'] as List;
      final first = Map<String, Object?>.from(candidates.first as Map);
      final content = Map<String, Object?>.from(first['content'] as Map);
      final parts = content['parts'] as List;
      final part = Map<String, Object?>.from(parts.first as Map);
      final structured =
          jsonDecode(part['text'] as String) as Map<String, Object?>;
      final destinations = structured['destinations'] as List;
      return destinations
          .map(
            (item) => DestinationCandidate.fromJson(
              Map<String, Object?>.from(item as Map),
            ),
          )
          .toList(growable: false);
    } catch (_) {
      throw const RecommendationEngineException(
        code: 'UPSTREAM_INVALID_RESPONSE',
        status: 502,
      );
    }
  }
}
