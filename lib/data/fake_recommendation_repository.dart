import '../domain/recommendation.dart';
import '../domain/travel_preferences.dart';
import 'recommendation_repository.dart';

class FakeRecommendationRepository implements RecommendationRepository {
  const FakeRecommendationRepository({
    this.delay = const Duration(milliseconds: 500),
  });

  final Duration delay;

  @override
  Future<List<DestinationRecommendation>> fetch(
    TravelPreferences preferences,
  ) async {
    await Future<void>.delayed(delay);
    final isJapanese = preferences.locale == 'ja';
    final domestic = preferences.scope == TravelScope.domestic;
    final cities = domestic
        ? [
            _FakeCity('Kyoto', '京都', preferences.originCountry),
            _FakeCity('Kanazawa', '金沢', preferences.originCountry),
            _FakeCity('Sapporo', '札幌', preferences.originCountry),
          ]
        : const [
            _FakeCity('Lisbon', 'リスボン', 'PT'),
            _FakeCity('Reykjavik', 'レイキャビク', 'IS'),
            _FakeCity('Seoul', 'ソウル', 'KR'),
            _FakeCity('Vancouver', 'バンクーバー', 'CA'),
          ];
    final selected = cities
        .where(
          (city) => domestic || city.countryCode != preferences.originCountry,
        )
        .take(3);
    return selected
        .map((city) {
          final displayCity = isJapanese ? city.ja : city.en;
          final reason = isJapanese
              ? '選択した興味や旅行スタイルに合う、歩いて楽しみやすい旅先です。'
              : 'A walkable destination that matches your selected interests and travel style.';
          final query = Uri.encodeComponent(city.en);
          return DestinationRecommendation(
            placeId: 'fake-${city.en.toLowerCase()}',
            city: displayCity,
            countryCode: city.countryCode,
            reason: reason,
            photo: const PlacePhoto(url: '', attribution: ''),
            mapsUri: 'https://www.google.com/maps/search/?api=1&query=$query',
            highlights: List.generate(3, (index) {
              final number = index + 1;
              return DestinationHighlight(
                placeId: 'fake-${city.en}-$number',
                name: isJapanese
                    ? 'おすすめスポット $number'
                    : 'Recommended place $number',
                mapsUri:
                    'https://www.google.com/maps/search/?api=1&query=$query',
                photoUrl: '',
              );
            }),
          );
        })
        .toList(growable: false);
  }
}

class _FakeCity {
  const _FakeCity(this.en, this.ja, this.countryCode);

  final String en;
  final String ja;
  final String countryCode;
}
