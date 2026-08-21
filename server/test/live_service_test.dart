import 'package:test/test.dart';
import 'package:trip_pick_server/trip_pick_server.dart';

const _request = RecommendationRequest(
  originCountry: 'JP',
  scope: 'international',
  budgetLevel: 'medium',
  tripDays: 5,
  interests: ['culture'],
  locale: 'en',
);
const _highlights = ['One', 'Two', 'Three'];

void main() {
  test('filters duplicates and out-of-scope candidates', () async {
    final engine = LiveRecommendationEngine(generator: _Generator());
    final results = await engine.recommend(_request);
    expect(results, hasLength(3));
    expect(
      results.map((item) => item['countryCode']),
      everyElement(isNot('JP')),
    );
    expect(results.map((item) => item['placeId']).toSet(), hasLength(3));
    expect(
      results.map((item) => item['highlights']),
      everyElement(hasLength(3)),
    );
  });

  test('request validation enforces interest and day boundaries', () {
    expect(
      () => RecommendationRequest.fromJson({
        'originCountry': 'Japan',
        'scope': 'domestic',
        'budgetLevel': 'medium',
        'tripDays': 31,
        'interests': <String>[],
        'locale': 'en',
      }),
      throwsA(isA<ValidationFailure>()),
    );
  });
}

class _Generator implements CandidateGenerator {
  @override
  Future<List<DestinationCandidate>> generate(
    RecommendationRequest request,
  ) async {
    return const [
      DestinationCandidate(
        city: 'Kyoto',
        countryCode: 'JP',
        reason: 'Domestic',
        highlights: _highlights,
      ),
      DestinationCandidate(
        city: 'Lisbon',
        countryCode: 'PT',
        reason: 'Culture',
        highlights: _highlights,
      ),
      DestinationCandidate(
        city: 'Lisbon',
        countryCode: 'PT',
        reason: 'Duplicate',
        highlights: _highlights,
      ),
      DestinationCandidate(
        city: 'Seoul',
        countryCode: 'KR',
        reason: 'Food',
        highlights: _highlights,
      ),
      DestinationCandidate(
        city: 'Paris',
        countryCode: 'FR',
        reason: 'Museums',
        highlights: _highlights,
      ),
      DestinationCandidate(
        city: 'Rome',
        countryCode: 'IT',
        reason: 'History',
        highlights: _highlights,
      ),
    ];
  }
}
