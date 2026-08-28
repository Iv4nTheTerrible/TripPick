import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:travel_recommender/data/api_recommendation_repository.dart';
import 'package:travel_recommender/data/recommendation_repository.dart';
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
  test('preserves a structured server error', () async {
    final repository = _repository(
      http.Response(
        jsonEncode({
          'error': {
            'message': 'Please correct the request.',
            'retryable': false,
          },
        }),
        400,
      ),
    );

    await expectLater(
      repository.fetch(_preferences),
      throwsA(
        isA<RecommendationException>()
            .having(
              (error) => error.kind,
              'kind',
              RecommendationFailureKind.server,
            )
            .having(
              (error) => error.message,
              'message',
              'Please correct the request.',
            )
            .having((error) => error.retryable, 'retryable', isFalse),
      ),
    );
  });

  for (final status in [408, 429, 503]) {
    test('treats a non-JSON HTTP $status response as retryable', () async {
      final repository = _repository(
        http.Response('Service unavailable', status),
      );

      await expectLater(
        repository.fetch(_preferences),
        throwsA(
          isA<RecommendationException>()
              .having(
                (error) => error.kind,
                'kind',
                RecommendationFailureKind.server,
              )
              .having((error) => error.message, 'message', isEmpty)
              .having((error) => error.retryable, 'retryable', isTrue),
        ),
      );
    });
  }

  test('treats a non-JSON ordinary 4xx response as non-retryable', () async {
    final repository = _repository(http.Response('Forbidden', 403));

    await expectLater(
      repository.fetch(_preferences),
      throwsA(
        isA<RecommendationException>()
            .having(
              (error) => error.kind,
              'kind',
              RecommendationFailureKind.server,
            )
            .having((error) => error.retryable, 'retryable', isFalse),
      ),
    );
  });

  test('keeps malformed successful responses classified as invalid', () async {
    final repository = _repository(http.Response('<html>not json</html>', 200));

    await expectLater(
      repository.fetch(_preferences),
      throwsA(
        isA<RecommendationException>().having(
          (error) => error.kind,
          'kind',
          RecommendationFailureKind.invalidResponse,
        ),
      ),
    );
  });
}

ApiRecommendationRepository _repository(http.Response response) {
  return ApiRecommendationRepository(
    baseUrl: 'http://localhost:8080',
    client: MockClient((_) async => response),
  );
}
