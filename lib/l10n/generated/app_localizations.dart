import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ne.dart';

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

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
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
    Locale('ne'),
  ];

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @accountAndSecurity.
  ///
  /// In en, this message translates to:
  /// **'Account & Security'**
  String get accountAndSecurity;

  /// No description provided for @anonymousGuestAccount.
  ///
  /// In en, this message translates to:
  /// **'Anonymous guest account'**
  String get anonymousGuestAccount;

  /// No description provided for @authenticatedUser.
  ///
  /// In en, this message translates to:
  /// **'Signed-in account'**
  String get authenticatedUser;

  /// No description provided for @guestSession.
  ///
  /// In en, this message translates to:
  /// **'Guest Session'**
  String get guestSession;

  /// No description provided for @offlinePersonal.
  ///
  /// In en, this message translates to:
  /// **'Offline / Personal'**
  String get offlinePersonal;

  /// No description provided for @signOut.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get signOut;

  /// No description provided for @preferences.
  ///
  /// In en, this message translates to:
  /// **'Preferences'**
  String get preferences;

  /// No description provided for @nepaliCalendarTitle.
  ///
  /// In en, this message translates to:
  /// **'Nepali Bikram Sambat (BS) Calendar'**
  String get nepaliCalendarTitle;

  /// No description provided for @nepaliCalendarActive.
  ///
  /// In en, this message translates to:
  /// **'Active: Showing Nepali dates and tithi'**
  String get nepaliCalendarActive;

  /// No description provided for @nepaliCalendarInactive.
  ///
  /// In en, this message translates to:
  /// **'Inactive: Showing Gregorian (AD) calendar'**
  String get nepaliCalendarInactive;

  /// No description provided for @baseCurrency.
  ///
  /// In en, this message translates to:
  /// **'Base Currency'**
  String get baseCurrency;

  /// No description provided for @baseCurrencySubtitle.
  ///
  /// In en, this message translates to:
  /// **'NPR — Nepalese Rupee (paisa-exact precision)'**
  String get baseCurrencySubtitle;

  /// No description provided for @dataAndStorage.
  ///
  /// In en, this message translates to:
  /// **'Data & Storage'**
  String get dataAndStorage;

  /// No description provided for @recordedTransactions.
  ///
  /// In en, this message translates to:
  /// **'Recorded Transactions'**
  String get recordedTransactions;

  /// No description provided for @recordedTransactionsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'{count} in this period • {type}'**
  String recordedTransactionsSubtitle(int count, String type);

  /// No description provided for @incomeAndExpensesRecorded.
  ///
  /// In en, this message translates to:
  /// **'Income & expenses recorded'**
  String get incomeAndExpensesRecorded;

  /// No description provided for @expensesRecorded.
  ///
  /// In en, this message translates to:
  /// **'Expenses recorded'**
  String get expensesRecorded;

  /// No description provided for @dangerZone.
  ///
  /// In en, this message translates to:
  /// **'Danger Zone'**
  String get dangerZone;

  /// No description provided for @deletingAllDataPermanently.
  ///
  /// In en, this message translates to:
  /// **'Deleting all data permanently...'**
  String get deletingAllDataPermanently;

  /// No description provided for @dataWillBeDeletedIn1Min.
  ///
  /// In en, this message translates to:
  /// **'Your data will be deleted in 1 minute'**
  String get dataWillBeDeletedIn1Min;

  /// No description provided for @secondsRemaining.
  ///
  /// In en, this message translates to:
  /// **'{count} seconds remaining before automatic permanent deletion.'**
  String secondsRemaining(int count);

  /// No description provided for @cancelDeletion.
  ///
  /// In en, this message translates to:
  /// **'Cancel Deletion'**
  String get cancelDeletion;

  /// No description provided for @deleteImmediately.
  ///
  /// In en, this message translates to:
  /// **'Delete Immediately'**
  String get deleteImmediately;

  /// No description provided for @deleteMyData.
  ///
  /// In en, this message translates to:
  /// **'Delete My Data'**
  String get deleteMyData;

  /// No description provided for @deleteMyDataDesc.
  ///
  /// In en, this message translates to:
  /// **'Permanently erase all your expense and income records from Cloud Firestore. Once deleted, your financial history cannot be recovered.'**
  String get deleteMyDataDesc;

  /// No description provided for @dataDeletionCancelled.
  ///
  /// In en, this message translates to:
  /// **'Data deletion cancelled. Your data is safe.'**
  String get dataDeletionCancelled;

  /// No description provided for @allRecordsDeleted.
  ///
  /// In en, this message translates to:
  /// **'All your records have been permanently deleted.'**
  String get allRecordsDeleted;

  /// No description provided for @failedToDeleteData.
  ///
  /// In en, this message translates to:
  /// **'Failed to delete data. Please check your connection.'**
  String get failedToDeleteData;

  /// No description provided for @deleteAccount.
  ///
  /// In en, this message translates to:
  /// **'Delete Account'**
  String get deleteAccount;

  /// No description provided for @deleteAccountDesc.
  ///
  /// In en, this message translates to:
  /// **'Permanently delete your account credentials from Firebase Authentication, your expense and income records in Cloud Firestore. This action cannot be undone.'**
  String get deleteAccountDesc;

  /// No description provided for @deleteAccountPermanentlyTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete Account Permanently?'**
  String get deleteAccountPermanentlyTitle;

  /// No description provided for @deleteAccountPermanentlyContent.
  ///
  /// In en, this message translates to:
  /// **'This will permanently delete your Pocket account, all expense and income records from Cloud Firestore.\n\nThis action cannot be undone. Are you sure you want to proceed?'**
  String get deleteAccountPermanentlyContent;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @deletingAccountAndDataProgress.
  ///
  /// In en, this message translates to:
  /// **'Permanently deleting account and all data...'**
  String get deletingAccountAndDataProgress;

  /// No description provided for @accountDeletedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Your account and all associated data have been permanently deleted.'**
  String get accountDeletedSuccess;

  /// No description provided for @confirmPasswordTitle.
  ///
  /// In en, this message translates to:
  /// **'Confirm Password'**
  String get confirmPasswordTitle;

  /// No description provided for @confirmPasswordSecurityPrompt.
  ///
  /// In en, this message translates to:
  /// **'For security, please enter your password to confirm account deletion.'**
  String get confirmPasswordSecurityPrompt;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @passwordIsRequired.
  ///
  /// In en, this message translates to:
  /// **'Password is required'**
  String get passwordIsRequired;

  /// No description provided for @noEmailAssociated.
  ///
  /// In en, this message translates to:
  /// **'No email associated with account'**
  String get noEmailAssociated;

  /// No description provided for @confirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirm;

  /// No description provided for @appearance.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get appearance;

  /// No description provided for @themeSystem.
  ///
  /// In en, this message translates to:
  /// **'Follow system'**
  String get themeSystem;

  /// No description provided for @themeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get themeLight;

  /// No description provided for @themeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get themeDark;

  /// No description provided for @themeSaveFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not save appearance. Please try again.'**
  String get themeSaveFailed;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @languageSystem.
  ///
  /// In en, this message translates to:
  /// **'Follow system'**
  String get languageSystem;

  /// No description provided for @languageEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// No description provided for @languageNepali.
  ///
  /// In en, this message translates to:
  /// **'नेपाली (Nepali)'**
  String get languageNepali;

  /// No description provided for @languageSaveFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not save language preference. Please try again.'**
  String get languageSaveFailed;
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
      <String>['en', 'ne'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'ne':
      return AppLocalizationsNe();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
