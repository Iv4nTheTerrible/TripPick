import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'data/recommendation_repository.dart';
import 'l10n/generated/app_localizations.dart';
import 'ui/home_page.dart';

class TripPickApp extends StatefulWidget {
  const TripPickApp({
    required this.repository,
    this.initialLocale,
    this.onLocaleChanged,
    super.key,
  });

  final RecommendationRepository repository;
  final Locale? initialLocale;
  final Future<void> Function(Locale locale)? onLocaleChanged;

  @override
  State<TripPickApp> createState() => _TripPickAppState();
}

class _TripPickAppState extends State<TripPickApp> {
  late Locale _locale;

  @override
  void initState() {
    super.initState();
    _locale = widget.initialLocale?.languageCode == 'en'
        ? const Locale('en')
        : const Locale('ja');
  }

  Future<void> _setLocale(Locale locale) async {
    if (_locale == locale) return;
    setState(() => _locale = locale);
    await widget.onLocaleChanged?.call(locale);
  }

  @override
  Widget build(BuildContext context) {
    const ink = Color(0xFF18332F);
    final colorScheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF147D73),
      brightness: Brightness.light,
      surface: const Color(0xFFFFFBF5),
    );

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      onGenerateTitle: (context) => AppLocalizations.of(context).appName,
      locale: _locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: ThemeData(
        colorScheme: colorScheme,
        scaffoldBackgroundColor: const Color(0xFFF6F2E9),
        useMaterial3: true,
        textTheme: ThemeData.light().textTheme.apply(
          bodyColor: ink,
          displayColor: ink,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFFD7DED8)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFFD7DED8)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: colorScheme.primary, width: 2),
          ),
        ),
        cardTheme: CardThemeData(
          color: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: const BorderSide(color: Color(0xFFE3E5DE)),
          ),
        ),
      ),
      home: HomePage(
        repository: widget.repository,
        locale: _locale,
        onLocaleChanged: _setLocale,
      ),
    );
  }
}
