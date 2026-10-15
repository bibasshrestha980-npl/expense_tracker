import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:expense_tracker/models/expense.dart';
import 'package:expense_tracker/providers/auth_provider.dart';
import 'package:expense_tracker/providers/expense_provider.dart';
import 'package:expense_tracker/screens/settings_screen.dart';
import 'package:expense_tracker/theme.dart';
import 'package:expense_tracker/models/calendar_period.dart';

class MockAuth extends ChangeNotifier implements AuthProvider {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  @override
  get user => null;

  bool signedOut = false;
  @override
  Future<void> signOut() async {
    signedOut = true;
    notifyListeners();
  }
}

class MockExpenses extends ChangeNotifier implements ExpenseProvider {
  bool deletedAll = false;
  @override
  bool nepali = true;
  @override
  int get income => 50000;
  @override
  int get total => 20000;
  @override
  List<Expense> get monthlyTransactions => [];
  @override
  CalendarPeriod get period => CalendarPeriod(DateTime(2026, 10), nepali: true);

  @override
  void setCalendar(bool value) {
    nepali = value;
    notifyListeners();
  }

  @override
  Future<void> deleteAllData() async {
    deletedAll = true;
    notifyListeners();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  testWidgets('SettingsScreen renders account, preferences and danger zone', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final mockAuth = MockAuth();
    final mockExpenses = MockExpenses();

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<AuthProvider>.value(value: mockAuth),
          ChangeNotifierProvider<ExpenseProvider>.value(value: mockExpenses),
        ],
        child: MaterialApp(
          theme: pocketTheme(),
          home: Scaffold(
            body: SingleChildScrollView(
              child: SettingsScreen(expenseProvider: mockExpenses),
            ),
          ),
        ),
      ),
    );

    expect(find.text('Account & Security'), findsOneWidget);
    expect(find.text('Preferences'), findsOneWidget);
    expect(find.text('Danger Zone'), findsOneWidget);
    expect(find.text('Delete My Data'), findsOneWidget);
    expect(find.text('Base Currency'), findsOneWidget);
    expect(find.text('Nepali Bikram Sambat (BS) Calendar'), findsOneWidget);
  });

  testWidgets(
    'SettingsScreen triggers 1-minute countdown on Delete My Data and allows Cancel',
    (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final mockAuth = MockAuth();
      final mockExpenses = MockExpenses();

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<AuthProvider>.value(value: mockAuth),
            ChangeNotifierProvider<ExpenseProvider>.value(value: mockExpenses),
          ],
          child: MaterialApp(
            theme: pocketTheme(),
            home: Scaffold(
              body: SingleChildScrollView(
                child: SettingsScreen(expenseProvider: mockExpenses),
              ),
            ),
          ),
        ),
      );

      // Tap Delete My Data
      await tester.ensureVisible(find.text('Delete My Data'));
      await tester.tap(find.text('Delete My Data'));
      await tester.pump();

      // Verify explicit notification text
      expect(find.text('Your data will be deleted in 1 minute'), findsOneWidget);
      expect(find.text('01:00'), findsOneWidget);
      expect(find.text('Cancel Deletion'), findsOneWidget);
      expect(find.text('Delete Immediately'), findsOneWidget);

      // Advance 1 second
      await tester.pump(const Duration(seconds: 1));
      expect(find.text('00:59'), findsOneWidget);

      // Cancel countdown
      await tester.ensureVisible(find.text('Cancel Deletion'));
      await tester.tap(find.text('Cancel Deletion'));
      await tester.pump();

      expect(find.text('Data deletion cancelled. Your data is safe.'), findsOneWidget);
      expect(find.text('Delete My Data'), findsOneWidget);
      expect(mockExpenses.deletedAll, isFalse);
    },
  );

  testWidgets(
    'SettingsScreen triggers immediate deletion when Delete Immediately is tapped',
    (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final mockAuth = MockAuth();
      final mockExpenses = MockExpenses();

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<AuthProvider>.value(value: mockAuth),
            ChangeNotifierProvider<ExpenseProvider>.value(value: mockExpenses),
          ],
          child: MaterialApp(
            theme: pocketTheme(),
            home: Scaffold(
              body: SingleChildScrollView(
                child: SettingsScreen(expenseProvider: mockExpenses),
              ),
            ),
          ),
        ),
      );

      await tester.ensureVisible(find.text('Delete My Data'));
      await tester.tap(find.text('Delete My Data'));
      await tester.pump();

      expect(find.text('Delete Immediately'), findsOneWidget);
      await tester.ensureVisible(find.text('Delete Immediately'));
      await tester.tap(find.text('Delete Immediately'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(mockExpenses.deletedAll, isTrue);
      expect(
        find.text('All your records have been permanently deleted.'),
        findsOneWidget,
      );
    },
  );
}
