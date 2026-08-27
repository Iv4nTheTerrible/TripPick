import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:travel_recommender/app.dart';
import 'package:travel_recommender/data/fake_recommendation_repository.dart';
import 'package:travel_recommender/data/recommendation_repository.dart';
import 'package:travel_recommender/domain/recommendation.dart';
import 'package:travel_recommender/domain/travel_preferences.dart';
import 'package:travel_recommender/theme/trip_pick_theme.dart';

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

    expect(find.text('Three places worth considering.'), findsOneWidget);
    expect(find.byKey(const Key('submitPreferences')), findsOneWidget);

    await tester.ensureVisible(find.byKey(const Key('submitPreferences')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('submitPreferences')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('recommendationResults')), findsOneWidget);
    expect(find.text('Kyoto'), findsOneWidget);
    expect(find.text('Kanazawa'), findsOneWidget);
    expect(find.text('Sapporo'), findsOneWidget);
    expect(find.text('01'), findsOneWidget);
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

    expect(find.text('次の旅に、ちょうどいい3都市。'), findsOneWidget);
    await tester.tap(find.byKey(const Key('languageMenu')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('English'));
    await tester.pumpAndSettle();

    expect(find.text('Three places worth considering.'), findsOneWidget);
    expect(savedLanguage, 'en');
  });

  testWidgets('switches and reports the selected theme mode', (tester) async {
    ThemeMode? savedThemeMode;
    await tester.pumpWidget(
      TripPickApp(
        initialLocale: const Locale('en'),
        initialThemeMode: ThemeMode.light,
        repository: const FakeRecommendationRepository(delay: Duration.zero),
        onThemeModeChanged: (mode) async => savedThemeMode = mode,
      ),
    );

    expect(
      tester.widget<MaterialApp>(find.byType(MaterialApp)).themeMode,
      ThemeMode.light,
    );
    await tester.tap(find.byKey(const Key('themeModeMenu')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('themeMode-dark')));
    await tester.pumpAndSettle();

    expect(savedThemeMode, ThemeMode.dark);
    expect(
      tester.widget<MaterialApp>(find.byType(MaterialApp)).themeMode,
      ThemeMode.dark,
    );
  });

  testWidgets('shows invalid trip days while keeping submission disabled', (
    tester,
  ) async {
    await tester.pumpWidget(
      const TripPickApp(
        initialLocale: Locale('en'),
        repository: FakeRecommendationRepository(delay: Duration.zero),
      ),
    );

    final days = find.byKey(const Key('tripDays'));
    final submit = find.byKey(const Key('submitPreferences'));
    for (final invalidValue in ['0', '', '31']) {
      await tester.enterText(days, invalidValue);
      await tester.pump();
      expect(find.text('Enter a number from 1 to 30.'), findsOneWidget);
      expect(tester.widget<FilledButton>(submit).onPressed, isNull);
    }

    await tester.enterText(days, '4');
    await tester.pump();
    expect(find.text('Enter a number from 1 to 30.'), findsNothing);
    expect(tester.widget<FilledButton>(submit).onPressed, isNotNull);
  });

  testWidgets('keeps budget labels on one line at mobile width', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      const TripPickApp(
        initialLocale: Locale('en'),
        repository: FakeRecommendationRepository(delay: Duration.zero),
      ),
    );
    await tester.pumpAndSettle();

    final budget = find.byKey(const Key('budgetLevel'));
    expect(
      find.descendant(of: budget, matching: find.byType(FittedBox)),
      findsNWidgets(3),
    );
    for (final label in ['Low', 'Medium', 'High']) {
      expect(tester.widget<Text>(find.text(label)).maxLines, 1);
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('renders a city photo with clickable Commons attribution', (
    tester,
  ) async {
    await tester.pumpWidget(
      const TripPickApp(
        initialLocale: Locale('en'),
        repository: _PhotoRepository(),
      ),
    );
    await tester.ensureVisible(find.byKey(const Key('submitPreferences')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('submitPreferences')));
    await tester.pump();
    await tester.pump();

    expect(find.byType(Image), findsWidgets);
    final attribution = find.byKey(const Key('photoAttribution-City 1'));
    expect(attribution, findsOneWidget);
    expect(tester.widget<InkWell>(attribution).onTap, isNotNull);
    expect(find.text('Author · CC BY-SA 4.0'), findsNWidgets(3));
  });

  testWidgets('interest tiles keep explicit readable colors in dark mode', (
    tester,
  ) async {
    await tester.pumpWidget(
      const TripPickApp(
        initialLocale: Locale('en'),
        initialThemeMode: ThemeMode.dark,
        repository: FakeRecommendationRepository(delay: Duration.zero),
      ),
    );

    final selectedTile = find.byKey(const Key('interest-food'));
    final unselectedTile = find.byKey(const Key('interest-nature'));
    final selectedLabel = tester.widget<Text>(
      find.descendant(of: selectedTile, matching: find.text('Food')),
    );
    final unselectedLabel = tester.widget<Text>(
      find.descendant(of: unselectedTile, matching: find.text('Nature')),
    );

    expect(selectedLabel.style?.color, TripPickPalette.dark.onSelection);
    expect(unselectedLabel.style?.color, TripPickPalette.dark.text);

    await tester.ensureVisible(unselectedTile);
    await tester.pumpAndSettle();
    await tester.tap(unselectedTile);
    await tester.pump();

    final newlySelectedLabel = tester.widget<Text>(
      find.descendant(of: unselectedTile, matching: find.text('Nature')),
    );
    expect(newlySelectedLabel.style?.color, TripPickPalette.dark.onSelection);
  });

  testWidgets('bundles the hero photo and exposes its source attribution', (
    tester,
  ) async {
    await tester.pumpWidget(
      const TripPickApp(
        initialLocale: Locale('en'),
        repository: FakeRecommendationRepository(delay: Duration.zero),
      ),
    );

    expect(find.byKey(const Key('heroPhoto')), findsOneWidget);
    expect(find.byKey(const Key('heroPhotoAttribution')), findsOneWidget);
    expect(find.text('Mashkawat Ahsan · CC BY-SA 4.0'), findsOneWidget);
  });

  testWidgets('vivid layout stays overflow-free at supported widths', (
    tester,
  ) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    for (final size in const [
      Size(390, 844),
      Size(768, 1024),
      Size(1280, 900),
    ]) {
      await tester.binding.setSurfaceSize(size);
      await tester.pumpWidget(
        const TripPickApp(
          initialLocale: Locale('ja'),
          initialThemeMode: ThemeMode.dark,
          repository: FakeRecommendationRepository(delay: Duration.zero),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: 'Overflow at $size');
    }
  });

  testWidgets('desktop form no longer covers the hero photograph', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1280, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      const TripPickApp(
        initialLocale: Locale('en'),
        initialThemeMode: ThemeMode.dark,
        repository: FakeRecommendationRepository(delay: Duration.zero),
      ),
    );
    await tester.pumpAndSettle();

    final hero = tester.getRect(find.byKey(const Key('travelHero')));
    final form = tester.getRect(find.byKey(const Key('planningFormSurface')));
    expect(form.top, greaterThanOrEqualTo(hero.bottom + 20));
    expect(tester.takeException(), isNull);
  });
}

class _PhotoRepository implements RecommendationRepository {
  const _PhotoRepository();

  @override
  Future<List<DestinationRecommendation>> fetch(
    TravelPreferences preferences,
  ) async {
    return List.generate(
      3,
      (index) => DestinationRecommendation(
        placeId: 'city-$index',
        city: 'City ${index + 1}',
        countryCode: 'JP',
        reason: 'Reason',
        photo: const PlacePhoto(
          url: 'https://upload.wikimedia.org/photo.jpg',
          attribution: 'Author · CC BY-SA 4.0',
          sourceUrl: 'https://commons.wikimedia.org/wiki/File:Photo.jpg',
          licenseUrl: 'https://creativecommons.org/licenses/by-sa/4.0/',
        ),
        mapsUri: 'https://maps.example/city',
        highlights: List.generate(
          3,
          (highlight) => DestinationHighlight(
            placeId: 'highlight-$index-$highlight',
            name: 'Highlight $highlight',
            mapsUri: 'https://maps.example/highlight',
            photoUrl: '',
          ),
        ),
      ),
    );
  }
}
