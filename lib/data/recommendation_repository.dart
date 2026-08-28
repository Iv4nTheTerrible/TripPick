import '../domain/recommendation.dart';
import '../domain/travel_preferences.dart';

enum RecommendationFailureKind { connection, invalidResponse, server }

class RecommendationException implements Exception {
  const RecommendationException({
    required this.kind,
    this.message = '',
    this.retryable = true,
  });

  final RecommendationFailureKind kind;
  final String message;
  final bool retryable;
}

abstract interface class RecommendationRepository {
  Future<List<DestinationRecommendation>> fetch(TravelPreferences preferences);
}
