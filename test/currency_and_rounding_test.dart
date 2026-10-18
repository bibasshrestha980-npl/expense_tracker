import 'package:flutter_test/flutter_test.dart';
import 'package:expense_tracker/models/expense.dart';

void main() {
  group('Currency & Precision Formatting Tests', () {
    test('Expense amount in cents correctly converts to float rupees', () {
      final expense = Expense(
        id: 'test-1',
        title: 'Momo & Tea',
        amountCents: 25050, // Rs. 250.50
        category: 'Food',
        date: DateTime(2026, 10, 18),
      );

      expect(expense.amountCents, 25050);
      expect(expense.amountCents / 100.0, 250.50);
    });

    test('Income transaction handles large values without overflow', () {
      final income = Expense(
        id: 'test-inc-1',
        title: 'Software Development Project',
        amountCents: 15000000, // Rs. 150,000.00
        category: 'Salary',
        date: DateTime(2026, 10, 18),
        isIncome: true,
      );

      expect(income.isIncome, isTrue);
      expect(income.amountCents, 15000000);
      expect((income.amountCents / 100).toStringAsFixed(2), '150000.00');
    });

    test('Zero amount handles safely without negative sign', () {
      final expense = Expense(
        id: 'zero-test',
        title: 'Free sample',
        amountCents: 0,
        category: 'Other',
        date: DateTime(2026, 10, 18),
      );

      expect(expense.amountCents, 0);
      expect((expense.amountCents / 100).toStringAsFixed(0), '0');
    });
  });
}
