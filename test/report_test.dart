import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:expense_tracker/models/expense.dart';
import 'package:expense_tracker/models/sip.dart';
import 'package:expense_tracker/providers/expense_provider.dart';
import 'package:expense_tracker/providers/sip_provider.dart';
import 'package:expense_tracker/screens/report_dialog.dart';

void main() {
  testWidgets('ReportDialog displays financial summary and category breakdown', (tester) async {
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

    final sampleSips = [
      Sip(
        id: 'sip_1',
        name: 'NIBL Sahabhagita',
        monthlyAmountCents: 500000, // NPR 5,000
        dayOfMonth: 15,
        startDate: DateTime(2026, 1, 1),
      ),
    ];

    final expProvider = ExpenseProvider('', initialExpenses: sampleExpenses);
    final sipProvider = SipProvider('', initialSips: sampleSips);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ReportDialog(
            expenseProvider: expProvider,
            sipProvider: sipProvider,
          ),
        ),
      ),
    );

    expect(find.text('Monthly Financial Report'), findsOneWidget);
    expect(find.text('Income'), findsOneWidget);
    expect(find.text('Expenses'), findsOneWidget);
    expect(find.text('Net Savings'), findsOneWidget);
    expect(find.text('Spending by Category'), findsOneWidget);
    expect(find.text('Food'), findsOneWidget);
    expect(find.text('Bills'), findsOneWidget);
    expect(find.text('SIP Investments'), findsOneWidget);
    expect(find.text('Share Summary'), findsOneWidget);
    expect(find.text('Export CSV'), findsOneWidget);
  });
}
