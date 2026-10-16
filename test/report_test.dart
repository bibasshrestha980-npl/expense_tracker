import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:expense_tracker/models/expense.dart';
import 'package:expense_tracker/providers/expense_provider.dart';
import 'package:expense_tracker/screens/report_dialog.dart';

void main() {
  testWidgets(
    'ReportDialog displays financial summary and category breakdown',
    (tester) async {
      final sampleExpenses = [
        Expense(
          id: '1',
          title: 'Salary Deposit',
          category: 'Salary',
          amountCents: 10000000, // NPR 100,000 income
          date: DateTime(2026, 10, 1),
          isIncome: true,
        ),
        Expense(
          id: '2',
          title: 'Supermarket Grocery',
          category: 'Food',
          amountCents: 2500000, // NPR 25,000 expense
          date: DateTime(2026, 10, 5),
        ),
        Expense(
          id: '3',
          title: 'Electric Bill',
          category: 'Bills',
          amountCents: 500000, // NPR 5,000 expense
          date: DateTime(2026, 10, 8),
        ),
      ];

      final expProvider = ExpenseProvider('', initialExpenses: sampleExpenses)
        ..nepali = false
        ..month = DateTime(2026, 10, 1);
      addTearDown(expProvider.dispose);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: ReportDialog(expenseProvider: expProvider)),
        ),
      );

      expect(find.text('Monthly Financial Report'), findsOneWidget);
      expect(find.text('Income'), findsOneWidget);
      expect(find.text('Expenses'), findsOneWidget);
      expect(find.text('Net Savings'), findsOneWidget);
      expect(find.text('Spending by Category'), findsOneWidget);
      expect(find.text('Food'), findsOneWidget);
      expect(find.text('Bills'), findsOneWidget);
      expect(find.text('Share Summary'), findsOneWidget);
      expect(find.text('Export CSV'), findsOneWidget);
    },
  );

  for (final scenario in [
    (income: 100000, expense: 25000, rate: '75.0%'),
    (income: 100000, expense: 150000, rate: '-50.0%'),
    (income: 0, expense: 25000, rate: '0.0%'),
  ]) {
    testWidgets('Monthly report and copied summary show ${scenario.rate}', (
      tester,
    ) async {
      final provider = ExpenseProvider(
        '',
        initialExpenses: [
          Expense(
            id: 'previous-income',
            title: 'Previous salary',
            category: 'Salary',
            amountCents: 900000,
            date: DateTime(2026, 9, 1),
            isIncome: true,
          ),
          if (scenario.income > 0)
            Expense(
              id: 'income',
              title: 'Salary',
              category: 'Salary',
              amountCents: scenario.income,
              date: DateTime(2026, 10, 1),
              isIncome: true,
            ),
          Expense(
            id: 'expense',
            title: 'Food',
            category: 'Food',
            amountCents: scenario.expense,
            date: DateTime(2026, 10, 2),
          ),
        ],
      )..nepali = false;
      provider.month = DateTime(2026, 10, 1);
      addTearDown(provider.dispose);

      String? copiedText;
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async {
          if (call.method == 'Clipboard.setData') {
            copiedText = (call.arguments as Map)['text'] as String;
          }
          return null;
        },
      );
      addTearDown(() {
        tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          null,
        );
      });

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: ReportDialog(expenseProvider: provider)),
        ),
      );
      expect(find.text(scenario.rate), findsOneWidget);
      await tester.tap(find.text('Share Summary'));
      await tester.pump();
      expect(copiedText, contains('${scenario.rate} savings rate'));
      expect(copiedText, isNot(contains('Previous salary')));
    });
  }
}
