import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:expense_tracker/models/expense.dart';
import 'package:expense_tracker/providers/auth_provider.dart';
import 'package:expense_tracker/providers/expense_provider.dart';
import 'package:expense_tracker/screens/settings_screen.dart';
import 'package:expense_tracker/services/account_deletion_service.dart';
import 'package:expense_tracker/theme.dart';
import 'package:expense_tracker/models/calendar_period.dart';

class MockAuth extends ChangeNotifier implements AuthProvider {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  @override
  get user => null;

  bool signedOut = false;
  bool accountDeleted = false;

  @override
  Future<void> signOut() async {
    signedOut = true;
    notifyListeners();
  }

  @override
  Future<void> deleteAccount({
    required Future<AuthCredential?> Function(User user) onReauthenticate,
    AccountDeletionService? deletionService,
  }) async {
    accountDeleted = true;
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

class PasswordUser extends Fake implements User {
  @override
  String get email => 'test@example.com';
  @override
  bool get isAnonymous => false;
  @override
  List<UserInfo> get providerData => [];
}

class PasswordAuth extends MockAuth {
  final passwordUser = PasswordUser();
  String? confirmedPassword;
  @override
  User get user => passwordUser;
  @override
  Future<void> deleteAccount({
    required Future<AuthCredential?> Function(User user) onReauthenticate,
    AccountDeletionService? deletionService,
  }) async {
    final credential = await onReauthenticate(passwordUser);
    confirmedPassword = (credential as EmailAuthCredential).password;
  }
}

void main() {
  for (final submitWithKeyboard in [false, true]) {
    testWidgets(
      'Password confirmation preserves spaces (keyboard: $submitWithKeyboard)',
      (tester) async {
        tester.view.physicalSize = const Size(800, 1200);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final auth = PasswordAuth();
        final expenses = MockExpenses();
        addTearDown(auth.dispose);
        addTearDown(expenses.dispose);
        await tester.pumpWidget(
          ChangeNotifierProvider<AuthProvider>.value(
            value: auth,
            child: MaterialApp(
              routes: {'/login': (_) => const Scaffold(body: Text('Login'))},
              home: Scaffold(
                body: SingleChildScrollView(
                  child: SettingsScreen(expenseProvider: expenses),
                ),
              ),
            ),
          ),
        );
        expect(find.text('Signed-in account'), findsOneWidget);
        expect(find.textContaining('2FA enabled'), findsNothing);
        final delete = find.widgetWithText(FilledButton, 'Delete Account');
        await tester.ensureVisible(delete);
        await tester.tap(delete);
        await tester.pumpAndSettle();
        await tester.tap(
          find.descendant(of: find.byType(AlertDialog), matching: delete),
        );
        // The settings page shows a progress indicator while reauthentication is pending.
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));
        await tester.enterText(
          find.byType(TextField),
          ' password with spaces ',
        );
        if (submitWithKeyboard) {
          await tester.testTextInput.receiveAction(TextInputAction.done);
        } else {
          await tester.tap(find.text('Confirm'));
        }
        await tester.pumpAndSettle();
        expect(auth.confirmedPassword, ' password with spaces ');
      },
    );
  }
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
      expect(
        find.text('Your data will be deleted in 1 minute'),
        findsOneWidget,
      );
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

      expect(
        find.text('Data deletion cancelled. Your data is safe.'),
        findsOneWidget,
      );
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

  testWidgets(
    'SettingsScreen shows confirmation dialog on Delete Account and cancels cleanly',
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
            routes: {
              '/login': (context) => const Scaffold(body: Text('Login Screen')),
            },
            home: Scaffold(
              body: SingleChildScrollView(
                child: SettingsScreen(expenseProvider: mockExpenses),
              ),
            ),
          ),
        ),
      );

      expect(
        find.widgetWithText(FilledButton, 'Delete Account'),
        findsOneWidget,
      );

      await tester.ensureVisible(
        find.widgetWithText(FilledButton, 'Delete Account'),
      );
      await tester.tap(find.widgetWithText(FilledButton, 'Delete Account'));
      await tester.pumpAndSettle();

      // Check dialog
      expect(find.text('Delete Account Permanently?'), findsOneWidget);
      expect(
        find.textContaining('This will permanently delete your Pocket account'),
        findsOneWidget,
      );

      // Cancel
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(find.text('Delete Account Permanently?'), findsNothing);
      expect(mockAuth.accountDeleted, isFalse);
    },
  );

  testWidgets(
    'SettingsScreen triggers account deletion and routes to /login when confirmed',
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
            routes: {
              '/login': (context) => const Scaffold(body: Text('Login Screen')),
            },
            home: Scaffold(
              body: SingleChildScrollView(
                child: SettingsScreen(expenseProvider: mockExpenses),
              ),
            ),
          ),
        ),
      );

      await tester.ensureVisible(
        find.widgetWithText(FilledButton, 'Delete Account'),
      );
      await tester.tap(find.widgetWithText(FilledButton, 'Delete Account'));
      await tester.pumpAndSettle();

      // Tap confirm button in dialog
      final dialogDeleteBtn = find.descendant(
        of: find.byType(AlertDialog),
        matching: find.widgetWithText(FilledButton, 'Delete Account'),
      );
      await tester.tap(dialogDeleteBtn);
      await tester.pumpAndSettle();

      expect(mockAuth.accountDeleted, isTrue);
      expect(find.text('Login Screen'), findsOneWidget);
      expect(
        find.text(
          'Your account and all associated data have been permanently deleted.',
        ),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'SettingsScreen countdown automatically executes deletion when 60 seconds elapses',
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

      expect(
        find.text('Your data will be deleted in 1 minute'),
        findsOneWidget,
      );

      // Elapse the full 60 seconds
      for (int i = 0; i < 60; i++) {
        await tester.pump(const Duration(seconds: 1));
      }
      await tester.pump(const Duration(milliseconds: 100));

      expect(mockExpenses.deletedAll, isTrue);
      expect(
        find.text('All your records have been permanently deleted.'),
        findsOneWidget,
      );
    },
  );
}
