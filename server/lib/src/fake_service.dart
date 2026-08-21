import 'models.dart';

class FakeRecommendationEngine implements RecommendationEngine {
  const FakeRecommendationEngine();

  @override
  Future<List<Map<String, Object?>>> recommend(
    RecommendationRequest request,
  ) async {
    final domestic = request.scope == 'domestic';
    final japanese = request.locale == 'ja';
    final source = domestic
        ? [
            ('Kyoto', '京都', request.originCountry),
            ('Kanazawa', '金沢', request.originCountry),
            ('Sapporo', '札幌', request.originCountry),
          ]
        : const [
            ('Lisbon', 'リスボン', 'PT'),
            ('Reykjavik', 'レイキャビク', 'IS'),
            ('Seoul', 'ソウル', 'KR'),
            ('Vancouver', 'バンクーバー', 'CA'),
            ('Melbourne', 'メルボルン', 'AU'),
          ];
    final cities = source
        .where((city) => domestic || city.$3 != request.originCountry)
        .take(3)
        .toList();
    if (cities.length != 3) {
      throw const RecommendationEngineException(
        code: 'INSUFFICIENT_RESULTS',
        status: 503,
      );
    }
    return cities
        .map((city) {
          final englishName = city.$1;
          final name = japanese ? city.$2 : englishName;
          final mapsUri =
              'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(englishName)}';
          return <String, Object?>{
            'placeId': 'fake-${englishName.toLowerCase()}',
            'city': name,
            'countryCode': city.$3,
            'reason': japanese
                ? '選択した興味や旅行スタイルに合う、歩いて楽しみやすい旅先です。'
                : 'A walkable destination that matches your selected interests and travel style.',
            'photo': <String, Object?>{'url': '', 'attribution': ''},
            'mapsUri': mapsUri,
            'highlights': List.generate(
              3,
              (index) => <String, Object?>{
                'placeId': 'fake-$englishName-${index + 1}',
                'name': japanese
                    ? 'おすすめスポット ${index + 1}'
                    : 'Recommended place ${index + 1}',
                'mapsUri': mapsUri,
                'photoUrl': '',
              },
            ),
          };
        })
        .toList(growable: false);
  }
}
