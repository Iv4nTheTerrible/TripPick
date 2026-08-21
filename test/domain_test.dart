import 'package:flutter_test/flutter_test.dart';
import 'package:travel_recommender/domain/recommendation.dart';
import 'package:travel_recommender/domain/travel_preferences.dart';

void main() {
  test('serializes recommendation preferences to the API contract', () {
    const preferences = TravelPreferences(
      originCountry: 'JP',
      scope: TravelScope.international,
      budgetLevel: BudgetLevel.medium,
      tripDays: 5,
      interests: [TravelInterest.food, TravelInterest.culture],
      travelMonth: 10,
      locale: 'en',
    );
    expect(preferences.toJson(), {
      'originCountry': 'JP',
      'scope': 'international',
      'budgetLevel': 'medium',
      'tripDays': 5,
      'interests': ['food', 'culture'],
      'travelMonth': 10,
      'locale': 'en',
    });
  });

  test('rejects a destination without exactly three highlights', () {
    expect(
      () => DestinationRecommendation.fromJson({
        'placeId': 'city',
        'city': 'Kyoto',
        'countryCode': 'JP',
        'reason': 'Reason',
        'photo': {'url': '', 'attribution': ''},
        'mapsUri': 'https://maps.example/city',
        'highlights': <Object?>[],
      }),
      throwsFormatException,
    );
  });
}
