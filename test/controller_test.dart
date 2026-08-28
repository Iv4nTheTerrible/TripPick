import 'package:flutter_test/flutter_test.dart';
import 'package:travel_recommender/controllers/recommendation_controller.dart';
import 'package:travel_recommender/data/fake_recommendation_repository.dart';
import 'package:travel_recommender/data/recommendation_repository.dart';
import 'package:travel_recommender/domain/recommendation.dart';
import 'package:travel_recommender/domain/travel_preferences.dart';

const _preferences = TravelPreferences(
  originCountry: 'JP',
  scope: TravelScope.domestic,
  budgetLevel: BudgetLevel.medium,
  tripDays: 4,
  interests: [TravelInterest.culture],
  locale: 'en',
);

void main() {
  test('controller transitions from loading to success', () async {
    final controller = RecommendationController(
      const FakeRecommendationRepository(delay: Duration.zero),
    );
    final states = <RecommendationStatus>[];
    controller.addListener(() => states.add(controller.status));
    await controller.fetch(_preferences);
    expect(states, [
      RecommendationStatus.loading,
      RecommendationStatus.success,
    ]);
    expect(controller.recommendations, hasLength(3));
  });

  test('controller exposes repository failures and supports retry', () async {
    final repository = _FailOnceRepository();
    final controller = RecommendationController(repository);
    await controller.fetch(_preferences);
    expect(controller.status, RecommendationStatus.failure);
    expect(controller.failure?.kind, RecommendationFailureKind.connection);
    await controller.retry();
    expect(controller.status, RecommendationStatus.success);
    expect(controller.recommendations, hasLength(3));
  });
}

class _FailOnceRepository implements RecommendationRepository {
  var calls = 0;

  @override
  Future<List<DestinationRecommendation>> fetch(TravelPreferences preferences) {
    calls++;
    if (calls == 1) {
      throw const RecommendationException(
        kind: RecommendationFailureKind.connection,
      );
    }
    return const FakeRecommendationRepository(
      delay: Duration.zero,
    ).fetch(preferences);
  }
}
