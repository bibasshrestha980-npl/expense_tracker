import 'package:expense_tracker/main.dart';
import 'package:expense_tracker/providers/auth_provider.dart';
import 'package:expense_tracker/providers/theme_provider.dart';
import 'package:expense_tracker/screens/settings_screen.dart';
import 'package:expense_tracker/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'dashboard_test.dart' show TestAuth, TestExpenses;

// Mutable in-memory fake for testing persistence failures.
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
}

void main() {
  test(
    'Theme choice survives a new provider and supports system reset',
    () async {
      final preferences = MemoryPreferences();
      final theme = ThemeProvider(preferences: preferences);
      await theme.load();
      expect(theme.mode, ThemeMode.system);
      for (final mode in [ThemeMode.dark, ThemeMode.light, ThemeMode.system]) {
        await theme.setMode(mode);
        final restored = ThemeProvider(preferences: preferences);
        await restored.load();
        expect(restored.mode, mode);
        restored.dispose();
      }
      theme.dispose();
    },
  );

  test('Unavailable or invalid preferences fall back safely', () async {
    final preferences = MemoryPreferences()..saved = 'invalid';
    final theme = ThemeProvider(preferences: preferences);
    await theme.load();
    expect(theme.mode, ThemeMode.system);
    preferences.fail = true;
    await theme.load();
    expect(theme.mode, ThemeMode.system);
    await expectLater(theme.setMode(ThemeMode.dark), throwsStateError);
    expect(theme.mode, ThemeMode.system);
    theme.dispose();
  });

  testWidgets('App follows system brightness and honors an explicit override', (
    tester,
  ) async {
    final theme = ThemeProvider(preferences: MemoryPreferences());
    addTearDown(theme.dispose);
    addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
    tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: theme,
        child: const ExpenseApp(setupError: 'Test setup screen'),
      ),
    );
    expect(
      Theme.of(tester.element(find.byType(Scaffold))).brightness,
      Brightness.dark,
    );
    await theme.setMode(ThemeMode.light);
    await tester.pumpAndSettle();
    expect(
      Theme.of(tester.element(find.byType(Scaffold))).brightness,
      Brightness.light,
    );
    await theme.setMode(ThemeMode.system);
    await tester.pumpAndSettle();
    expect(
      Theme.of(tester.element(find.byType(Scaffold))).brightness,
      Brightness.dark,
    );
  });

  testWidgets('Appearance selector changes the active theme and saves it', (
    tester,
  ) async {
    final preferences = MemoryPreferences();
    final theme = ThemeProvider(preferences: preferences);
    final expenses = TestExpenses();
    addTearDown(theme.dispose);
    addTearDown(expenses.dispose);
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: theme),
          ChangeNotifierProvider<AuthProvider>(create: (_) => TestAuth()),
        ],
        child: Builder(
          builder: (context) => MaterialApp(
            theme: pocketTheme(),
            darkTheme: pocketTheme(brightness: Brightness.dark),
            themeMode: context.watch<ThemeProvider>().mode,
            home: Scaffold(
              body: SingleChildScrollView(
                child: SettingsScreen(expenseProvider: expenses),
              ),
            ),
          ),
        ),
      ),
    );
    for (final option in [
      ('Dark', Brightness.dark),
      ('Light', Brightness.light),
    ]) {
      final dropdown = find.byType(DropdownButtonFormField<ThemeMode>);
      await tester.ensureVisible(dropdown);
      await tester.tap(dropdown);
      await tester.pumpAndSettle();
      await tester.tap(find.text(option.$1).last);
      await tester.pumpAndSettle();
      expect(
        Theme.of(tester.element(find.byType(Scaffold))).brightness,
        option.$2,
      );
      expect(preferences.saved, option.$1.toLowerCase());
      expect(tester.takeException(), isNull);
    }
    preferences.fail = true;
    await tester.tap(find.byType(DropdownButtonFormField<ThemeMode>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Dark').last);
    await tester.pumpAndSettle();
    expect(theme.mode, ThemeMode.light);
    expect(
      find.text('Could not save appearance. Please try again.'),
      findsOneWidget,
    );
    expect(
      tester
          .state<FormFieldState<ThemeMode>>(
            find.byType(DropdownButtonFormField<ThemeMode>),
          )
          .value,
      ThemeMode.light,
    );
  });
}
