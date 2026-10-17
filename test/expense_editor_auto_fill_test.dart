import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:expense_tracker/l10n/generated/app_localizations.dart';
import 'package:expense_tracker/models/expense.dart';
import 'package:expense_tracker/models/calendar_period.dart';
import 'package:expense_tracker/providers/expense_provider.dart';
import 'package:expense_tracker/screens/expense_editor.dart';
import 'package:expense_tracker/theme.dart';

class AutoFillTestExpenses extends ChangeNotifier implements ExpenseProvider {
  Expense? lastSaved;
  @override
  bool nepali = false;
  @override
  int get income => 0;
  @override
  int get balance => 0;
  @override
  int get total => 0;
  @override
  int get monthlyNet => 0;
  @override
  int get previousTotal => 0;
  @override
  String get category => 'All';
  @override
  String get search => '';
  @override
  String get sort => 'Newest first';
  @override
  String get transactionType => 'All';
  @override
  bool get loading => false;
  @override
  String? get error => null;
  @override
  DateTime get month => DateTime(2026, 10);
  @override
  List<Expense> get monthly => [];
  @override
  List<Expense> get visible => [];
  @override
  List<Expense> get monthlyTransactions => [];

  @override
  CalendarPeriod get period => CalendarPeriod(month, nepali: nepali);

  @override
  Future<void> save(Expense expense) async {
    lastSaved = expense;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  testWidgets('ExpenseEditor auto-fills from eSewa SMS alert', (tester) async {
    final expenses = AutoFillTestExpenses();

    await tester.pumpWidget(
      MaterialApp(
        theme: pocketTheme(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: ExpenseEditor(provider: expenses),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Verify auto-fill button is present
    final autoFillBtn = find.text('Auto-fill from SMS / Wallet');
    expect(autoFillBtn, findsOneWidget);

    // Tap to open parser dialog
    await tester.tap(autoFillBtn);
    await tester.pumpAndSettle();

    expect(find.text('Auto-fill from SMS / Wallet'), findsWidgets);

    // Enter SMS text into the dialog
    final inputField = find.byKey(const Key('sms_input_field'));
    await tester.enterText(
      inputField,
      'Paid Rs. 650 to Himalayan Java via eSewa. Txn ID: ESW554433',
    );
    await tester.pumpAndSettle();

    // Verify preview card shows parsed details
    expect(find.textContaining('Rs. 650.00'), findsOneWidget);
    expect(find.textContaining('Himalayan Java Coffee'), findsOneWidget);
    expect(find.textContaining('Ref ID: ESW554433'), findsOneWidget);

    // Apply details
    await tester.tap(find.text('Apply Details'));
    await tester.pumpAndSettle();

    // Verify editor fields are filled with parsed data
    expect(find.widgetWithText(TextFormField, '650.00'), findsOneWidget);
    expect(find.widgetWithText(TextFormField, 'Himalayan Java Coffee'), findsOneWidget);
    expect(find.widgetWithText(TextFormField, 'Ref: ESW554433'), findsOneWidget);
  });
}
