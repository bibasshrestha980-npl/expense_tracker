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

  /// No description provided for @navOverview.
  ///
  /// In en, this message translates to:
  /// **'Overview'**
  String get navOverview;

  /// No description provided for @navTransactions.
  ///
  /// In en, this message translates to:
  /// **'Transactions'**
  String get navTransactions;

  /// No description provided for @navInsights.
  ///
  /// In en, this message translates to:
  /// **'Insights'**
  String get navInsights;

  /// No description provided for @navSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get navSettings;

  /// No description provided for @sidebarSlogan.
  ///
  /// In en, this message translates to:
  /// **'YOUR MONEY, MADE CLEAR'**
  String get sidebarSlogan;

  /// No description provided for @sidebarCardTitle.
  ///
  /// In en, this message translates to:
  /// **'Make every rupee count'**
  String get sidebarCardTitle;

  /// No description provided for @sidebarCardDesc.
  ///
  /// In en, this message translates to:
  /// **'Log the small things. Understand the bigger picture.'**
  String get sidebarCardDesc;

  /// No description provided for @sidebarFooter.
  ///
  /// In en, this message translates to:
  /// **'Personal expense tracker'**
  String get sidebarFooter;

  /// No description provided for @shareReport.
  ///
  /// In en, this message translates to:
  /// **'Share Report'**
  String get shareReport;

  /// No description provided for @personalAccount.
  ///
  /// In en, this message translates to:
  /// **'Personal account'**
  String get personalAccount;

  /// No description provided for @yourAccount.
  ///
  /// In en, this message translates to:
  /// **'Your account'**
  String get yourAccount;

  /// No description provided for @switchToEnglish.
  ///
  /// In en, this message translates to:
  /// **'Switch to English'**
  String get switchToEnglish;

  /// No description provided for @switchToNepali.
  ///
  /// In en, this message translates to:
  /// **'नेपालीमा बदल्नुहोस्'**
  String get switchToNepali;

  /// No description provided for @signOutFailed.
  ///
  /// In en, this message translates to:
  /// **'Sign out failed. Please try again.'**
  String get signOutFailed;

  /// No description provided for @heroOverviewTitle.
  ///
  /// In en, this message translates to:
  /// **'A little clarity. A lot of control.'**
  String get heroOverviewTitle;

  /// No description provided for @heroOverviewSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Here is how your month is shaping up.'**
  String get heroOverviewSubtitle;

  /// No description provided for @heroTransactionsTitle.
  ///
  /// In en, this message translates to:
  /// **'Every expense, in one place.'**
  String get heroTransactionsTitle;

  /// No description provided for @heroTransactionsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Search, review and organize your daily spending.'**
  String get heroTransactionsSubtitle;

  /// No description provided for @heroInsightsTitle.
  ///
  /// In en, this message translates to:
  /// **'Understand your spending.'**
  String get heroInsightsTitle;

  /// No description provided for @heroInsightsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Turn your everyday expenses into useful insights.'**
  String get heroInsightsSubtitle;

  /// No description provided for @heroSettingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Account & Preferences.'**
  String get heroSettingsTitle;

  /// No description provided for @heroSettingsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Manage calendar, currency, and data privacy options.'**
  String get heroSettingsSubtitle;

  /// No description provided for @addMoney.
  ///
  /// In en, this message translates to:
  /// **'Add money'**
  String get addMoney;

  /// No description provided for @addExpense.
  ///
  /// In en, this message translates to:
  /// **'Add expense'**
  String get addExpense;

  /// No description provided for @calendarNepaliBs.
  ///
  /// In en, this message translates to:
  /// **'Nepali (BS)'**
  String get calendarNepaliBs;

  /// No description provided for @calendarEnglishAd.
  ///
  /// In en, this message translates to:
  /// **'English (AD)'**
  String get calendarEnglishAd;

  /// No description provided for @previousMonth.
  ///
  /// In en, this message translates to:
  /// **'Previous month'**
  String get previousMonth;

  /// No description provided for @nextMonth.
  ///
  /// In en, this message translates to:
  /// **'Next month'**
  String get nextMonth;

  /// No description provided for @currencyNpr.
  ///
  /// In en, this message translates to:
  /// **'Currency: Nepalese Rupee (NPR)'**
  String get currencyNpr;

  /// No description provided for @recordedBalance.
  ///
  /// In en, this message translates to:
  /// **'Recorded balance'**
  String get recordedBalance;

  /// No description provided for @recordedBalanceSubtitle.
  ///
  /// In en, this message translates to:
  /// **'All recorded income minus expenses'**
  String get recordedBalanceSubtitle;

  /// No description provided for @moneyIn.
  ///
  /// In en, this message translates to:
  /// **'Money in'**
  String get moneyIn;

  /// No description provided for @moneyInSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Income for selected month'**
  String get moneyInSubtitle;

  /// No description provided for @moneyOut.
  ///
  /// In en, this message translates to:
  /// **'Money out'**
  String get moneyOut;

  /// No description provided for @moneyOutSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Expenses for selected month'**
  String get moneyOutSubtitle;

  /// No description provided for @monthlyNet.
  ///
  /// In en, this message translates to:
  /// **'Monthly net'**
  String get monthlyNet;

  /// No description provided for @transactionsCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 transaction} other{{count} transactions}}'**
  String transactionsCount(int count);

  /// No description provided for @onboardingTip.
  ///
  /// In en, this message translates to:
  /// **'Starting today? Add money with the Opening balance category for the funds you already have. This is a personal ledger, not a connected bank account.'**
  String get onboardingTip;

  /// No description provided for @dailySpending.
  ///
  /// In en, this message translates to:
  /// **'Daily spending'**
  String get dailySpending;

  /// No description provided for @addExpenseToStartTimeline.
  ///
  /// In en, this message translates to:
  /// **'Add an expense to start your spending timeline.'**
  String get addExpenseToStartTimeline;

  /// No description provided for @highestDay.
  ///
  /// In en, this message translates to:
  /// **'Highest day: {amount}'**
  String highestDay(String amount);

  /// No description provided for @dayOfMonth.
  ///
  /// In en, this message translates to:
  /// **'Day of month'**
  String get dayOfMonth;

  /// No description provided for @spendingByCategory.
  ///
  /// In en, this message translates to:
  /// **'Spending by category'**
  String get spendingByCategory;

  /// No description provided for @categoriesEmpty.
  ///
  /// In en, this message translates to:
  /// **'Your categories will appear here.'**
  String get categoriesEmpty;

  /// No description provided for @monthlyPerspective.
  ///
  /// In en, this message translates to:
  /// **'Your monthly perspective'**
  String get monthlyPerspective;

  /// No description provided for @noSpendingLastMonth.
  ///
  /// In en, this message translates to:
  /// **'No spending recorded last month to compare yet.'**
  String get noSpendingLastMonth;

  /// No description provided for @moreThanLastMonth.
  ///
  /// In en, this message translates to:
  /// **'{amount} more than last month.'**
  String moreThanLastMonth(String amount);

  /// No description provided for @lessThanLastMonth.
  ///
  /// In en, this message translates to:
  /// **'{amount} less than last month.'**
  String lessThanLastMonth(String amount);

  /// No description provided for @monthlyComparisonNotice.
  ///
  /// In en, this message translates to:
  /// **'Comparisons use whole calendar months. A month still in progress may have a lower total.'**
  String get monthlyComparisonNotice;

  /// No description provided for @recentTransactions.
  ///
  /// In en, this message translates to:
  /// **'Recent transactions'**
  String get recentTransactions;

  /// No description provided for @transactionHistory.
  ///
  /// In en, this message translates to:
  /// **'Transaction history'**
  String get transactionHistory;

  /// No description provided for @filterAllTransactions.
  ///
  /// In en, this message translates to:
  /// **'All transactions'**
  String get filterAllTransactions;

  /// No description provided for @filterIncome.
  ///
  /// In en, this message translates to:
  /// **'Income'**
  String get filterIncome;

  /// No description provided for @filterExpenses.
  ///
  /// In en, this message translates to:
  /// **'Expenses'**
  String get filterExpenses;

  /// No description provided for @searchHint.
  ///
  /// In en, this message translates to:
  /// **'Search title or note'**
  String get searchHint;

  /// No description provided for @clearSearchTooltip.
  ///
  /// In en, this message translates to:
  /// **'Clear search'**
  String get clearSearchTooltip;

  /// No description provided for @resultsCount.
  ///
  /// In en, this message translates to:
  /// **'{count} results'**
  String resultsCount(int count);

  /// No description provided for @sortNewestFirst.
  ///
  /// In en, this message translates to:
  /// **'Newest first'**
  String get sortNewestFirst;

  /// No description provided for @sortOldestFirst.
  ///
  /// In en, this message translates to:
  /// **'Oldest first'**
  String get sortOldestFirst;

  /// No description provided for @sortHighestAmount.
  ///
  /// In en, this message translates to:
  /// **'Highest amount'**
  String get sortHighestAmount;

  /// No description provided for @sortLowestAmount.
  ///
  /// In en, this message translates to:
  /// **'Lowest amount'**
  String get sortLowestAmount;

  /// No description provided for @noMatchingTransactions.
  ///
  /// In en, this message translates to:
  /// **'No matching transactions'**
  String get noMatchingTransactions;

  /// No description provided for @freshStartThisMonth.
  ///
  /// In en, this message translates to:
  /// **'A fresh start for this month'**
  String get freshStartThisMonth;

  /// No description provided for @emptyTransactionsPrompt.
  ///
  /// In en, this message translates to:
  /// **'Add money or an expense, or try another month or filter.'**
  String get emptyTransactionsPrompt;

  /// No description provided for @showAllTransactions.
  ///
  /// In en, this message translates to:
  /// **'Show all transactions'**
  String get showAllTransactions;

  /// No description provided for @editTransaction.
  ///
  /// In en, this message translates to:
  /// **'Edit transaction'**
  String get editTransaction;

  /// No description provided for @deleteTransaction.
  ///
  /// In en, this message translates to:
  /// **'Delete transaction'**
  String get deleteTransaction;

  /// No description provided for @viewAll.
  ///
  /// In en, this message translates to:
  /// **'View all'**
  String get viewAll;

  /// No description provided for @copyCsvTooltip.
  ///
  /// In en, this message translates to:
  /// **'Copy filtered transactions as CSV'**
  String get copyCsvTooltip;

  /// No description provided for @deleteTransactionDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete this transaction?'**
  String get deleteTransactionDialogTitle;

  /// No description provided for @actionCannotBeUndone.
  ///
  /// In en, this message translates to:
  /// **'This action cannot be undone.'**
  String get actionCannotBeUndone;

  /// No description provided for @keepExpense.
  ///
  /// In en, this message translates to:
  /// **'Keep expense'**
  String get keepExpense;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @transactionSavedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Transaction saved successfully.'**
  String get transactionSavedSuccess;

  /// No description provided for @transactionDeletedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Transaction deleted.'**
  String get transactionDeletedSuccess;

  /// No description provided for @couldNotDeleteError.
  ///
  /// In en, this message translates to:
  /// **'Could not delete. Please try again.'**
  String get couldNotDeleteError;

  /// No description provided for @unableToLoadExpenses.
  ///
  /// In en, this message translates to:
  /// **'Unable to load your expenses'**
  String get unableToLoadExpenses;

  /// No description provided for @addMoneyTitle.
  ///
  /// In en, this message translates to:
  /// **'Add money'**
  String get addMoneyTitle;

  /// No description provided for @editIncomeTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit income'**
  String get editIncomeTitle;

  /// No description provided for @addExpenseTitle.
  ///
  /// In en, this message translates to:
  /// **'Add expense'**
  String get addExpenseTitle;

  /// No description provided for @editExpenseTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit expense'**
  String get editExpenseTitle;

  /// No description provided for @expenseEditorSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Keep the details clear. Your totals and insights update automatically.'**
  String get expenseEditorSubtitle;

  /// No description provided for @whereFromLabel.
  ///
  /// In en, this message translates to:
  /// **'Where did the money come from?'**
  String get whereFromLabel;

  /// No description provided for @whatForLabel.
  ///
  /// In en, this message translates to:
  /// **'What was it for?'**
  String get whatForLabel;

  /// No description provided for @octoberSalaryHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. October salary'**
  String get octoberSalaryHint;

  /// No description provided for @lunchCafeHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Lunch at the cafe'**
  String get lunchCafeHint;

  /// No description provided for @enterTitleError.
  ///
  /// In en, this message translates to:
  /// **'Enter a title'**
  String get enterTitleError;

  /// No description provided for @aiSuggestionsLabel.
  ///
  /// In en, this message translates to:
  /// **'AI suggestions:'**
  String get aiSuggestionsLabel;

  /// No description provided for @aiSuggestionsForCategory.
  ///
  /// In en, this message translates to:
  /// **'Suggestions for {category}'**
  String aiSuggestionsForCategory(String category);

  /// No description provided for @autoGenerateAiTooltip.
  ///
  /// In en, this message translates to:
  /// **'Auto-generate with AI'**
  String get autoGenerateAiTooltip;

  /// No description provided for @scrollLeftTooltip.
  ///
  /// In en, this message translates to:
  /// **'Scroll left'**
  String get scrollLeftTooltip;

  /// No description provided for @scrollRightTooltip.
  ///
  /// In en, this message translates to:
  /// **'Scroll right'**
  String get scrollRightTooltip;

  /// No description provided for @autoGenerate.
  ///
  /// In en, this message translates to:
  /// **'Auto'**
  String get autoGenerate;

  /// No description provided for @clearTitleTooltip.
  ///
  /// In en, this message translates to:
  /// **'Clear title'**
  String get clearTitleTooltip;

  /// No description provided for @amountLabel.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get amountLabel;

  /// No description provided for @amountReceivedHelper.
  ///
  /// In en, this message translates to:
  /// **'Enter the amount you received'**
  String get amountReceivedHelper;

  /// No description provided for @amountPaidHelper.
  ///
  /// In en, this message translates to:
  /// **'Enter the amount you paid'**
  String get amountPaidHelper;

  /// No description provided for @invalidAmountError.
  ///
  /// In en, this message translates to:
  /// **'Enter a positive amount with up to 2 decimals'**
  String get invalidAmountError;

  /// No description provided for @categoryLabel.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get categoryLabel;

  /// No description provided for @noteOptionalLabel.
  ///
  /// In en, this message translates to:
  /// **'Note (optional)'**
  String get noteOptionalLabel;

  /// No description provided for @saveIncomeButton.
  ///
  /// In en, this message translates to:
  /// **'Save income'**
  String get saveIncomeButton;

  /// No description provided for @saveExpenseButton.
  ///
  /// In en, this message translates to:
  /// **'Save expense'**
  String get saveExpenseButton;

  /// No description provided for @savingButton.
  ///
  /// In en, this message translates to:
  /// **'Saving…'**
  String get savingButton;

  /// No description provided for @couldNotSaveError.
  ///
  /// In en, this message translates to:
  /// **'Could not save. Check your connection and try again.'**
  String get couldNotSaveError;

  /// No description provided for @monthlyFinancialReportTitle.
  ///
  /// In en, this message translates to:
  /// **'Monthly Financial Report'**
  String get monthlyFinancialReportTitle;

  /// No description provided for @reportIncome.
  ///
  /// In en, this message translates to:
  /// **'Income'**
  String get reportIncome;

  /// No description provided for @reportExpenses.
  ///
  /// In en, this message translates to:
  /// **'Expenses'**
  String get reportExpenses;

  /// No description provided for @reportNetSavings.
  ///
  /// In en, this message translates to:
  /// **'Net Savings'**
  String get reportNetSavings;

  /// No description provided for @reportSavingsRate.
  ///
  /// In en, this message translates to:
  /// **'Savings Rate'**
  String get reportSavingsRate;

  /// No description provided for @reportSpendingByCategory.
  ///
  /// In en, this message translates to:
  /// **'Spending by Category'**
  String get reportSpendingByCategory;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @exportCsv.
  ///
  /// In en, this message translates to:
  /// **'Export CSV'**
  String get exportCsv;

  /// No description provided for @shareSummary.
  ///
  /// In en, this message translates to:
  /// **'Share Summary'**
  String get shareSummary;

  /// No description provided for @reportSummaryCopied.
  ///
  /// In en, this message translates to:
  /// **'Financial report summary copied! Ready to share or paste.'**
  String get reportSummaryCopied;

  /// No description provided for @reportCsvCopied.
  ///
  /// In en, this message translates to:
  /// **'Monthly CSV transactions copied to clipboard!'**
  String get reportCsvCopied;

  /// No description provided for @catFood.
  ///
  /// In en, this message translates to:
  /// **'Food'**
  String get catFood;

  /// No description provided for @catTransport.
  ///
  /// In en, this message translates to:
  /// **'Transport'**
  String get catTransport;

  /// No description provided for @catShopping.
  ///
  /// In en, this message translates to:
  /// **'Shopping'**
  String get catShopping;

  /// No description provided for @catBills.
  ///
  /// In en, this message translates to:
  /// **'Bills'**
  String get catBills;

  /// No description provided for @catHealth.
  ///
  /// In en, this message translates to:
  /// **'Health'**
  String get catHealth;

  /// No description provided for @catEducation.
  ///
  /// In en, this message translates to:
  /// **'Education'**
  String get catEducation;

  /// No description provided for @catOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get catOther;

  /// No description provided for @catSalary.
  ///
  /// In en, this message translates to:
  /// **'Salary'**
  String get catSalary;

  /// No description provided for @catFreelance.
  ///
  /// In en, this message translates to:
  /// **'Freelance'**
  String get catFreelance;

  /// No description provided for @catAllowance.
  ///
  /// In en, this message translates to:
  /// **'Allowance'**
  String get catAllowance;

  /// No description provided for @catGift.
  ///
  /// In en, this message translates to:
  /// **'Gift'**
  String get catGift;

  /// No description provided for @catRefund.
  ///
  /// In en, this message translates to:
  /// **'Refund'**
  String get catRefund;

  /// No description provided for @catOpeningBalance.
  ///
  /// In en, this message translates to:
  /// **'Opening balance'**
  String get catOpeningBalance;

  /// No description provided for @catOtherIncome.
  ///
  /// In en, this message translates to:
  /// **'Other income'**
  String get catOtherIncome;

  /// No description provided for @catAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get catAll;
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
