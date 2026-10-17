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
}
