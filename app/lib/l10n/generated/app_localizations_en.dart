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
}
