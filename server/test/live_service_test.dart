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
    final imageResolver = _ImageResolver();
    final engine = LiveRecommendationEngine(
      generator: _Generator(),
      imageResolver: imageResolver,
    );
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
    expect(imageResolver.searchTerms, ['Lisbon', 'Seoul', 'Paris']);
    expect(
      results.map((item) => (item['photo'] as Map)['sourceUrl']),
      everyElement(contains('commons.wikimedia.org')),
    );
  });

  test('image failures do not fail recommendations', () async {
    final engine = LiveRecommendationEngine(
      generator: _Generator(),
      imageResolver: _ThrowingImageResolver(),
    );
    final results = await engine.recommend(_request);
    expect(results, hasLength(3));
    expect(
      results.map((item) => (item['photo'] as Map)['url']),
      everyElement(isEmpty),
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
        imageSearchTerm: 'Kyoto',
        highlights: _highlights,
      ),
      DestinationCandidate(
        city: 'Lisbon',
        countryCode: 'PT',
        reason: 'Culture',
        imageSearchTerm: 'Lisbon',
        highlights: _highlights,
      ),
      DestinationCandidate(
        city: 'Lisbon',
        countryCode: 'PT',
        reason: 'Duplicate',
        imageSearchTerm: 'Lisbon',
        highlights: _highlights,
      ),
      DestinationCandidate(
        city: 'Seoul',
        countryCode: 'KR',
        reason: 'Food',
        imageSearchTerm: 'Seoul',
        highlights: _highlights,
      ),
      DestinationCandidate(
        city: 'Paris',
        countryCode: 'FR',
        reason: 'Museums',
        imageSearchTerm: 'Paris',
        highlights: _highlights,
      ),
      DestinationCandidate(
        city: 'Rome',
        countryCode: 'IT',
        reason: 'History',
        imageSearchTerm: 'Rome',
        highlights: _highlights,
      ),
    ];
  }
}

class _ImageResolver implements DestinationImageResolver {
  final searchTerms = <String>[];

  @override
  Future<WikimediaPhoto> resolve({
    required String imageSearchTerm,
    required String countryCode,
  }) async {
    searchTerms.add(imageSearchTerm);
    return WikimediaPhoto(
      url: 'https://upload.wikimedia.org/$imageSearchTerm.jpg',
      attribution: 'Photographer · CC BY-SA 4.0',
      sourceUrl: 'https://commons.wikimedia.org/wiki/File:$imageSearchTerm.jpg',
      licenseUrl: 'https://creativecommons.org/licenses/by-sa/4.0/',
    );
  }
}

class _ThrowingImageResolver implements DestinationImageResolver {
  @override
  Future<WikimediaPhoto> resolve({
    required String imageSearchTerm,
    required String countryCode,
  }) => throw StateError('Image service unavailable');
}
