// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'TripPick';

  @override
  String get appTagline => 'Three places that fit your trip';

  @override
  String get heroTitle => 'Not sure where to go next?';

  @override
  String get heroBody =>
      'Tell us what kind of trip you want. TripPick will suggest three cities and explain why each one fits.';

  @override
  String get language => 'Language';

  @override
  String get english => 'English';

  @override
  String get japanese => '日本語';

  @override
  String get preferencesTitle => 'Your travel preferences';

  @override
  String get preferencesSubtitle =>
      'A few details are enough. Budget is used as a general preference, not an exact price estimate.';

  @override
  String get originCountry => 'Origin country';

  @override
  String get chooseCountry => 'Choose a country';

  @override
  String get travelScope => 'Travel scope';

  @override
  String get domestic => 'Domestic';

  @override
  String get international => 'International';

  @override
  String get budget => 'Budget preference';

  @override
  String get low => 'Low';

  @override
  String get medium => 'Medium';

  @override
  String get high => 'High';

  @override
  String get tripDays => 'Trip duration (days)';

  @override
  String get tripDaysHint => '1–30 days';

  @override
  String get interests => 'What interests you?';

  @override
  String get chooseInterests => 'Choose between 1 and 5 interests.';

  @override
  String get nature => 'Nature';

  @override
  String get food => 'Food';

  @override
  String get culture => 'Culture';

  @override
  String get shopping => 'Shopping';

  @override
  String get relaxation => 'Relaxation';

  @override
  String get adventure => 'Adventure';

  @override
  String get travelMonth => 'Travel month (optional)';

  @override
  String get anyMonth => 'Any month';

  @override
  String get findDestinations => 'Find my destinations';

  @override
  String get requiredField => 'This field is required.';

  @override
  String get invalidDays => 'Enter a number from 1 to 30.';

  @override
  String get loadingTitle => 'Finding your three best matches…';

  @override
  String get loadingBody =>
      'We are matching your preferences with destination ideas.';

  @override
  String get resultsTitle => 'Your recommended destinations';

  @override
  String get resultsSubtitle =>
      'Three ideas selected from your preferences. Open any place in Google Maps to explore further.';

  @override
  String get highlights => 'Highlights';

  @override
  String get openMaps => 'Open in Google Maps';

  @override
  String get editPreferences => 'Edit preferences';

  @override
  String get tryAgain => 'Try again';

  @override
  String get newRecommendations => 'New recommendations';

  @override
  String get errorTitle => 'We could not finish this search';

  @override
  String get genericError =>
      'Something went wrong while finding destinations. Please try again.';

  @override
  String get invalidResponse =>
      'The recommendation service returned incomplete results.';

  @override
  String get connectionError =>
      'Could not connect to the local TripPick server. Check that it is running on port 8080.';

  @override
  String get mapsError => 'Could not open Google Maps.';

  @override
  String get photoUnavailable => 'Destination photo unavailable';

  @override
  String get poweredByGoogle => 'Links open in Google Maps';

  @override
  String get budgetNote =>
      'Budget is a soft preference and does not include flights, hotels, or exact trip costs.';

  @override
  String get stepPreferences => '1. Preferences';

  @override
  String get stepResults => '2. Recommendations';

  @override
  String get month1 => 'January';

  @override
  String get month2 => 'February';

  @override
  String get month3 => 'March';

  @override
  String get month4 => 'April';

  @override
  String get month5 => 'May';

  @override
  String get month6 => 'June';

  @override
  String get month7 => 'July';

  @override
  String get month8 => 'August';

  @override
  String get month9 => 'September';

  @override
  String get month10 => 'October';

  @override
  String get month11 => 'November';

  @override
  String get month12 => 'December';
}
