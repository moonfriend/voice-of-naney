// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Voice of Naney';

  @override
  String get languageMenuTooltip => 'Language';

  @override
  String get languageEnglish => 'English';

  @override
  String get languagePersian => 'فارسی';

  @override
  String get mapLoadError => 'Could not load the map. Please check your connection.';

  @override
  String get retry => 'Retry';

  @override
  String get filters => 'Filters';

  @override
  String filtersWithCount(int count) {
    return 'Filters ($count)';
  }

  @override
  String get filterCultures => 'Cultures & ethnicities';

  @override
  String get filterLanguages => 'Languages';

  @override
  String get filterKinds => 'Kinds';

  @override
  String get filterTag => 'Tag';

  @override
  String get filterClear => 'Clear all';

  @override
  String get filterApply => 'Show results';

  @override
  String get kindLullaby => 'Lullaby';

  @override
  String get kindPoem => 'Poem';

  @override
  String get kindWisdom => 'Words of wisdom';

  @override
  String get kindMurmur => 'Murmur';

  @override
  String get kindOther => 'Other';

  @override
  String recordingsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count recordings',
      one: '1 recording',
    );
    return '$_temp0';
  }

  @override
  String get placeRecordingsError => 'Could not load the recordings.';

  @override
  String get noRecordingsHere => 'No recordings here match your filters.';

  @override
  String get close => 'Close';

  @override
  String get recordingNotFound => 'This recording does not exist or is no longer public.';

  @override
  String get recordingLoadError => 'Could not load this recording.';

  @override
  String get backToMap => 'Back to the map';

  @override
  String performedBy(String name) {
    return 'Performed by $name';
  }

  @override
  String recordedIn(int year) {
    return 'Recorded in $year';
  }

  @override
  String get origin => 'Origin';

  @override
  String get cultures => 'Cultures & ethnicities';

  @override
  String get language => 'Language';

  @override
  String get originNote => 'About the origin';

  @override
  String get tags => 'Tags';

  @override
  String get transcript => 'Lyrics & transcript';

  @override
  String get versionOriginal => 'Original';

  @override
  String versionRevision(int number) {
    return 'Revision $number';
  }

  @override
  String get versionLabel => 'Version';

  @override
  String get mapTilesMissing => 'Map background is not configured.';

  @override
  String get playerError => 'This media could not be played.';

  @override
  String get play => 'Play';

  @override
  String get pause => 'Pause';

  @override
  String photoOf(String title) {
    return 'Photo for $title';
  }

  @override
  String get signIn => 'Sign in';

  @override
  String get signOut => 'Sign out';

  @override
  String get signInTitle => 'Sign in to share recordings';

  @override
  String get signInHint => 'Accounts are by invitation only. Listening to recordings needs no account.';

  @override
  String get email => 'Email';

  @override
  String get password => 'Password';

  @override
  String get errorInvalidCredentials => 'Email or password is not correct.';

  @override
  String get errorGeneric => 'Something went wrong. Please try again.';

  @override
  String get errorNetwork => 'No connection. Please check your internet and try again.';

  @override
  String get setPasswordTitle => 'Choose your password';

  @override
  String get setPasswordHint => 'Welcome! Choose a password (at least 8 characters) to finish setting up your account.';

  @override
  String get newPassword => 'New password';

  @override
  String get savePassword => 'Save password';

  @override
  String get errorWeakPassword => 'Please use at least 8 characters.';

  @override
  String get passwordSaved => 'Your password is saved. You can now add recordings.';

  @override
  String get addRecording => 'Add a recording';

  @override
  String get noUploadAccess => 'Your account cannot add recordings. Please contact an admin.';

  @override
  String get account => 'Account';

  @override
  String get uploadTitle => 'Add a recording';

  @override
  String get stepMedia => 'Recording';

  @override
  String get stepDetails => 'Details';

  @override
  String get stepCultures => 'Culture';

  @override
  String get stepArea => 'Origin';

  @override
  String get stepConsent => 'Consent';

  @override
  String get next => 'Next';

  @override
  String get back => 'Back';

  @override
  String get chooseFile => 'Choose audio or video file';

  @override
  String get recordVoice => 'Record with microphone';

  @override
  String get stopRecording => 'Stop';

  @override
  String get discard => 'Discard';

  @override
  String recordingElapsed(String time) {
    return 'Recording… $time';
  }

  @override
  String get micPermissionDenied => 'Microphone access was denied. Allow it in your browser settings, or choose a file instead.';

  @override
  String get recordingFailed => 'Recording did not work. Please try again or choose a file.';

  @override
  String selectedFile(String name, String size) {
    return '$name · $size';
  }

  @override
  String get removeFile => 'Remove';

  @override
  String get addPhoto => 'Add a photo (optional)';

  @override
  String get mediaLimits => 'Audio up to 50 MB (mp3, m4a, wav, ogg, webm). Video up to 500 MB (mp4).';

  @override
  String get fieldTitle => 'Title';

  @override
  String get fieldKind => 'Kind';

  @override
  String get fieldDescription => 'Description (optional)';

  @override
  String get fieldPerformer => 'Who is singing or speaking? (optional)';

  @override
  String get fieldPerformerHint => 'Leave empty to stay anonymous';

  @override
  String get fieldYear => 'Year recorded (optional)';

  @override
  String get fieldLanguage => 'Language';

  @override
  String get languageOtherOption => 'Other…';

  @override
  String get fieldLanguageOther => 'Which language?';

  @override
  String get fieldTags => 'Tags (optional, separated by commas)';

  @override
  String get fieldTranscript => 'Lyrics, transcript or translation (optional)';

  @override
  String get culturesIntro => 'Which culture or ethnic group does this come from? Add a second or third for mixed or moved families.';

  @override
  String cultureLabel(int number) {
    return 'Culture $number';
  }

  @override
  String get cultureOtherOption => 'Other (type it)…';

  @override
  String get cultureOtherText => 'Name of the culture or group';

  @override
  String get addCulture => 'Add another culture';

  @override
  String get removeCulture => 'Remove';

  @override
  String get fieldOriginNote => 'More about the origin (optional)';

  @override
  String get fieldOriginNoteHint => 'e.g. family moved from Urmia to Tabriz in the 1950s';

  @override
  String get areaIntro => 'Where does this recording come from? Search for a city, district or village, or draw the area yourself.';

  @override
  String get searchPlace => 'Search a place';

  @override
  String get noPlacesFound => 'No places found.';

  @override
  String get searchFailed => 'Search is not available right now.';

  @override
  String get loadingBoundary => 'Loading the area…';

  @override
  String get noBoundary => 'OpenStreetMap has no outline for this place. Please draw the area on the map.';

  @override
  String get boundaryFailed => 'Could not load the outline. Try again or draw the area.';

  @override
  String get useThisArea => 'Use this area';

  @override
  String get drawArea => 'Draw the area myself';

  @override
  String drawHint(int count) {
    return 'Tap the map to mark the corners of the area ($count points so far, at least 3).';
  }

  @override
  String get undoPoint => 'Undo';

  @override
  String get clearPoints => 'Clear';

  @override
  String get areaNameEn => 'Name of the area (English)';

  @override
  String get areaNameFa => 'Name of the area (Persian)';

  @override
  String get saveDrawnArea => 'Use the drawn area';

  @override
  String chosenArea(String name) {
    return 'Origin: $name';
  }

  @override
  String get changeArea => 'Change';

  @override
  String get consentTitle => 'Permission to share';

  @override
  String get consentText => 'I confirm that the person heard or seen in this recording (or their family) agreed to share it publicly on Voice of Naney, and that I may upload it.';

  @override
  String get submit => 'Share recording';

  @override
  String uploadingMedia(int percent) {
    return 'Uploading the recording… $percent%';
  }

  @override
  String get uploadingPhoto => 'Uploading the photo…';

  @override
  String get savingPlace => 'Saving the origin area…';

  @override
  String get savingRecording => 'Saving…';

  @override
  String get submitFailed => 'Sharing did not finish. Your files are kept — press the button to try again.';

  @override
  String get dailyLimitReached => 'You reached today\'s upload limit. Please try again tomorrow.';

  @override
  String get issueMediaMissing => 'Choose a file or record your voice.';

  @override
  String get issueMediaUnsupported => 'This file type is not supported.';

  @override
  String get issueMediaTooLarge => 'This file is too large.';

  @override
  String get issuePhotoUnsupported => 'The photo must be JPG, PNG or WebP.';

  @override
  String get issuePhotoTooLarge => 'The photo must be at most 10 MB.';

  @override
  String get issueTitleMissing => 'Please give it a title.';

  @override
  String get issueTitleTooLong => 'The title is too long.';

  @override
  String get issueKindMissing => 'Please choose a kind.';

  @override
  String get issueYearInvalid => 'Please enter a year between 1800 and this year.';

  @override
  String get issueTooManyTags => 'Use at most 20 tags.';

  @override
  String get issueCulturesMissing => 'Add at least one culture.';

  @override
  String get issueTooManyCultures => 'Add at most three cultures.';

  @override
  String get issueCultureInvalid => 'Choose a culture or type its name.';

  @override
  String get issueCultureDuplicate => 'The same culture is listed twice.';

  @override
  String get issuePlaceMissing => 'Choose or draw the origin area.';

  @override
  String get issueConsentMissing => 'Please confirm permission to share.';

  @override
  String get fileMustBeChosenAgain => 'This large file has to be chosen again before retrying. Go back to the first step and choose it again.';
}
