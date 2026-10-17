// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get settings => 'Settings';

  @override
  String get accountAndSecurity => 'Account & Security';

  @override
  String get anonymousGuestAccount => 'Anonymous guest account';

  @override
  String get authenticatedUser => 'Signed-in account';

  @override
  String get guestSession => 'Guest Session';

  @override
  String get offlinePersonal => 'Offline / Personal';

  @override
  String get signOut => 'Sign out';

  @override
  String get preferences => 'Preferences';

  @override
  String get nepaliCalendarTitle => 'Nepali Bikram Sambat (BS) Calendar';

  @override
  String get nepaliCalendarActive => 'Active: Showing Nepali dates and tithi';

  @override
  String get nepaliCalendarInactive =>
      'Inactive: Showing Gregorian (AD) calendar';

  @override
  String get baseCurrency => 'Base Currency';

  @override
  String get baseCurrencySubtitle =>
      'NPR — Nepalese Rupee (paisa-exact precision)';

  @override
  String get dataAndStorage => 'Data & Storage';

  @override
  String get recordedTransactions => 'Recorded Transactions';

  @override
  String recordedTransactionsSubtitle(int count, String type) {
    return '$count in this period • $type';
  }

  @override
  String get incomeAndExpensesRecorded => 'Income & expenses recorded';

  @override
  String get expensesRecorded => 'Expenses recorded';

  @override
  String get dangerZone => 'Danger Zone';

  @override
  String get deletingAllDataPermanently => 'Deleting all data permanently...';

  @override
  String get dataWillBeDeletedIn1Min => 'Your data will be deleted in 1 minute';

  @override
  String secondsRemaining(int count) {
    return '$count seconds remaining before automatic permanent deletion.';
  }

  @override
  String get cancelDeletion => 'Cancel Deletion';

  @override
  String get deleteImmediately => 'Delete Immediately';

  @override
  String get deleteMyData => 'Delete My Data';

  @override
  String get deleteMyDataDesc =>
      'Permanently erase all your expense and income records from Cloud Firestore. Once deleted, your financial history cannot be recovered.';

  @override
  String get dataDeletionCancelled =>
      'Data deletion cancelled. Your data is safe.';

  @override
  String get allRecordsDeleted =>
      'All your records have been permanently deleted.';

  @override
  String get failedToDeleteData =>
      'Failed to delete data. Please check your connection.';

  @override
  String get deleteAccount => 'Delete Account';

  @override
  String get deleteAccountDesc =>
      'Permanently delete your account credentials from Firebase Authentication, your expense and income records in Cloud Firestore. This action cannot be undone.';

  @override
  String get deleteAccountPermanentlyTitle => 'Delete Account Permanently?';

  @override
  String get deleteAccountPermanentlyContent =>
      'This will permanently delete your Pocket account, all expense and income records from Cloud Firestore.\n\nThis action cannot be undone. Are you sure you want to proceed?';

  @override
  String get cancel => 'Cancel';

  @override
  String get deletingAccountAndDataProgress =>
      'Permanently deleting account and all data...';

  @override
  String get accountDeletedSuccess =>
      'Your account and all associated data have been permanently deleted.';

  @override
  String get confirmPasswordTitle => 'Confirm Password';

  @override
  String get confirmPasswordSecurityPrompt =>
      'For security, please enter your password to confirm account deletion.';

  @override
  String get password => 'Password';

  @override
  String get passwordIsRequired => 'Password is required';

  @override
  String get noEmailAssociated => 'No email associated with account';

  @override
  String get confirm => 'Confirm';

  @override
  String get appearance => 'Appearance';

  @override
  String get themeSystem => 'Follow system';

  @override
  String get themeLight => 'Light';

  @override
  String get themeDark => 'Dark';

  @override
  String get themeSaveFailed => 'Could not save appearance. Please try again.';

  @override
  String get language => 'Language';

  @override
  String get languageSystem => 'Follow system';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageNepali => 'नेपाली (Nepali)';

  @override
  String get languageSaveFailed =>
      'Could not save language preference. Please try again.';

  @override
  String get navOverview => 'Overview';

  @override
  String get navTransactions => 'Transactions';

  @override
  String get navInsights => 'Insights';

  @override
  String get navSettings => 'Settings';

  @override
  String get sidebarSlogan => 'YOUR MONEY, MADE CLEAR';

  @override
  String get sidebarCardTitle => 'Make every rupee count';

  @override
  String get sidebarCardDesc =>
      'Log the small things. Understand the bigger picture.';

  @override
  String get sidebarFooter => 'Personal expense tracker';

  @override
  String get shareReport => 'Share Report';

  @override
  String get personalAccount => 'Personal account';

  @override
  String get yourAccount => 'Your account';

  @override
  String get switchToEnglish => 'Switch to English';

  @override
  String get switchToNepali => 'नेपालीमा बदल्नुहोस्';

  @override
  String get signOutFailed => 'Sign out failed. Please try again.';

  @override
  String get heroOverviewTitle => 'A little clarity. A lot of control.';

  @override
  String get heroOverviewSubtitle => 'Here is how your month is shaping up.';

  @override
  String get heroTransactionsTitle => 'Every expense, in one place.';

  @override
  String get heroTransactionsSubtitle =>
      'Search, review and organize your daily spending.';

  @override
  String get heroInsightsTitle => 'Understand your spending.';

  @override
  String get heroInsightsSubtitle =>
      'Turn your everyday expenses into useful insights.';

  @override
  String get heroSettingsTitle => 'Account & Preferences.';

  @override
  String get heroSettingsSubtitle =>
      'Manage calendar, currency, and data privacy options.';

  @override
  String get addMoney => 'Add money';

  @override
  String get addExpense => 'Add expense';

  @override
  String get calendarNepaliBs => 'Nepali (BS)';

  @override
  String get calendarEnglishAd => 'English (AD)';

  @override
  String get previousMonth => 'Previous month';

  @override
  String get nextMonth => 'Next month';

  @override
  String get currencyNpr => 'Currency: Nepalese Rupee (NPR)';

  @override
  String get recordedBalance => 'Recorded balance';

  @override
  String get recordedBalanceSubtitle => 'All recorded income minus expenses';

  @override
  String get moneyIn => 'Money in';

  @override
  String get moneyInSubtitle => 'Income for selected month';

  @override
  String get moneyOut => 'Money out';

  @override
  String get moneyOutSubtitle => 'Expenses for selected month';

  @override
  String get monthlyNet => 'Monthly net';

  @override
  String transactionsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count transactions',
      one: '1 transaction',
    );
    return '$_temp0';
  }

  @override
  String get onboardingTip =>
      'Starting today? Add money with the Opening balance category for the funds you already have. This is a personal ledger, not a connected bank account.';

  @override
  String get dailySpending => 'Daily spending';

  @override
  String get addExpenseToStartTimeline =>
      'Add an expense to start your spending timeline.';

  @override
  String highestDay(String amount) {
    return 'Highest day: $amount';
  }

  @override
  String get dayOfMonth => 'Day of month';

  @override
  String get spendingByCategory => 'Spending by category';

  @override
  String get categoriesEmpty => 'Your categories will appear here.';

  @override
  String get monthlyPerspective => 'Your monthly perspective';

  @override
  String get noSpendingLastMonth =>
      'No spending recorded last month to compare yet.';

  @override
  String moreThanLastMonth(String amount) {
    return '$amount more than last month.';
  }

  @override
  String lessThanLastMonth(String amount) {
    return '$amount less than last month.';
  }

  @override
  String get monthlyComparisonNotice =>
      'Comparisons use whole calendar months. A month still in progress may have a lower total.';

  @override
  String get recentTransactions => 'Recent transactions';

  @override
  String get transactionHistory => 'Transaction history';

  @override
  String get filterAllTransactions => 'All transactions';

  @override
  String get filterIncome => 'Income';

  @override
  String get filterExpenses => 'Expenses';

  @override
  String get searchHint => 'Search title or note';

  @override
  String get clearSearchTooltip => 'Clear search';

  @override
  String resultsCount(int count) {
    return '$count results';
  }

  @override
  String get sortNewestFirst => 'Newest first';

  @override
  String get sortOldestFirst => 'Oldest first';

  @override
  String get sortHighestAmount => 'Highest amount';

  @override
  String get sortLowestAmount => 'Lowest amount';

  @override
  String get noMatchingTransactions => 'No matching transactions';

  @override
  String get freshStartThisMonth => 'A fresh start for this month';

  @override
  String get emptyTransactionsPrompt =>
      'Add money or an expense, or try another month or filter.';

  @override
  String get editTransaction => 'Edit transaction';

  @override
  String get deleteTransaction => 'Delete transaction';

  @override
  String get viewAll => 'View all';

  @override
  String get copyCsvTooltip => 'Copy filtered transactions as CSV';

  @override
  String get deleteTransactionDialogTitle => 'Delete this transaction?';

  @override
  String get actionCannotBeUndone => 'This action cannot be undone.';

  @override
  String get keepExpense => 'Keep expense';

  @override
  String get delete => 'Delete';

  @override
  String get transactionSavedSuccess => 'Transaction saved successfully.';

  @override
  String get transactionDeletedSuccess => 'Transaction deleted.';

  @override
  String get couldNotDeleteError => 'Could not delete. Please try again.';

  @override
  String get unableToLoadExpenses => 'Unable to load your expenses';

  @override
  String get addMoneyTitle => 'Add money';

  @override
  String get editIncomeTitle => 'Edit income';

  @override
  String get addExpenseTitle => 'Add expense';

  @override
  String get editExpenseTitle => 'Edit expense';

  @override
  String get expenseEditorSubtitle =>
      'Keep the details clear. Your totals and insights update automatically.';

  @override
  String get whereFromLabel => 'Where did the money come from?';

  @override
  String get whatForLabel => 'What was it for?';

  @override
  String get octoberSalaryHint => 'e.g. October salary';

  @override
  String get lunchCafeHint => 'e.g. Lunch at the cafe';

  @override
  String get enterTitleError => 'Enter a title';

  @override
  String get aiSuggestionsLabel => 'AI suggestions:';

  @override
  String aiSuggestionsForCategory(String category) {
    return 'Suggestions for $category';
  }

  @override
  String get autoGenerateAiTooltip => 'Auto-generate with AI';

  @override
  String get scrollLeftTooltip => 'Scroll left';

  @override
  String get scrollRightTooltip => 'Scroll right';

  @override
  String get autoGenerate => 'Auto';

  @override
  String get clearTitleTooltip => 'Clear title';

  @override
  String get amountLabel => 'Amount';

  @override
  String get amountReceivedHelper => 'Enter the amount you received';

  @override
  String get amountPaidHelper => 'Enter the amount you paid';

  @override
  String get invalidAmountError =>
      'Enter a positive amount with up to 2 decimals';

  @override
  String get categoryLabel => 'Category';

  @override
  String get noteOptionalLabel => 'Note (optional)';

  @override
  String get saveIncomeButton => 'Save income';

  @override
  String get saveExpenseButton => 'Save expense';

  @override
  String get savingButton => 'Saving…';

  @override
  String get couldNotSaveError =>
      'Could not save. Check your connection and try again.';

  @override
  String get monthlyFinancialReportTitle => 'Monthly Financial Report';

  @override
  String get reportIncome => 'Income';

  @override
  String get reportExpenses => 'Expenses';

  @override
  String get reportNetSavings => 'Net Savings';

  @override
  String get reportSavingsRate => 'Savings Rate';

  @override
  String get reportSpendingByCategory => 'Spending by Category';

  @override
  String get close => 'Close';

  @override
  String get exportCsv => 'Export CSV';

  @override
  String get shareSummary => 'Share Summary';

  @override
  String get reportSummaryCopied =>
      'Financial report summary copied! Ready to share or paste.';

  @override
  String get reportCsvCopied => 'Monthly CSV transactions copied to clipboard!';

  @override
  String get catFood => 'Food';

  @override
  String get catTransport => 'Transport';

  @override
  String get catShopping => 'Shopping';

  @override
  String get catBills => 'Bills';

  @override
  String get catHealth => 'Health';

  @override
  String get catEducation => 'Education';

  @override
  String get catOther => 'Other';

  @override
  String get catSalary => 'Salary';

  @override
  String get catFreelance => 'Freelance';

  @override
  String get catAllowance => 'Allowance';

  @override
  String get catGift => 'Gift';

  @override
  String get catRefund => 'Refund';

  @override
  String get catOpeningBalance => 'Opening balance';

  @override
  String get catOtherIncome => 'Other income';

  @override
  String get catAll => 'All';
}
