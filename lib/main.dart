import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'data/api_recommendation_repository.dart';
import 'data/fake_recommendation_repository.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final preferences = await SharedPreferences.getInstance();
  final savedLanguage = preferences.getString('languageCode');
  final initialLocale = savedLanguage == null ? null : Locale(savedLanguage);
  const useFakeRepository = bool.fromEnvironment(
    'USE_FAKE_REPOSITORY',
    defaultValue: false,
  );
  const backendBaseUrl = String.fromEnvironment(
    'BACKEND_BASE_URL',
    defaultValue: 'http://localhost:8080',
  );

  runApp(
    TripPickApp(
      initialLocale: initialLocale,
      repository: useFakeRepository
          ? const FakeRecommendationRepository()
          : ApiRecommendationRepository(baseUrl: backendBaseUrl),
      onLocaleChanged: (locale) async {
        await preferences.setString('languageCode', locale.languageCode);
      },
    ),
  );
}
