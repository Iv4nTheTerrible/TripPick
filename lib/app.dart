import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'data/recommendation_repository.dart';
import 'l10n/generated/app_localizations.dart';
import 'theme/trip_pick_theme.dart';
import 'ui/home_page.dart';

class TripPickApp extends StatefulWidget {
  const TripPickApp({
    required this.repository,
    this.initialLocale,
    this.initialThemeMode = ThemeMode.system,
    this.onLocaleChanged,
    this.onThemeModeChanged,
    super.key,
  });

  final RecommendationRepository repository;
  final Locale? initialLocale;
  final ThemeMode initialThemeMode;
  final Future<void> Function(Locale locale)? onLocaleChanged;
  final Future<void> Function(ThemeMode mode)? onThemeModeChanged;

  @override
  State<TripPickApp> createState() => _TripPickAppState();
}

class _TripPickAppState extends State<TripPickApp> {
  late Locale _locale;
  late ThemeMode _themeMode;

  @override
  void initState() {
    super.initState();
    _locale = widget.initialLocale?.languageCode == 'en'
        ? const Locale('en')
        : const Locale('ja');
    _themeMode = widget.initialThemeMode;
  }

  Future<void> _setLocale(Locale locale) async {
    if (_locale == locale) return;
    setState(() => _locale = locale);
    await widget.onLocaleChanged?.call(locale);
  }

  Future<void> _setThemeMode(ThemeMode mode) async {
    if (_themeMode == mode) return;
    setState(() => _themeMode = mode);
    await widget.onThemeModeChanged?.call(mode);
  }

  @override
  Widget build(BuildContext context) {
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
      theme: TripPickTheme.light,
      darkTheme: TripPickTheme.dark,
      themeMode: _themeMode,
      home: HomePage(
        repository: widget.repository,
        locale: _locale,
        themeMode: _themeMode,
        onLocaleChanged: _setLocale,
        onThemeModeChanged: _setThemeMode,
      ),
    );
  }
}
