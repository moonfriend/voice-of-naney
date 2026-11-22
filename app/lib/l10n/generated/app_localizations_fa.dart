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

  @override
  String get signIn => 'ورود';

  @override
  String get signOut => 'خروج';

  @override
  String get signInTitle => 'برای هم‌رسانی ضبط‌ها وارد شوید';

  @override
  String get signInHint => 'حساب‌ها فقط با دعوت‌نامه ساخته می‌شوند. برای شنیدن ضبط‌ها نیازی به حساب نیست.';

  @override
  String get email => 'ایمیل';

  @override
  String get password => 'گذرواژه';

  @override
  String get errorInvalidCredentials => 'ایمیل یا گذرواژه درست نیست.';

  @override
  String get errorGeneric => 'مشکلی پیش آمد. لطفاً دوباره تلاش کنید.';

  @override
  String get errorNetwork => 'اتصال برقرار نیست. لطفاً اینترنت را بررسی کنید و دوباره تلاش کنید.';

  @override
  String get setPasswordTitle => 'گذرواژه‌ی خود را انتخاب کنید';

  @override
  String get setPasswordHint => 'خوش آمدید! برای کامل کردن حساب، گذرواژه‌ای (دست‌کم ۸ نویسه) انتخاب کنید.';

  @override
  String get newPassword => 'گذرواژه‌ی تازه';

  @override
  String get savePassword => 'ذخیره‌ی گذرواژه';

  @override
  String get errorWeakPassword => 'لطفاً دست‌کم ۸ نویسه به کار ببرید.';

  @override
  String get passwordSaved => 'گذرواژه ذخیره شد. اکنون می‌توانید ضبط بیفزایید.';

  @override
  String get addRecording => 'افزودن ضبط';

  @override
  String get noUploadAccess => 'حساب شما اجازه‌ی افزودن ضبط ندارد. لطفاً با مدیر تماس بگیرید.';

  @override
  String get account => 'حساب';

  @override
  String get uploadTitle => 'افزودن ضبط';

  @override
  String get stepMedia => 'ضبط';

  @override
  String get stepDetails => 'جزئیات';

  @override
  String get stepCultures => 'فرهنگ';

  @override
  String get stepArea => 'خاستگاه';

  @override
  String get stepConsent => 'رضایت';

  @override
  String get next => 'بعدی';

  @override
  String get back => 'قبلی';

  @override
  String get chooseFile => 'انتخاب فایل صوتی یا تصویری';

  @override
  String get recordVoice => 'ضبط با میکروفون';

  @override
  String get stopRecording => 'توقف';

  @override
  String get discard => 'دور انداختن';

  @override
  String recordingElapsed(String time) {
    return 'در حال ضبط… $time';
  }

  @override
  String get micPermissionDenied => 'دسترسی به میکروفون رد شد. آن را در تنظیمات مرورگر مجاز کنید یا فایلی انتخاب کنید.';

  @override
  String get recordingFailed => 'ضبط انجام نشد. لطفاً دوباره تلاش کنید یا فایلی انتخاب کنید.';

  @override
  String selectedFile(String name, String size) {
    return '$name · $size';
  }

  @override
  String get removeFile => 'حذف';

  @override
  String get addPhoto => 'افزودن عکس (اختیاری)';

  @override
  String get mediaLimits => 'صدا تا ۵۰ مگابایت (mp3، m4a، wav، ogg، webm). ویدیو تا ۵۰۰ مگابایت (mp4).';

  @override
  String get fieldTitle => 'عنوان';

  @override
  String get fieldKind => 'گونه';

  @override
  String get fieldDescription => 'توضیحات (اختیاری)';

  @override
  String get fieldPerformer => 'چه کسی می‌خواند یا سخن می‌گوید؟ (اختیاری)';

  @override
  String get fieldPerformerHint => 'برای ناشناس ماندن خالی بگذارید';

  @override
  String get fieldYear => 'سال ضبط (اختیاری)';

  @override
  String get fieldLanguage => 'زبان';

  @override
  String get languageOtherOption => 'دیگر…';

  @override
  String get fieldLanguageOther => 'کدام زبان؟';

  @override
  String get fieldTags => 'برچسب‌ها (اختیاری، با ویرگول جدا کنید)';

  @override
  String get fieldTranscript => 'متن، رونوشت یا ترجمه (اختیاری)';

  @override
  String get culturesIntro => 'این ضبط از کدام فرهنگ یا قوم است؟ برای خانواده‌های آمیخته یا کوچ‌کرده، فرهنگ دوم یا سوم را هم بیفزایید.';

  @override
  String cultureLabel(int number) {
    return 'فرهنگ $number';
  }

  @override
  String get cultureOtherOption => 'دیگر (بنویسید)…';

  @override
  String get cultureOtherText => 'نام فرهنگ یا گروه';

  @override
  String get addCulture => 'افزودن فرهنگی دیگر';

  @override
  String get removeCulture => 'حذف';

  @override
  String get fieldOriginNote => 'بیشتر درباره‌ی خاستگاه (اختیاری)';

  @override
  String get fieldOriginNoteHint => 'مثلاً خانواده در دهه‌ی ۱۳۳۰ از ارومیه به تبریز کوچ کرد';

  @override
  String get areaIntro => 'این ضبط از کجاست؟ شهر، محله یا روستا را جست‌وجو کنید یا خودتان محدوده را بکشید.';

  @override
  String get searchPlace => 'جست‌وجوی مکان';

  @override
  String get noPlacesFound => 'مکانی پیدا نشد.';

  @override
  String get searchFailed => 'جست‌وجو اکنون در دسترس نیست.';

  @override
  String get loadingBoundary => 'در حال بارگیری محدوده…';

  @override
  String get noBoundary => 'اوپن‌استریت‌مپ برای این مکان محدوده‌ای ندارد. لطفاً محدوده را روی نقشه بکشید.';

  @override
  String get boundaryFailed => 'بارگیری محدوده ممکن نشد. دوباره تلاش کنید یا محدوده را بکشید.';

  @override
  String get useThisArea => 'همین محدوده';

  @override
  String get drawArea => 'خودم محدوده را می‌کشم';

  @override
  String drawHint(int count) {
    return 'برای مشخص کردن گوشه‌های محدوده روی نقشه بزنید ($count نقطه تا اینجا، دست‌کم ۳).';
  }

  @override
  String get undoPoint => 'واگرد';

  @override
  String get clearPoints => 'پاک کردن';

  @override
  String get areaNameEn => 'نام محدوده (انگلیسی)';

  @override
  String get areaNameFa => 'نام محدوده (فارسی)';

  @override
  String get saveDrawnArea => 'استفاده از محدوده‌ی کشیده‌شده';

  @override
  String chosenArea(String name) {
    return 'خاستگاه: $name';
  }

  @override
  String get changeArea => 'تغییر';

  @override
  String get consentTitle => 'اجازه‌ی هم‌رسانی';

  @override
  String get consentText => 'تأیید می‌کنم که فردی که در این ضبط شنیده یا دیده می‌شود (یا خانواده‌اش) با هم‌رسانی عمومی آن در «صدای ننه» موافق است و من اجازه‌ی بارگذاری آن را دارم.';

  @override
  String get submit => 'هم‌رسانی ضبط';

  @override
  String uploadingMedia(int percent) {
    return 'در حال بارگذاری ضبط… $percent٪';
  }

  @override
  String get uploadingPhoto => 'در حال بارگذاری عکس…';

  @override
  String get savingPlace => 'در حال ذخیره‌ی خاستگاه…';

  @override
  String get savingRecording => 'در حال ذخیره…';

  @override
  String get submitFailed => 'هم‌رسانی کامل نشد. فایل‌های شما نگه داشته شده‌اند؛ برای تلاش دوباره دکمه را بزنید.';

  @override
  String get dailyLimitReached => 'به سقف بارگذاری امروز رسیده‌اید. لطفاً فردا دوباره تلاش کنید.';

  @override
  String get issueMediaMissing => 'فایلی انتخاب کنید یا صدای خود را ضبط کنید.';

  @override
  String get issueMediaUnsupported => 'این نوع فایل پشتیبانی نمی‌شود.';

  @override
  String get issueMediaTooLarge => 'این فایل بیش از حد بزرگ است.';

  @override
  String get issuePhotoUnsupported => 'عکس باید JPG، PNG یا WebP باشد.';

  @override
  String get issuePhotoTooLarge => 'عکس باید حداکثر ۱۰ مگابایت باشد.';

  @override
  String get issueTitleMissing => 'لطفاً عنوانی بنویسید.';

  @override
  String get issueTitleTooLong => 'عنوان بیش از حد بلند است.';

  @override
  String get issueKindMissing => 'لطفاً گونه را انتخاب کنید.';

  @override
  String get issueYearInvalid => 'لطفاً سالی میان ۱۸۰۰ و امسال (میلادی) وارد کنید.';

  @override
  String get issueTooManyTags => 'حداکثر ۲۰ برچسب به کار ببرید.';

  @override
  String get issueCulturesMissing => 'دست‌کم یک فرهنگ بیفزایید.';

  @override
  String get issueTooManyCultures => 'حداکثر سه فرهنگ بیفزایید.';

  @override
  String get issueCultureInvalid => 'فرهنگی انتخاب کنید یا نام آن را بنویسید.';

  @override
  String get issueCultureDuplicate => 'یک فرهنگ دو بار آمده است.';

  @override
  String get issuePlaceMissing => 'خاستگاه را انتخاب کنید یا بکشید.';

  @override
  String get issueConsentMissing => 'لطفاً اجازه‌ی هم‌رسانی را تأیید کنید.';

  @override
  String get fileMustBeChosenAgain => 'پیش از تلاش دوباره باید این فایل بزرگ را دوباره انتخاب کنید. به گام نخست برگردید و آن را دوباره انتخاب کنید.';
}
