import 'package:expense_tracker/l10n/generated/app_localizations.dart';
import 'package:expense_tracker/providers/auth_provider.dart';
import 'package:expense_tracker/providers/locale_provider.dart';
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
  });
}
