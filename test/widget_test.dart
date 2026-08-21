import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:travel_recommender/app.dart';
import 'package:travel_recommender/data/fake_recommendation_repository.dart';

void main() {
  testWidgets('renders the English form and three fake recommendations', (
    tester,
  ) async {
    await tester.pumpWidget(
      const TripPickApp(
        initialLocale: Locale('en'),
        repository: FakeRecommendationRepository(delay: Duration.zero),
      ),
    );

    expect(find.text('Not sure where to go next?'), findsOneWidget);
    expect(find.byKey(const Key('submitPreferences')), findsOneWidget);

    await tester.ensureVisible(find.byKey(const Key('submitPreferences')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('submitPreferences')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('recommendationResults')), findsOneWidget);
    expect(find.text('Kyoto · JP'), findsOneWidget);
    expect(find.text('Kanazawa · JP'), findsOneWidget);
    expect(find.text('Sapporo · JP'), findsOneWidget);
    expect(find.text('Open in Google Maps'), findsNWidgets(3));
  });

  testWidgets('switches between Japanese and English', (tester) async {
    var savedLanguage = '';
    await tester.pumpWidget(
      TripPickApp(
        initialLocale: const Locale('ja'),
        repository: const FakeRecommendationRepository(delay: Duration.zero),
        onLocaleChanged: (locale) async {
          savedLanguage = locale.languageCode;
        },
      ),
    );

    expect(find.text('次の旅先が決まらない？'), findsOneWidget);
    await tester.tap(find.text('EN'));
    await tester.pumpAndSettle();

    expect(find.text('Not sure where to go next?'), findsOneWidget);
    expect(savedLanguage, 'en');
  });
}
