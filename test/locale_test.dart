import 'package:expense_tracker/l10n/generated/app_localizations.dart';
import 'package:expense_tracker/providers/auth_provider.dart';
import 'package:expense_tracker/providers/expense_provider.dart';
import 'package:expense_tracker/providers/locale_provider.dart';
import 'package:expense_tracker/screens/dashboard.dart';
import 'package:expense_tracker/screens/expense_editor.dart';
import 'package:expense_tracker/screens/settings_screen.dart';
import 'package:expense_tracker/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'dashboard_test.dart' show TestAuth, TestExpenses;

// ignore: must_be_immutable
class MemoryPreferences extends Fake implements SharedPreferencesAsync {
  String? saved;
  bool fail = false;

  @override
  Future<String?> getString(String key) async {
    if (fail) throw StateError('Storage unavailable');
    return saved;
  }

  @override
  Future<void> setString(String key, String value) async {
    if (fail) throw StateError('Storage unavailable');
    saved = value;
  }

  @override
  Future<void> remove(String key) async {
    if (fail) throw StateError('Storage unavailable');
    saved = null;
  }
}

void main() {
  group('LocaleProvider Unit Tests', () {
    test('Defaults to follow system (null)', () async {
      final prefs = MemoryPreferences();
      final provider = LocaleProvider(preferences: prefs);
      addTearDown(provider.dispose);
      await provider.load();
      expect(provider.locale, isNull);
      expect(provider.languageCode, 'system');
      expect(provider.isEnglish, isFalse);
      expect(provider.isNepali, isFalse);
    });

    test('Loads saved English and Nepali preferences', () async {
      final prefs = MemoryPreferences()..saved = 'ne';
      final provider = LocaleProvider(preferences: prefs);
      addTearDown(provider.dispose);
      await provider.load();
      expect(provider.locale, const Locale('ne'));
      expect(provider.isNepali, isTrue);

      await provider.setLanguageCode('en');
      expect(provider.locale, const Locale('en'));
      expect(provider.isEnglish, isTrue);
      expect(prefs.saved, 'en');

      await provider.setLanguageCode('system');
      expect(provider.locale, isNull);
      expect(prefs.saved, isNull);
    });

    test('Toggles between Nepali and English', () async {
      final prefs = MemoryPreferences()..saved = 'en';
      final provider = LocaleProvider(preferences: prefs);
      addTearDown(provider.dispose);
      await provider.load();
      expect(provider.isEnglish, isTrue);

      await provider.toggleLocale();
      expect(provider.isNepali, isTrue);
      expect(prefs.saved, 'ne');

      await provider.toggleLocale();
      expect(provider.isEnglish, isTrue);
      expect(prefs.saved, 'en');
    });

    test('Recovers gracefully on storage failure', () async {
      final prefs = MemoryPreferences()..fail = true;
      final provider = LocaleProvider(preferences: prefs);
      addTearDown(provider.dispose);
      await provider.load();
      expect(provider.locale, isNull);
    });
  });

  group('Language Setting Widget Tests', () {
    testWidgets('SettingsScreen changes language and applies translation', (
      tester,
    ) async {
      final prefs = MemoryPreferences();
      final localeProvider = LocaleProvider(preferences: prefs);
      final expenses = TestExpenses();
      addTearDown(localeProvider.dispose);
      addTearDown(expenses.dispose);

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: localeProvider),
            ChangeNotifierProvider<AuthProvider>(create: (_) => TestAuth()),
          ],
          child: Builder(
            builder: (context) {
              return MaterialApp(
                theme: pocketTheme(),
                locale: context.watch<LocaleProvider>().locale,
                localizationsDelegates: AppLocalizations.localizationsDelegates,
                supportedLocales: AppLocalizations.supportedLocales,
                home: Scaffold(
                  body: SingleChildScrollView(
                    child: SettingsScreen(expenseProvider: expenses),
                  ),
                ),
              );
            },
          ),
        ),
      );

      // Initially in English
      expect(find.text('Preferences'), findsOneWidget);

      // Find the Language dropdown
      final langDropdown = find.byType(DropdownButtonFormField<String>);
      await tester.ensureVisible(langDropdown);
      await tester.tap(langDropdown);
      await tester.pumpAndSettle();

      // Select Nepali
      await tester.tap(find.text('नेपाली (Nepali)').last);
      await tester.pumpAndSettle();

      // Verify language changed to Nepali: 'प्राथमिकताहरू' replaces 'Preferences'
      expect(find.text('प्राथमिकताहरू'), findsOneWidget);
      expect(localeProvider.isNepali, isTrue);
      expect(prefs.saved, 'ne');

      // Change back to English
      await tester.ensureVisible(langDropdown);
      await tester.tap(langDropdown);
      await tester.pumpAndSettle();
      await tester.tap(find.text('English (अंग्रेजी)').last);
      await tester.pumpAndSettle();

      expect(find.text('Preferences'), findsOneWidget);
      expect(localeProvider.isEnglish, isTrue);
      expect(prefs.saved, 'en');
    });

    testWidgets('Dashboard renders in full Nepali and live toggles with English', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1200, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final prefs = MemoryPreferences()..saved = 'ne';
      final localeProvider = LocaleProvider(preferences: prefs);
      final expenses = TestExpenses();
      addTearDown(localeProvider.dispose);
      addTearDown(expenses.dispose);
      await localeProvider.load();

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: localeProvider),
            ChangeNotifierProvider<AuthProvider>(create: (_) => TestAuth()),
            ChangeNotifierProvider<ExpenseProvider>.value(value: expenses),
          ],
          child: Builder(
            builder: (context) {
              return MaterialApp(
                theme: pocketTheme(),
                locale: context.watch<LocaleProvider>().locale,
                localizationsDelegates: AppLocalizations.localizationsDelegates,
                supportedLocales: AppLocalizations.supportedLocales,
                home: const Dashboard(),
              );
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify Nepali dashboard strings
      expect(find.text('समीक्षा'), findsWidgets); // Nav item
      expect(find.text('कारोबारहरू'), findsWidgets); // Nav item
      expect(find.text('अन्तरदृष्टि'), findsWidgets); // Nav item
      expect(find.text('सेटिङहरू'), findsWidgets); // Nav item
      expect(find.text('अभिलेख मौज्दात'), findsOneWidget); // Recorded balance
      expect(find.text('आएको रकम'), findsOneWidget); // Money in
      expect(find.text('गएको रकम'), findsOneWidget); // Money out
      expect(find.text('रकम थप्नुहोस्'), findsOneWidget); // Add money
      expect(find.text('खर्च थप्नुहोस्'), findsOneWidget); // Add expense
      expect(find.text('अलिकति स्पष्टता। धेरै नियन्त्रण।'), findsOneWidget); // Hero title
      expect(find.text('नेपाली (वि.सं.)'), findsOneWidget); // Calendar segment
      expect(find.text('प्रतिवेदन सेयर'), findsOneWidget); // Share report

      // Navigate to Transactions in Nepali
      await tester.tap(find.text('कारोबारहरू').first);
      await tester.pumpAndSettle();
      expect(find.text('कारोबार इतिहास'), findsOneWidget);
      expect(find.text('सबै कारोबार'), findsOneWidget);
      expect(find.text('शीर्षक वा टिपोट खोज्नुहोस्'), findsOneWidget);

      // Navigate to Insights in Nepali
      await tester.tap(find.text('अन्तरदृष्टि').first);
      await tester.pumpAndSettle();
      expect(find.text('दैनिक खर्च'), findsOneWidget);
      expect(find.text('श्रेणी अनुसार खर्च'), findsOneWidget);

      // Switch language to English
      await localeProvider.setLanguageCode('en');
      await tester.pumpAndSettle();

      // Verify English strings are restored
      expect(find.text('Insights'), findsWidgets);
      expect(find.text('Daily spending'), findsOneWidget);
      expect(find.text('Spending by category'), findsOneWidget);

      await tester.tap(find.text('Overview').first);
      await tester.pumpAndSettle();
      expect(find.text('Recorded balance'), findsOneWidget);
      expect(find.text('Money in'), findsOneWidget);
      expect(find.text('Add money'), findsOneWidget);
    });

    testWidgets('ExpenseEditor renders AI suggestions in Nepali when locale is Nepali', (
      tester,
    ) async {
      final prefs = MemoryPreferences()..saved = 'ne';
      final localeProvider = LocaleProvider(preferences: prefs);
      final expenses = TestExpenses();
      addTearDown(localeProvider.dispose);
      addTearDown(expenses.dispose);
      await localeProvider.load();

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: localeProvider),
            ChangeNotifierProvider<ExpenseProvider>.value(value: expenses),
          ],
          child: Builder(
            builder: (context) {
              return MaterialApp(
                theme: pocketTheme(),
                locale: context.watch<LocaleProvider>().locale,
                localizationsDelegates: AppLocalizations.localizationsDelegates,
                supportedLocales: AppLocalizations.supportedLocales,
                home: Scaffold(
                  body: ExpenseEditor(provider: expenses, income: true),
                ),
              );
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify Nepali AI suggestion chips for Salary:
      // 'मासिक तलब', 'पेस्की तलब', 'बोनस रकम'
      expect(find.text('मासिक तलब'), findsOneWidget);
      expect(find.text('पेस्की तलब'), findsOneWidget);
      expect(find.text('बोनस रकम'), findsOneWidget);
      expect(find.text('वि.सं.'), findsOneWidget);
      expect(find.text('ई.सं.'), findsOneWidget);

      // Tap 'पेस्की तलब' chip
      await tester.tap(find.text('पेस्की तलब'));
      await tester.pumpAndSettle();

      final titleField = find.byType(TextFormField).first;
      expect(
        tester.widget<TextFormField>(titleField).controller!.text,
        'पेस्की तलब',
      );
    });
  });
}
