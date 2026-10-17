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

  @override
  String get language => 'भाषा';

  @override
  String get languageSystem => 'प्रणाली अनुसार';

  @override
  String get languageEnglish => 'English (अंग्रेजी)';

  @override
  String get languageNepali => 'नेपाली';

  @override
  String get languageSaveFailed =>
      'भाषा प्राथमिकता सुरक्षित गर्न सकिएन। फेरि प्रयास गर्नुहोस्।';

  @override
  String get navOverview => 'समीक्षा';

  @override
  String get navTransactions => 'कारोबारहरू';

  @override
  String get navInsights => 'अन्तरदृष्टि';

  @override
  String get navSettings => 'सेटिङहरू';

  @override
  String get sidebarSlogan => 'तपाईंको पैसा, स्पष्ट हिसाब';

  @override
  String get sidebarCardTitle => 'हरेक रूपैयाँको सदुपयोग गर्नुहोस्';

  @override
  String get sidebarCardDesc =>
      'साना खर्च पनि लेख्नुहोस्। ठूलो वित्तीय चित्र बुझ्नुहोस्।';

  @override
  String get sidebarFooter => 'व्यक्तिगत खर्च ट्र्याकर';

  @override
  String get shareReport => 'प्रतिवेदन सेयर';

  @override
  String get personalAccount => 'व्यक्तिगत खाता';

  @override
  String get yourAccount => 'तपाईंको खाता';

  @override
  String get switchToEnglish => 'English मा बदल्नुहोस्';

  @override
  String get switchToNepali => 'नेपालीमा बदल्नुहोस्';

  @override
  String get signOutFailed => 'साइन आउट असफल भयो। कृपया फेरि प्रयास गर्नुहोस्।';

  @override
  String get heroOverviewTitle => 'अलिकति स्पष्टता। धेरै नियन्त्रण।';

  @override
  String get heroOverviewSubtitle => 'यहाँ तपाईंको महिनाको स्थिति देखाइएको छ।';

  @override
  String get heroTransactionsTitle => 'हरेक खर्च, एकै ठाउँमा।';

  @override
  String get heroTransactionsSubtitle =>
      'तपाईंको दैनिक खर्च खोज्नुहोस्, समीक्षा गर्नुहोस् र व्यवस्थित गर्नुहोस्।';

  @override
  String get heroInsightsTitle => 'आफ्नो खर्चको ढाँचा बुझ्नुहोस्।';

  @override
  String get heroInsightsSubtitle =>
      'आफ्ना दैनिक खर्चहरूलाई उपयोगी विश्लेषणमा बदल्नुहोस्।';

  @override
  String get heroSettingsTitle => 'खाता र प्राथमिकताहरू।';

  @override
  String get heroSettingsSubtitle =>
      'पात्रो, मुद्रा, र डाटा गोपनीयता विकल्पहरू व्यवस्थापन गर्नुहोस्।';

  @override
  String get addMoney => 'रकम थप्नुहोस्';

  @override
  String get addExpense => 'खर्च थप्नुहोस्';

  @override
  String get calendarNepaliBs => 'नेपाली (वि.सं.)';

  @override
  String get calendarEnglishAd => 'अंग्रेजी (ई.सं.)';

  @override
  String get previousMonth => 'अघिल्लो महिना';

  @override
  String get nextMonth => 'पछिल्लो महिना';

  @override
  String get currencyNpr => 'मुद्रा: नेपाली रूपैयाँ (NPR)';

  @override
  String get recordedBalance => 'अभिलेख मौज्दात';

  @override
  String get recordedBalanceSubtitle =>
      'सम्पूर्ण आम्दानीबाट खर्च घटाउँदा बाँकी';

  @override
  String get moneyIn => 'आएको रकम';

  @override
  String get moneyInSubtitle => 'छनोट गरिएको महिनाको आम्दानी';

  @override
  String get moneyOut => 'गएको रकम';

  @override
  String get moneyOutSubtitle => 'छनोट गरिएको महिनाको खर्च';

  @override
  String get monthlyNet => 'मासिक खुद';

  @override
  String transactionsCount(int count) {
    return '$count कारोबार';
  }

  @override
  String get onboardingTip =>
      'आजै सुरु गर्दै हुनुहुन्छ? तपाईंसँग पहिल्यै भएको रकम \'सुरुवाती मौज्दात\' श्रेणीबाट थप्नुहोस्। यो व्यक्तिगत खाता हो, बैंक खाता जोडिएको होइन।';

  @override
  String get dailySpending => 'दैनिक खर्च';

  @override
  String get addExpenseToStartTimeline =>
      'आफ्नो खर्चको विवरण सुरु गर्न खर्च थप्नुहोस्।';

  @override
  String highestDay(String amount) {
    return 'सबैभन्दा बढी भएको दिन: $amount';
  }

  @override
  String get dayOfMonth => 'महिनाको गते/दिन';

  @override
  String get spendingByCategory => 'श्रेणी अनुसार खर्च';

  @override
  String get categoriesEmpty => 'तपाईंको श्रेणीहरूको विवरण यहाँ देखिनेछ।';

  @override
  String get monthlyPerspective => 'तपाईंको मासिक विश्लेषण';

  @override
  String get noSpendingLastMonth =>
      'तुलना गर्न गत महिना कुनै खर्च रेकर्ड गरिएको छैन।';

  @override
  String moreThanLastMonth(String amount) {
    return 'गत महिनाभन्दा $amount बढी।';
  }

  @override
  String lessThanLastMonth(String amount) {
    return 'गत महिनाभन्दा $amount कम।';
  }

  @override
  String get monthlyComparisonNotice =>
      'तुलना पूरा क्यालेन्डर महिना अनुसार गरिन्छ। चालू महिनाको कुल खर्च कम हुन सक्छ।';

  @override
  String get recentTransactions => 'हालैका कारोबारहरू';

  @override
  String get transactionHistory => 'कारोबार इतिहास';

  @override
  String get filterAllTransactions => 'सबै कारोबार';

  @override
  String get filterIncome => 'आम्दानी';

  @override
  String get filterExpenses => 'खर्च';

  @override
  String get searchHint => 'शीर्षक वा टिपोट खोज्नुहोस्';

  @override
  String get clearSearchTooltip => 'खोज हटाउनुहोस्';

  @override
  String resultsCount(int count) {
    return '$count नतिजाहरू';
  }

  @override
  String get sortNewestFirst => 'नयाँ पहिले';

  @override
  String get sortOldestFirst => 'पुरानो पहिले';

  @override
  String get sortHighestAmount => 'उच्च रकम';

  @override
  String get sortLowestAmount => 'न्यून रकम';

  @override
  String get noMatchingTransactions => 'कुनै मिल्दो कारोबार फेला परेन';

  @override
  String get freshStartThisMonth => 'यो महिनाको नयाँ सुरुवात';

  @override
  String get emptyTransactionsPrompt =>
      'रकम वा खर्च थप्नुहोस्, वा अर्को महिना वा फिल्टर छान्नुहोस्।';

  @override
  String get editTransaction => 'कारोबार सम्पादन गर्नुहोस्';

  @override
  String get deleteTransaction => 'कारोबार मेटाउनुहोस्';

  @override
  String get viewAll => 'सबै हेर्नुहोस्';

  @override
  String get copyCsvTooltip =>
      'फिल्टर गरिएका कारोबार CSV को रूपमा प्रतिलिपि गर्नुहोस्';

  @override
  String get deleteTransactionDialogTitle => 'यो कारोबार मेटाउने?';

  @override
  String get actionCannotBeUndone => 'यो कार्य फिर्ता गर्न सकिँदैन।';

  @override
  String get keepExpense => 'खर्च राख्नुहोस्';

  @override
  String get delete => 'मेटाउनुहोस्';

  @override
  String get transactionSavedSuccess => 'कारोबार सफलतापूर्वक सुरक्षित गरियो।';

  @override
  String get transactionDeletedSuccess => 'कारोबार मेटाइयो।';

  @override
  String get couldNotDeleteError =>
      'मेटाउन सकिएन। कृपया फेरि प्रयास गर्नुहोस्।';

  @override
  String get unableToLoadExpenses => 'तपाईंको खर्च लोड गर्न सकिएन';

  @override
  String get addMoneyTitle => 'रकम थप्नुहोस्';

  @override
  String get editIncomeTitle => 'आम्दानी सम्पादन गर्नुहोस्';

  @override
  String get addExpenseTitle => 'खर्च थप्नुहोस्';

  @override
  String get editExpenseTitle => 'खर्च सम्पादन गर्नुहोस्';

  @override
  String get expenseEditorSubtitle =>
      'विवरण स्पष्ट राख्नुहोस्। तपाईंको कुल रकम र विश्लेषण स्वतः अद्यावधिक हुन्छन्।';

  @override
  String get whereFromLabel => 'रकम कहाँबाट आयो?';

  @override
  String get whatForLabel => 'के को लागि खर्च भयो?';

  @override
  String get octoberSalaryHint => 'जस्तै: असोजको तलब';

  @override
  String get lunchCafeHint => 'जस्तै: क्याफेमा खाजा';

  @override
  String get enterTitleError => 'शीर्षक प्रविष्ट गर्नुहोस्';

  @override
  String get aiSuggestionsLabel => 'एआई सुझावहरू:';

  @override
  String aiSuggestionsForCategory(String category) {
    return '$category का लागि सुझावहरू';
  }

  @override
  String get autoGenerateAiTooltip => 'एआई द्वारा स्वतः सिर्जना गर्नुहोस्';

  @override
  String get scrollLeftTooltip => 'बायाँ सार्नुहोस्';

  @override
  String get scrollRightTooltip => 'दायाँ सार्नुहोस्';

  @override
  String get autoGenerate => 'स्वतः';

  @override
  String get clearTitleTooltip => 'शीर्षक खाली गर्नुहोस्';

  @override
  String get amountLabel => 'रकम';

  @override
  String get amountReceivedHelper =>
      'तपाईंले प्राप्त गरेको रकम प्रविष्ट गर्नुहोस्';

  @override
  String get amountPaidHelper => 'तपाईंले तिरेको रकम प्रविष्ट गर्नुहोस्';

  @override
  String get invalidAmountError =>
      '२ दशमलवसम्मको मान्य सकारात्मक रकम प्रविष्ट गर्नुहोस्';

  @override
  String get categoryLabel => 'श्रेणी';

  @override
  String get noteOptionalLabel => 'टिपोट (वैकल्पिक)';

  @override
  String get saveIncomeButton => 'आम्दानी सुरक्षित गर्नुहोस्';

  @override
  String get saveExpenseButton => 'खर्च सुरक्षित गर्नुहोस्';

  @override
  String get savingButton => 'सुरक्षित गर्दै…';

  @override
  String get couldNotSaveError =>
      'सुरक्षित गर्न सकिएन। इन्टरनेट जाँच गरी फेरि प्रयास गर्नुहोस्।';

  @override
  String get monthlyFinancialReportTitle => 'मासिक वित्तीय प्रतिवेदन';

  @override
  String get reportIncome => 'आम्दानी';

  @override
  String get reportExpenses => 'खर्च';

  @override
  String get reportNetSavings => 'खुद बचत';

  @override
  String get reportSavingsRate => 'बचत दर';

  @override
  String get reportSpendingByCategory => 'श्रेणी अनुसार खर्च';

  @override
  String get close => 'बन्द गर्नुहोस्';

  @override
  String get exportCsv => 'CSV निर्यात';

  @override
  String get shareSummary => 'सारांश सेयर';

  @override
  String get reportSummaryCopied =>
      'वित्तीय प्रतिवेदन सारांश कपी गरियो! सेयर गर्न तयार छ।';

  @override
  String get reportCsvCopied => 'मासिक CSV कारोबार क्लिपबोर्डमा कपी गरियो!';

  @override
  String get catFood => 'खाना';

  @override
  String get catTransport => 'यातायात';

  @override
  String get catShopping => 'किनमेल';

  @override
  String get catBills => 'बिल / महसुल';

  @override
  String get catHealth => 'स्वास्थ्य';

  @override
  String get catEducation => 'शिक्षा';

  @override
  String get catOther => 'अन्य';

  @override
  String get catSalary => 'तलब';

  @override
  String get catFreelance => 'फ्रिलान्स';

  @override
  String get catAllowance => 'भत्ता';

  @override
  String get catGift => 'उपहार';

  @override
  String get catRefund => 'फिर्ता रकम';

  @override
  String get catOpeningBalance => 'सुरुवाती मौज्दात';

  @override
  String get catOtherIncome => 'अन्य आम्दानी';

  @override
  String get catAll => 'सबै';
}
