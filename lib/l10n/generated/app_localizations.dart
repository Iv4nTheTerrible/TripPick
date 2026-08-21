import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ja.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('ja'),
  ];

  /// No description provided for @appName.
  ///
  /// In en, this message translates to:
  /// **'TripPick'**
  String get appName;

  /// No description provided for @appTagline.
  ///
  /// In en, this message translates to:
  /// **'Three places that fit your trip'**
  String get appTagline;

  /// No description provided for @heroTitle.
  ///
  /// In en, this message translates to:
  /// **'Not sure where to go next?'**
  String get heroTitle;

  /// No description provided for @heroBody.
  ///
  /// In en, this message translates to:
  /// **'Tell us what kind of trip you want. TripPick will suggest three cities and explain why each one fits.'**
  String get heroBody;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @english.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get english;

  /// No description provided for @japanese.
  ///
  /// In en, this message translates to:
  /// **'日本語'**
  String get japanese;

  /// No description provided for @preferencesTitle.
  ///
  /// In en, this message translates to:
  /// **'Your travel preferences'**
  String get preferencesTitle;

  /// No description provided for @preferencesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'A few details are enough. Budget is used as a general preference, not an exact price estimate.'**
  String get preferencesSubtitle;

  /// No description provided for @originCountry.
  ///
  /// In en, this message translates to:
  /// **'Origin country'**
  String get originCountry;

  /// No description provided for @chooseCountry.
  ///
  /// In en, this message translates to:
  /// **'Choose a country'**
  String get chooseCountry;

  /// No description provided for @travelScope.
  ///
  /// In en, this message translates to:
  /// **'Travel scope'**
  String get travelScope;

  /// No description provided for @domestic.
  ///
  /// In en, this message translates to:
  /// **'Domestic'**
  String get domestic;

  /// No description provided for @international.
  ///
  /// In en, this message translates to:
  /// **'International'**
  String get international;

  /// No description provided for @budget.
  ///
  /// In en, this message translates to:
  /// **'Budget preference'**
  String get budget;

  /// No description provided for @low.
  ///
  /// In en, this message translates to:
  /// **'Low'**
  String get low;

  /// No description provided for @medium.
  ///
  /// In en, this message translates to:
  /// **'Medium'**
  String get medium;

  /// No description provided for @high.
  ///
  /// In en, this message translates to:
  /// **'High'**
  String get high;

  /// No description provided for @tripDays.
  ///
  /// In en, this message translates to:
  /// **'Trip duration (days)'**
  String get tripDays;

  /// No description provided for @tripDaysHint.
  ///
  /// In en, this message translates to:
  /// **'1–30 days'**
  String get tripDaysHint;

  /// No description provided for @interests.
  ///
  /// In en, this message translates to:
  /// **'What interests you?'**
  String get interests;

  /// No description provided for @chooseInterests.
  ///
  /// In en, this message translates to:
  /// **'Choose between 1 and 5 interests.'**
  String get chooseInterests;

  /// No description provided for @nature.
  ///
  /// In en, this message translates to:
  /// **'Nature'**
  String get nature;

  /// No description provided for @food.
  ///
  /// In en, this message translates to:
  /// **'Food'**
  String get food;

  /// No description provided for @culture.
  ///
  /// In en, this message translates to:
  /// **'Culture'**
  String get culture;

  /// No description provided for @shopping.
  ///
  /// In en, this message translates to:
  /// **'Shopping'**
  String get shopping;

  /// No description provided for @relaxation.
  ///
  /// In en, this message translates to:
  /// **'Relaxation'**
  String get relaxation;

  /// No description provided for @adventure.
  ///
  /// In en, this message translates to:
  /// **'Adventure'**
  String get adventure;

  /// No description provided for @travelMonth.
  ///
  /// In en, this message translates to:
  /// **'Travel month (optional)'**
  String get travelMonth;

  /// No description provided for @anyMonth.
  ///
  /// In en, this message translates to:
  /// **'Any month'**
  String get anyMonth;

  /// No description provided for @findDestinations.
  ///
  /// In en, this message translates to:
  /// **'Find my destinations'**
  String get findDestinations;

  /// No description provided for @requiredField.
  ///
  /// In en, this message translates to:
  /// **'This field is required.'**
  String get requiredField;

  /// No description provided for @invalidDays.
  ///
  /// In en, this message translates to:
  /// **'Enter a number from 1 to 30.'**
  String get invalidDays;

  /// No description provided for @loadingTitle.
  ///
  /// In en, this message translates to:
  /// **'Finding your three best matches…'**
  String get loadingTitle;

  /// No description provided for @loadingBody.
  ///
  /// In en, this message translates to:
  /// **'We are matching your preferences with destination ideas.'**
  String get loadingBody;

  /// No description provided for @resultsTitle.
  ///
  /// In en, this message translates to:
  /// **'Your recommended destinations'**
  String get resultsTitle;

  /// No description provided for @resultsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Three ideas selected from your preferences. Open any place in Google Maps to explore further.'**
  String get resultsSubtitle;

  /// No description provided for @highlights.
  ///
  /// In en, this message translates to:
  /// **'Highlights'**
  String get highlights;

  /// No description provided for @openMaps.
  ///
  /// In en, this message translates to:
  /// **'Open in Google Maps'**
  String get openMaps;

  /// No description provided for @editPreferences.
  ///
  /// In en, this message translates to:
  /// **'Edit preferences'**
  String get editPreferences;

  /// No description provided for @tryAgain.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get tryAgain;

  /// No description provided for @newRecommendations.
  ///
  /// In en, this message translates to:
  /// **'New recommendations'**
  String get newRecommendations;

  /// No description provided for @errorTitle.
  ///
  /// In en, this message translates to:
  /// **'We could not finish this search'**
  String get errorTitle;

  /// No description provided for @genericError.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong while finding destinations. Please try again.'**
  String get genericError;

  /// No description provided for @invalidResponse.
  ///
  /// In en, this message translates to:
  /// **'The recommendation service returned incomplete results.'**
  String get invalidResponse;

  /// No description provided for @connectionError.
  ///
  /// In en, this message translates to:
  /// **'Could not connect to the local TripPick server. Check that it is running on port 8080.'**
  String get connectionError;

  /// No description provided for @mapsError.
  ///
  /// In en, this message translates to:
  /// **'Could not open Google Maps.'**
  String get mapsError;

  /// No description provided for @photoUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Destination photo unavailable'**
  String get photoUnavailable;

  /// No description provided for @poweredByGoogle.
  ///
  /// In en, this message translates to:
  /// **'Links open in Google Maps'**
  String get poweredByGoogle;

  /// No description provided for @budgetNote.
  ///
  /// In en, this message translates to:
  /// **'Budget is a soft preference and does not include flights, hotels, or exact trip costs.'**
  String get budgetNote;

  /// No description provided for @stepPreferences.
  ///
  /// In en, this message translates to:
  /// **'1. Preferences'**
  String get stepPreferences;

  /// No description provided for @stepResults.
  ///
  /// In en, this message translates to:
  /// **'2. Recommendations'**
  String get stepResults;

  /// No description provided for @month1.
  ///
  /// In en, this message translates to:
  /// **'January'**
  String get month1;

  /// No description provided for @month2.
  ///
  /// In en, this message translates to:
  /// **'February'**
  String get month2;

  /// No description provided for @month3.
  ///
  /// In en, this message translates to:
  /// **'March'**
  String get month3;

  /// No description provided for @month4.
  ///
  /// In en, this message translates to:
  /// **'April'**
  String get month4;

  /// No description provided for @month5.
  ///
  /// In en, this message translates to:
  /// **'May'**
  String get month5;

  /// No description provided for @month6.
  ///
  /// In en, this message translates to:
  /// **'June'**
  String get month6;

  /// No description provided for @month7.
  ///
  /// In en, this message translates to:
  /// **'July'**
  String get month7;

  /// No description provided for @month8.
  ///
  /// In en, this message translates to:
  /// **'August'**
  String get month8;

  /// No description provided for @month9.
  ///
  /// In en, this message translates to:
  /// **'September'**
  String get month9;

  /// No description provided for @month10.
  ///
  /// In en, this message translates to:
  /// **'October'**
  String get month10;

  /// No description provided for @month11.
  ///
  /// In en, this message translates to:
  /// **'November'**
  String get month11;

  /// No description provided for @month12.
  ///
  /// In en, this message translates to:
  /// **'December'**
  String get month12;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'ja'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'ja':
      return AppLocalizationsJa();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
