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
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[Locale('en'), Locale('fa')];

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

  /// No description provided for @signIn.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get signIn;

  /// No description provided for @signOut.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get signOut;

  /// No description provided for @signInTitle.
  ///
  /// In en, this message translates to:
  /// **'Sign in to share recordings'**
  String get signInTitle;

  /// No description provided for @signInHint.
  ///
  /// In en, this message translates to:
  /// **'Accounts are by invitation only. Listening to recordings needs no account.'**
  String get signInHint;

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @errorInvalidCredentials.
  ///
  /// In en, this message translates to:
  /// **'Email or password is not correct.'**
  String get errorInvalidCredentials;

  /// No description provided for @errorGeneric.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Please try again.'**
  String get errorGeneric;

  /// No description provided for @errorNetwork.
  ///
  /// In en, this message translates to:
  /// **'No connection. Please check your internet and try again.'**
  String get errorNetwork;

  /// No description provided for @setPasswordTitle.
  ///
  /// In en, this message translates to:
  /// **'Choose your password'**
  String get setPasswordTitle;

  /// No description provided for @setPasswordHint.
  ///
  /// In en, this message translates to:
  /// **'Welcome! Choose a password (at least 8 characters) to finish setting up your account.'**
  String get setPasswordHint;

  /// No description provided for @newPassword.
  ///
  /// In en, this message translates to:
  /// **'New password'**
  String get newPassword;

  /// No description provided for @savePassword.
  ///
  /// In en, this message translates to:
  /// **'Save password'**
  String get savePassword;

  /// No description provided for @errorWeakPassword.
  ///
  /// In en, this message translates to:
  /// **'Please use at least 8 characters.'**
  String get errorWeakPassword;

  /// No description provided for @passwordSaved.
  ///
  /// In en, this message translates to:
  /// **'Your password is saved. You can now add recordings.'**
  String get passwordSaved;

  /// No description provided for @addRecording.
  ///
  /// In en, this message translates to:
  /// **'Add a recording'**
  String get addRecording;

  /// No description provided for @noUploadAccess.
  ///
  /// In en, this message translates to:
  /// **'Your account cannot add recordings. Please contact an admin.'**
  String get noUploadAccess;

  /// No description provided for @account.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get account;

  /// No description provided for @uploadTitle.
  ///
  /// In en, this message translates to:
  /// **'Add a recording'**
  String get uploadTitle;

  /// No description provided for @stepMedia.
  ///
  /// In en, this message translates to:
  /// **'Recording'**
  String get stepMedia;

  /// No description provided for @stepDetails.
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get stepDetails;

  /// No description provided for @stepCultures.
  ///
  /// In en, this message translates to:
  /// **'Culture'**
  String get stepCultures;

  /// No description provided for @stepArea.
  ///
  /// In en, this message translates to:
  /// **'Origin'**
  String get stepArea;

  /// No description provided for @stepConsent.
  ///
  /// In en, this message translates to:
  /// **'Consent'**
  String get stepConsent;

  /// No description provided for @next.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get next;

  /// No description provided for @back.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get back;

  /// No description provided for @chooseFile.
  ///
  /// In en, this message translates to:
  /// **'Choose audio or video file'**
  String get chooseFile;

  /// No description provided for @recordVoice.
  ///
  /// In en, this message translates to:
  /// **'Record with microphone'**
  String get recordVoice;

  /// No description provided for @stopRecording.
  ///
  /// In en, this message translates to:
  /// **'Stop'**
  String get stopRecording;

  /// No description provided for @discard.
  ///
  /// In en, this message translates to:
  /// **'Discard'**
  String get discard;

  /// No description provided for @recordingElapsed.
  ///
  /// In en, this message translates to:
  /// **'Recording… {time}'**
  String recordingElapsed(String time);

  /// No description provided for @micPermissionDenied.
  ///
  /// In en, this message translates to:
  /// **'Microphone access was denied. Allow it in your browser settings, or choose a file instead.'**
  String get micPermissionDenied;

  /// No description provided for @recordingFailed.
  ///
  /// In en, this message translates to:
  /// **'Recording did not work. Please try again or choose a file.'**
  String get recordingFailed;

  /// No description provided for @selectedFile.
  ///
  /// In en, this message translates to:
  /// **'{name} · {size}'**
  String selectedFile(String name, String size);

  /// No description provided for @removeFile.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get removeFile;

  /// No description provided for @addPhoto.
  ///
  /// In en, this message translates to:
  /// **'Add a photo (optional)'**
  String get addPhoto;

  /// No description provided for @mediaLimits.
  ///
  /// In en, this message translates to:
  /// **'Audio up to 50 MB (mp3, m4a, wav, ogg, webm). Video up to 500 MB (mp4, mov, m4v).'**
  String get mediaLimits;

  /// No description provided for @fieldTitle.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get fieldTitle;

  /// No description provided for @fieldKind.
  ///
  /// In en, this message translates to:
  /// **'Kind'**
  String get fieldKind;

  /// No description provided for @fieldDescription.
  ///
  /// In en, this message translates to:
  /// **'Description (optional)'**
  String get fieldDescription;

  /// No description provided for @fieldPerformer.
  ///
  /// In en, this message translates to:
  /// **'Who is singing or speaking? (optional)'**
  String get fieldPerformer;

  /// No description provided for @fieldPerformerHint.
  ///
  /// In en, this message translates to:
  /// **'Leave empty to stay anonymous'**
  String get fieldPerformerHint;

  /// No description provided for @fieldYear.
  ///
  /// In en, this message translates to:
  /// **'Year recorded (optional)'**
  String get fieldYear;

  /// No description provided for @fieldLanguage.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get fieldLanguage;

  /// No description provided for @languageOtherOption.
  ///
  /// In en, this message translates to:
  /// **'Other…'**
  String get languageOtherOption;

  /// No description provided for @fieldLanguageOther.
  ///
  /// In en, this message translates to:
  /// **'Which language?'**
  String get fieldLanguageOther;

  /// No description provided for @fieldTags.
  ///
  /// In en, this message translates to:
  /// **'Tags (optional, separated by commas)'**
  String get fieldTags;

  /// No description provided for @fieldTranscript.
  ///
  /// In en, this message translates to:
  /// **'Lyrics, transcript or translation (optional)'**
  String get fieldTranscript;

  /// No description provided for @culturesIntro.
  ///
  /// In en, this message translates to:
  /// **'Which culture or ethnic group does this come from? Add a second or third for mixed or moved families.'**
  String get culturesIntro;

  /// No description provided for @cultureLabel.
  ///
  /// In en, this message translates to:
  /// **'Culture {number}'**
  String cultureLabel(int number);

  /// No description provided for @cultureOtherOption.
  ///
  /// In en, this message translates to:
  /// **'Other (type it)…'**
  String get cultureOtherOption;

  /// No description provided for @cultureOtherText.
  ///
  /// In en, this message translates to:
  /// **'Name of the culture or group'**
  String get cultureOtherText;

  /// No description provided for @addCulture.
  ///
  /// In en, this message translates to:
  /// **'Add another culture'**
  String get addCulture;

  /// No description provided for @removeCulture.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get removeCulture;

  /// No description provided for @fieldOriginNote.
  ///
  /// In en, this message translates to:
  /// **'More about the origin (optional)'**
  String get fieldOriginNote;

  /// No description provided for @fieldOriginNoteHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. family moved from Urmia to Tabriz in the 1950s'**
  String get fieldOriginNoteHint;

  /// No description provided for @areaIntro.
  ///
  /// In en, this message translates to:
  /// **'Where does this recording come from? Search for a city, district or village, or draw the area yourself.'**
  String get areaIntro;

  /// No description provided for @searchPlace.
  ///
  /// In en, this message translates to:
  /// **'Search a place'**
  String get searchPlace;

  /// No description provided for @noPlacesFound.
  ///
  /// In en, this message translates to:
  /// **'No places found.'**
  String get noPlacesFound;

  /// No description provided for @searchFailed.
  ///
  /// In en, this message translates to:
  /// **'Search is not available right now.'**
  String get searchFailed;

  /// No description provided for @loadingBoundary.
  ///
  /// In en, this message translates to:
  /// **'Loading the area…'**
  String get loadingBoundary;

  /// No description provided for @noBoundary.
  ///
  /// In en, this message translates to:
  /// **'OpenStreetMap has no outline for this place. Please draw the area on the map.'**
  String get noBoundary;

  /// No description provided for @boundaryFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not load the outline. Try again or draw the area.'**
  String get boundaryFailed;

  /// No description provided for @useThisArea.
  ///
  /// In en, this message translates to:
  /// **'Use this area'**
  String get useThisArea;

  /// No description provided for @drawArea.
  ///
  /// In en, this message translates to:
  /// **'Draw the area myself'**
  String get drawArea;

  /// No description provided for @drawHint.
  ///
  /// In en, this message translates to:
  /// **'Tap the map to mark the corners of the area ({count} points so far, at least 3).'**
  String drawHint(int count);

  /// No description provided for @undoPoint.
  ///
  /// In en, this message translates to:
  /// **'Undo'**
  String get undoPoint;

  /// No description provided for @clearPoints.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get clearPoints;

  /// No description provided for @areaNameEn.
  ///
  /// In en, this message translates to:
  /// **'Name of the area (English)'**
  String get areaNameEn;

  /// No description provided for @areaNameFa.
  ///
  /// In en, this message translates to:
  /// **'Name of the area (Persian)'**
  String get areaNameFa;

  /// No description provided for @saveDrawnArea.
  ///
  /// In en, this message translates to:
  /// **'Use the drawn area'**
  String get saveDrawnArea;

  /// No description provided for @chosenArea.
  ///
  /// In en, this message translates to:
  /// **'Origin: {name}'**
  String chosenArea(String name);

  /// No description provided for @changeArea.
  ///
  /// In en, this message translates to:
  /// **'Change'**
  String get changeArea;

  /// No description provided for @consentTitle.
  ///
  /// In en, this message translates to:
  /// **'Permission to share'**
  String get consentTitle;

  /// No description provided for @consentText.
  ///
  /// In en, this message translates to:
  /// **'I confirm that the person heard or seen in this recording (or their family) agreed to share it publicly on Voice of Naney, and that I may upload it.'**
  String get consentText;

  /// No description provided for @submit.
  ///
  /// In en, this message translates to:
  /// **'Share recording'**
  String get submit;

  /// No description provided for @uploadingMedia.
  ///
  /// In en, this message translates to:
  /// **'Uploading the recording… {percent}%'**
  String uploadingMedia(int percent);

  /// No description provided for @uploadingPhoto.
  ///
  /// In en, this message translates to:
  /// **'Uploading the photo…'**
  String get uploadingPhoto;

  /// No description provided for @savingPlace.
  ///
  /// In en, this message translates to:
  /// **'Saving the origin area…'**
  String get savingPlace;

  /// No description provided for @savingRecording.
  ///
  /// In en, this message translates to:
  /// **'Saving…'**
  String get savingRecording;

  /// No description provided for @submitFailed.
  ///
  /// In en, this message translates to:
  /// **'Sharing did not finish. Your files are kept — press the button to try again.'**
  String get submitFailed;

  /// No description provided for @dailyLimitReached.
  ///
  /// In en, this message translates to:
  /// **'You reached today\'s upload limit. Please try again tomorrow.'**
  String get dailyLimitReached;

  /// No description provided for @issueMediaMissing.
  ///
  /// In en, this message translates to:
  /// **'Choose a file or record your voice.'**
  String get issueMediaMissing;

  /// No description provided for @issueMediaUnsupported.
  ///
  /// In en, this message translates to:
  /// **'This file type is not supported.'**
  String get issueMediaUnsupported;

  /// No description provided for @issueMediaTooLarge.
  ///
  /// In en, this message translates to:
  /// **'This file is too large.'**
  String get issueMediaTooLarge;

  /// No description provided for @issuePhotoUnsupported.
  ///
  /// In en, this message translates to:
  /// **'The photo must be JPG, PNG or WebP.'**
  String get issuePhotoUnsupported;

  /// No description provided for @issuePhotoTooLarge.
  ///
  /// In en, this message translates to:
  /// **'The photo must be at most 10 MB.'**
  String get issuePhotoTooLarge;

  /// No description provided for @issueTitleMissing.
  ///
  /// In en, this message translates to:
  /// **'Please give it a title.'**
  String get issueTitleMissing;

  /// No description provided for @issueTitleTooLong.
  ///
  /// In en, this message translates to:
  /// **'The title is too long.'**
  String get issueTitleTooLong;

  /// No description provided for @issueKindMissing.
  ///
  /// In en, this message translates to:
  /// **'Please choose a kind.'**
  String get issueKindMissing;

  /// No description provided for @issueYearInvalid.
  ///
  /// In en, this message translates to:
  /// **'Please enter a year between 1800 and this year.'**
  String get issueYearInvalid;

  /// No description provided for @issueTooManyTags.
  ///
  /// In en, this message translates to:
  /// **'Use at most 20 tags.'**
  String get issueTooManyTags;

  /// No description provided for @issueCulturesMissing.
  ///
  /// In en, this message translates to:
  /// **'Add at least one culture.'**
  String get issueCulturesMissing;

  /// No description provided for @issueTooManyCultures.
  ///
  /// In en, this message translates to:
  /// **'Add at most three cultures.'**
  String get issueTooManyCultures;

  /// No description provided for @issueCultureInvalid.
  ///
  /// In en, this message translates to:
  /// **'Choose a culture or type its name.'**
  String get issueCultureInvalid;

  /// No description provided for @issueCultureDuplicate.
  ///
  /// In en, this message translates to:
  /// **'The same culture is listed twice.'**
  String get issueCultureDuplicate;

  /// No description provided for @issuePlaceMissing.
  ///
  /// In en, this message translates to:
  /// **'Choose or draw the origin area.'**
  String get issuePlaceMissing;

  /// No description provided for @issueConsentMissing.
  ///
  /// In en, this message translates to:
  /// **'Please confirm permission to share.'**
  String get issueConsentMissing;

  /// No description provided for @fileMustBeChosenAgain.
  ///
  /// In en, this message translates to:
  /// **'This large file has to be chosen again before retrying. Go back to the first step and choose it again.'**
  String get fileMustBeChosenAgain;
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
    case 'en':
      return AppLocalizationsEn();
    case 'fa':
      return AppLocalizationsFa();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
