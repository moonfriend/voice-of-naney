// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Persian (`fa`).
class AppLocalizationsFa extends AppLocalizations {
  AppLocalizationsFa([String locale = 'fa']) : super(locale);

  @override
  String get appTitle => 'صدای ننه';

  @override
  String get languageMenuTooltip => 'زبان';

  @override
  String get languageEnglish => 'English';

  @override
  String get languagePersian => 'فارسی';

  @override
  String get mapLoadError => 'بارگیری نقشه ممکن نشد. لطفاً اتصال خود را بررسی کنید.';

  @override
  String get retry => 'تلاش دوباره';

  @override
  String get filters => 'فیلترها';

  @override
  String filtersWithCount(int count) {
    return 'فیلترها ($count)';
  }

  @override
  String get filterCultures => 'فرهنگ‌ها و قومیت‌ها';

  @override
  String get filterLanguages => 'زبان‌ها';

  @override
  String get filterKinds => 'گونه‌ها';

  @override
  String get filterTag => 'برچسب';

  @override
  String get filterClear => 'پاک کردن همه';

  @override
  String get filterApply => 'نمایش نتایج';

  @override
  String get kindLullaby => 'لالایی';

  @override
  String get kindPoem => 'شعر';

  @override
  String get kindWisdom => 'پند و حکمت';

  @override
  String get kindMurmur => 'زمزمه';

  @override
  String get kindOther => 'دیگر';

  @override
  String recordingsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ضبط',
      one: '۱ ضبط',
    );
    return '$_temp0';
  }

  @override
  String get placeRecordingsError => 'بارگیری ضبط‌ها ممکن نشد.';

  @override
  String get noRecordingsHere => 'هیچ ضبطی در اینجا با فیلترهای شما هم‌خوانی ندارد.';

  @override
  String get close => 'بستن';

  @override
  String get recordingNotFound => 'این ضبط وجود ندارد یا دیگر عمومی نیست.';

  @override
  String get recordingLoadError => 'بارگیری این ضبط ممکن نشد.';

  @override
  String get backToMap => 'بازگشت به نقشه';

  @override
  String performedBy(String name) {
    return 'اجرا: $name';
  }

  @override
  String recordedIn(int year) {
    return 'ضبط‌شده در $year';
  }

  @override
  String get origin => 'خاستگاه';

  @override
  String get cultures => 'فرهنگ‌ها و قومیت‌ها';

  @override
  String get language => 'زبان';

  @override
  String get originNote => 'درباره‌ی خاستگاه';

  @override
  String get tags => 'برچسب‌ها';

  @override
  String get transcript => 'متن و ترجمه';

  @override
  String get versionOriginal => 'نسخه‌ی اصلی';

  @override
  String versionRevision(int number) {
    return 'ویرایش $number';
  }

  @override
  String get versionLabel => 'نسخه';

  @override
  String get mapTilesMissing => 'پس‌زمینه‌ی نقشه تنظیم نشده است.';

  @override
  String get playerError => 'پخش این فایل ممکن نشد.';

  @override
  String get play => 'پخش';

  @override
  String get pause => 'توقف';

  @override
  String photoOf(String title) {
    return 'عکس $title';
  }
}
