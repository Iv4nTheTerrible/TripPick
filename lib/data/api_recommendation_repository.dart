import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../domain/recommendation.dart';
import '../domain/travel_preferences.dart';
import 'recommendation_repository.dart';

class ApiRecommendationRepository implements RecommendationRepository {
  ApiRecommendationRepository({
    required String baseUrl,
    http.Client? client,
    this.timeout = const Duration(seconds: 30),
  }) : _baseUrl = baseUrl.replaceFirst(RegExp(r'/+$'), ''),
       _client = client ?? http.Client();

  final String _baseUrl;
  final http.Client _client;
  final Duration timeout;

  @override
  Future<List<DestinationRecommendation>> fetch(
    TravelPreferences preferences,
  ) async {
    try {
      final response = await _client
          .post(
            Uri.parse('$_baseUrl/v1/recommendations'),
            headers: const {'content-type': 'application/json'},
            body: jsonEncode(preferences.toJson()),
          )
          .timeout(timeout);

      final decoded = jsonDecode(response.body);
      if (response.statusCode != 200) {
        final error = decoded is Map ? decoded['error'] : null;
        final errorMap = error is Map ? error : const {};
        throw RecommendationException(
          kind: RecommendationFailureKind.server,
          message: errorMap['message'] as String? ?? '',
          retryable: errorMap['retryable'] as bool? ?? true,
        );
      }
      if (decoded is! Map || decoded['recommendations'] is! List) {
        throw const RecommendationException(
          kind: RecommendationFailureKind.invalidResponse,
        );
      }
      final recommendations = (decoded['recommendations'] as List)
          .map(
            (item) => DestinationRecommendation.fromJson(
              Map<String, Object?>.from(item as Map),
            ),
          )
          .toList(growable: false);
      if (recommendations.length != 3) {
        throw const RecommendationException(
          kind: RecommendationFailureKind.invalidResponse,
        );
      }
      return recommendations;
    } on RecommendationException {
      rethrow;
    } on TimeoutException catch (_) {
      throw const RecommendationException(
        kind: RecommendationFailureKind.connection,
      );
    } on http.ClientException catch (_) {
      throw const RecommendationException(
        kind: RecommendationFailureKind.connection,
      );
    } on FormatException catch (_) {
      throw const RecommendationException(
        kind: RecommendationFailureKind.invalidResponse,
      );
    } on TypeError catch (_) {
      throw const RecommendationException(
        kind: RecommendationFailureKind.invalidResponse,
      );
    }
  }
}
