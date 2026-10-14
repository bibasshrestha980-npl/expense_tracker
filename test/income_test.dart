import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:expense_tracker/screens/expense_editor.dart';
import 'package:expense_tracker/theme.dart';
import 'package:expense_tracker/models/expense.dart';
import 'package:expense_tracker/providers/expense_provider.dart';

void main() {
  testWidgets('Add money form saves a salary transaction', (tester) async {
    final db = FakeFirebaseFirestore();
    final provider = ExpenseProvider('income-form', firestore: db);
    addTearDown(provider.dispose);
    await tester.pumpWidget(
      MaterialApp(
        theme: pocketTheme(),
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => showDialog<void>(
                context: context,
                builder: (_) => ExpenseEditor(provider: provider, income: true),
              ),
              child: const Text('Open income'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open income'));
    await tester.pumpAndSettle();
    expect(find.text('Add money'), findsOneWidget);
    await tester.enterText(find.byType(TextFormField).at(0), 'October salary');
    await tester.enterText(find.byType(TextFormField).at(1), '25000');
    await tester.tap(find.text('Save income'));
    await tester.pumpAndSettle();
    final docs = await provider.collection.get();
    expect(docs.docs.single.data()['type'], 'income');
    expect(docs.docs.single.data()['category'], 'Salary');
    expect(docs.docs.single.data()['amountCents'], 2500000);
    expect(provider.balance, 2500000);
    expect(provider.total, 0);
  });
  test('Income, legacy expenses, edits and deletes update the ledger independently of spending', () async {
    final db = FakeFirebaseFirestore();
    final collection = db
        .collection('users')
        .doc('test-user')
        .collection('expenses');
    final old = Expense(
      id: '',
      title: 'Lunch',
      category: 'Food',
      amountCents: 15000,
      date: DateTime(2026, 10, 2),
    ).toMap()..remove('type');
    await collection.doc('legacy').set(old);
    await collection
        .doc('salary')
        .set(
          Expense(
            id: '',
            title: 'Salary',
            category: 'Salary',
            amountCents: 100000,
            date: DateTime(2026, 10, 1),
            isIncome: true,
          ).toMap(),
        );
    final provider = ExpenseProvider('test-user', firestore: db);
    addTearDown(provider.dispose);
    provider.month = DateTime(2026, 10);
    Future<void> settled() =>
        Future<void>.delayed(const Duration(milliseconds: 30));
    await settled();
    expect(provider.income, 100000);
    expect(provider.total, 15000);
    expect(provider.balance, 85000);
    expect(provider.monthly.length, 1);
    expect(provider.dailyTotals.reduce((a, b) => a + b), 15000);
    provider.setType('Income');
    expect(provider.visible.single.title, 'Salary');
    await provider.save(
      Expense(
        id: 'salary',
        title: 'Salary revised',
        category: 'Salary',
        amountCents: 120000,
        date: DateTime(2026, 10, 1),
        isIncome: true,
      ),
    );
    await settled();
    expect(provider.balance, 105000);
    await provider.delete('salary');
    await settled();
    expect(provider.income, 0);
    expect(provider.balance, -15000);
    expect(provider.total, 15000);
  });
}
