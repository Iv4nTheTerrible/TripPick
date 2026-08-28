import 'package:flutter/foundation.dart';

import '../data/recommendation_repository.dart';
import '../domain/recommendation.dart';
import '../domain/travel_preferences.dart';

enum RecommendationStatus { initial, loading, success, failure }

class RecommendationController extends ChangeNotifier {
  RecommendationController(this._repository);

  final RecommendationRepository _repository;

  RecommendationStatus status = RecommendationStatus.initial;
  List<DestinationRecommendation> recommendations = const [];
  TravelPreferences? lastPreferences;
  RecommendationException? failure;

  Future<void> fetch(TravelPreferences preferences) async {
    lastPreferences = preferences;
    status = RecommendationStatus.loading;
    failure = null;
    notifyListeners();
    try {
      recommendations = await _repository.fetch(preferences);
      status = RecommendationStatus.success;
    } on RecommendationException catch (error) {
      recommendations = const [];
      failure = error;
      status = RecommendationStatus.failure;
    } catch (_) {
      recommendations = const [];
      failure = const RecommendationException(
        kind: RecommendationFailureKind.server,
      );
      status = RecommendationStatus.failure;
    }
    notifyListeners();
  }

  Future<void> retry() async {
    final preferences = lastPreferences;
    if (preferences != null) await fetch(preferences);
  }

  void reset() {
    status = RecommendationStatus.initial;
    recommendations = const [];
    failure = null;
    notifyListeners();
  }
}
