import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:expense_tracker/models/expense.dart';
import 'package:expense_tracker/providers/auth_provider.dart';
import 'package:expense_tracker/providers/expense_provider.dart';
import 'package:expense_tracker/screens/dashboard.dart';
import 'package:expense_tracker/theme.dart';

class TestAuth extends ChangeNotifier implements AuthProvider {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
  @override
  get user => null;
}

class TestExpenses extends ChangeNotifier implements ExpenseProvider {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
  @override
  bool get loading => false;
  @override
  String? get error => null;
  @override
  DateTime get month => DateTime(2026, 10);
  @override
  List<Expense> get monthly => [
    Expense(
      id: '1',
      title: 'Lunch with a deliberately long title to check narrow screens',
      category: 'Food',
      amountCents: 123450,
      date: DateTime(2026, 10, 14),
    ),
  ];
  @override
  List<Expense> get visible => monthly;
  @override
  int get total => 123450;
  @override
  int get previousTotal => 100000;
  @override
  String get category => 'All';
  @override
  String get search => '';
  @override
  String get sort => 'Newest first';
  @override
  int categoryTotal(String value) => value == 'Food' ? total : 0;
  @override
  List<int> get dailyTotals => List.generate(31, (i) => i == 13 ? total : 0);
}

void main() {
  for (final width in [360.0, 1440.0]) {
    testWidgets('Dashboard navigation and layout at width $width', (
      tester,
    ) async {
      tester.view.physicalSize = Size(width, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<AuthProvider>(create: (_) => TestAuth()),
            ChangeNotifierProvider<ExpenseProvider>(
              create: (_) => TestExpenses(),
            ),
          ],
          child: MaterialApp(theme: pocketTheme(), home: const Dashboard()),
        ),
      );
      expect(find.text('Total spending'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.tap(
        find.descendant(
          of: find.byType(width < 950 ? NavigationBar : ListTile),
          matching: find.text('Transactions'),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Transaction history'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.tap(
        find.descendant(
          of: find.byType(width < 950 ? NavigationBar : ListTile),
          matching: find.text('Insights'),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Daily spending'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
