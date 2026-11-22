import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_fa.dart';

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
  AppLocalizations(String locale) : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

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
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('fa')
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Voice of Naney'**
  String get appTitle;

  /// No description provided for @languageMenuTooltip.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get languageMenuTooltip;

  /// No description provided for @languageEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// No description provided for @languagePersian.
  ///
  /// In en, this message translates to:
  /// **'فارسی'**
  String get languagePersian;

  /// No description provided for @mapLoadError.
  ///
  /// In en, this message translates to:
  /// **'Could not load the map. Please check your connection.'**
  String get mapLoadError;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @filters.
  ///
  /// In en, this message translates to:
  /// **'Filters'**
  String get filters;

  /// No description provided for @filtersWithCount.
  ///
  /// In en, this message translates to:
  /// **'Filters ({count})'**
  String filtersWithCount(int count);

  /// No description provided for @filterCultures.
  ///
  /// In en, this message translates to:
  /// **'Cultures & ethnicities'**
  String get filterCultures;

  /// No description provided for @filterLanguages.
  ///
  /// In en, this message translates to:
  /// **'Languages'**
  String get filterLanguages;

  /// No description provided for @filterKinds.
  ///
  /// In en, this message translates to:
  /// **'Kinds'**
  String get filterKinds;

  /// No description provided for @filterTag.
  ///
  /// In en, this message translates to:
  /// **'Tag'**
  String get filterTag;

  /// No description provided for @filterClear.
  ///
  /// In en, this message translates to:
  /// **'Clear all'**
  String get filterClear;

  /// No description provided for @filterApply.
  ///
  /// In en, this message translates to:
  /// **'Show results'**
  String get filterApply;

  /// No description provided for @kindLullaby.
  ///
  /// In en, this message translates to:
  /// **'Lullaby'**
  String get kindLullaby;

  /// No description provided for @kindPoem.
  ///
  /// In en, this message translates to:
  /// **'Poem'**
  String get kindPoem;

  /// No description provided for @kindWisdom.
  ///
  /// In en, this message translates to:
  /// **'Words of wisdom'**
  String get kindWisdom;

  /// No description provided for @kindMurmur.
  ///
  /// In en, this message translates to:
  /// **'Murmur'**
  String get kindMurmur;

  /// No description provided for @kindOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get kindOther;

  /// No description provided for @recordingsCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 recording} other{{count} recordings}}'**
  String recordingsCount(int count);

  /// No description provided for @placeRecordingsError.
  ///
  /// In en, this message translates to:
  /// **'Could not load the recordings.'**
  String get placeRecordingsError;

  /// No description provided for @noRecordingsHere.
  ///
  /// In en, this message translates to:
  /// **'No recordings here match your filters.'**
  String get noRecordingsHere;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @recordingNotFound.
  ///
  /// In en, this message translates to:
  /// **'This recording does not exist or is no longer public.'**
  String get recordingNotFound;

  /// No description provided for @recordingLoadError.
  ///
  /// In en, this message translates to:
  /// **'Could not load this recording.'**
  String get recordingLoadError;

  /// No description provided for @backToMap.
  ///
  /// In en, this message translates to:
  /// **'Back to the map'**
  String get backToMap;

  /// No description provided for @performedBy.
  ///
  /// In en, this message translates to:
  /// **'Performed by {name}'**
  String performedBy(String name);

  /// No description provided for @recordedIn.
  ///
  /// In en, this message translates to:
  /// **'Recorded in {year}'**
  String recordedIn(int year);

  /// No description provided for @origin.
  ///
  /// In en, this message translates to:
  /// **'Origin'**
  String get origin;

  /// No description provided for @cultures.
  ///
  /// In en, this message translates to:
  /// **'Cultures & ethnicities'**
  String get cultures;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @originNote.
  ///
  /// In en, this message translates to:
  /// **'About the origin'**
  String get originNote;

  /// No description provided for @tags.
  ///
  /// In en, this message translates to:
  /// **'Tags'**
  String get tags;

  /// No description provided for @transcript.
  ///
  /// In en, this message translates to:
  /// **'Lyrics & transcript'**
  String get transcript;

  /// No description provided for @versionOriginal.
  ///
  /// In en, this message translates to:
  /// **'Original'**
  String get versionOriginal;

  /// No description provided for @versionRevision.
  ///
  /// In en, this message translates to:
  /// **'Revision {number}'**
  String versionRevision(int number);

  /// No description provided for @versionLabel.
  ///
  /// In en, this message translates to:
  /// **'Version'**
  String get versionLabel;

  /// No description provided for @mapTilesMissing.
  ///
  /// In en, this message translates to:
  /// **'Map background is not configured.'**
  String get mapTilesMissing;

  /// No description provided for @playerError.
  ///
  /// In en, this message translates to:
  /// **'This media could not be played.'**
  String get playerError;

  /// No description provided for @play.
  ///
  /// In en, this message translates to:
  /// **'Play'**
  String get play;

  /// No description provided for @pause.
  ///
  /// In en, this message translates to:
  /// **'Pause'**
  String get pause;

  /// No description provided for @photoOf.
  ///
  /// In en, this message translates to:
  /// **'Photo for {title}'**
  String photoOf(String title);
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>['en', 'fa'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {


  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en': return AppLocalizationsEn();
    case 'fa': return AppLocalizationsFa();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.'
  );
}
