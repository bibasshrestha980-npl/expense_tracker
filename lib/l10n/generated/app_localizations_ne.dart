// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Nepali (`ne`).
class AppLocalizationsNe extends AppLocalizations {
  AppLocalizationsNe([String locale = 'ne']) : super(locale);

  @override
  String get settings => 'सेटिङहरू';

  @override
  String get accountAndSecurity => 'खाता र सुरक्षा';

  @override
  String get anonymousGuestAccount => 'अज्ञात पाहुना खाता';

  @override
  String get authenticatedUser => 'साइन इन गरिएको खाता';

  @override
  String get guestSession => 'पाहुना सत्र';

  @override
  String get offlinePersonal => 'अफलाइन / व्यक्तिगत';

  @override
  String get signOut => 'साइन आउट';

  @override
  String get preferences => 'प्राथमिकताहरू';

  @override
  String get nepaliCalendarTitle => 'नेपाली विक्रम संवत् (वि.सं.) पात्रो';

  @override
  String get nepaliCalendarActive => 'सक्रिय: नेपाली मिति र तिथि देखाइएको छ';

  @override
  String get nepaliCalendarInactive =>
      'निष्क्रिय: ग्रेगोरियन (ई.सं.) क्यालेन्डर देखाइएको छ';

  @override
  String get baseCurrency => 'आधार मुद्रा';

  @override
  String get baseCurrencySubtitle => 'NPR — नेपाली रूपैयाँ (पैसा शुद्धता)';

  @override
  String get dataAndStorage => 'डाटा र भण्डारण';

  @override
  String get recordedTransactions => 'रेकर्ड गरिएका कारोबारहरू';

  @override
  String recordedTransactionsSubtitle(int count, String type) {
    return 'यो अवधिमा $count वटा • $type';
  }

  @override
  String get incomeAndExpensesRecorded => 'आम्दानी र खर्च रेकर्ड गरियो';

  @override
  String get expensesRecorded => 'खर्च रेकर्ड गरियो';

  @override
  String get dangerZone => 'खतराको क्षेत्र (Danger Zone)';

  @override
  String get deletingAllDataPermanently => 'सबै डाटा स्थायी रूपमा मेटाउँदै...';

  @override
  String get dataWillBeDeletedIn1Min => 'तपाईंको डाटा १ मिनेटमा मेटिनेछ';

  @override
  String secondsRemaining(int count) {
    return 'स्वचालित स्थायी मेटाउनुअघि $count सेकेन्ड बाँकी।';
  }

  @override
  String get cancelDeletion => 'मेटाउन रद्द गर्नुहोस्';

  @override
  String get deleteImmediately => 'तत्काल मेटाउनुहोस्';

  @override
  String get deleteMyData => 'मेरो डाटा मेटाउनुहोस्';

  @override
  String get deleteMyDataDesc =>
      'क्लाउड फायरस्टोरबाट तपाईंका सबै खर्च र आम्दानी रेकर्डहरू स्थायी रूपमा मेटाउनुहोस्। एकपटक मेटिएपछि, तपाईंको वित्तीय इतिहास पुनः प्राप्त गर्न सकिँदैन।';

  @override
  String get dataDeletionCancelled =>
      'डाटा मेटाउने कार्य रद्द गरियो। तपाईंको डाटा सुरक्षित छ।';

  @override
  String get allRecordsDeleted =>
      'तपाईंका सबै रेकर्डहरू स्थायी रूपमा मेटाइएका छन्।';

  @override
  String get failedToDeleteData =>
      'डाटा मेटाउन असफल भयो। कृपया आफ्नो इन्टरनेट जडान जाँच गर्नुहोस्।';

  @override
  String get deleteAccount => 'खाता मेटाउनुहोस्';

  @override
  String get deleteAccountDesc =>
      'फायरबेस प्रमाणीकरणबाट तपाईंको खाता र क्लाउड फायरस्टोरका खर्च तथा आम्दानी रेकर्डहरू स्थायी रूपमा मेटाउनुहोस्। यो कार्य फिर्ता गर्न सकिँदैन।';

  @override
  String get deleteAccountPermanentlyTitle => 'खाता स्थायी रूपमा मेटाउने?';

  @override
  String get deleteAccountPermanentlyContent =>
      'यसले तपाईंको पकेट खाता र क्लाउड फायरस्टोरका सबै खर्च तथा आम्दानी रेकर्डहरू स्थायी रूपमा मेटाउनेछ।\n\nयो कार्य पूर्ववत गर्न सकिँदैन। के तपाईं पक्का हुनुहुन्छ?';

  @override
  String get cancel => 'रद्द गर्नुहोस्';

  @override
  String get deletingAccountAndDataProgress =>
      'खाता र सबै डाटा स्थायी रूपमा मेटाउँदै...';

  @override
  String get accountDeletedSuccess =>
      'तपाईंको खाता र सम्पूर्ण सम्बन्धित डाटा स्थायी रूपमा मेटिएको छ।';

  @override
  String get confirmPasswordTitle => 'पासवर्ड पुष्टि गर्नुहोस्';

  @override
  String get confirmPasswordSecurityPrompt =>
      'सुरक्षाको लागि, कृपया खाता मेटाउन पुष्टि गर्न आफ्नो पासवर्ड प्रविष्ट गर्नुहोस्।';

  @override
  String get password => 'पासवर्ड';

  @override
  String get passwordIsRequired => 'पासवर्ड आवश्यक छ';

  @override
  String get noEmailAssociated => 'खातामा कुनै इमेल जोडिएको छैन';

  @override
  String get confirm => 'पुष्टि गर्नुहोस्';

  @override
  String get appearance => 'देखावट';

  @override
  String get themeSystem => 'प्रणाली अनुसार';

  @override
  String get themeLight => 'उज्यालो';

  @override
  String get themeDark => 'अँध्यारो';

  @override
  String get themeSaveFailed =>
      'देखावट सुरक्षित गर्न सकिएन। फेरि प्रयास गर्नुहोस्।';
}
