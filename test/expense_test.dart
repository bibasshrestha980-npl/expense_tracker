import 'package:flutter_test/flutter_test.dart';
import 'package:expense_tracker/models/expense.dart';
import 'package:expense_tracker/main.dart';

void main() {
  test('Amounts preserve cents without floating point rounding', () {
    expect(parseAmount('12.34'), 1234);
    expect(parseAmount('0.01'), 1);
    expect(parseAmount('100'), 10000);
    expect(parseAmount(' 12.5 '), 1250);
    for (final value in ['0', '-1', 'NaN', '1.001', '', '1e5', '1000000000']) {
      expect(parseAmount(value), isNull, reason: value);
    }
  });
  testWidgets('Firebase initialization failure has an actionable screen', (
    tester,
  ) async {
    await tester.pumpWidget(const ExpenseApp(setupError: 'Follow README.md'));
    expect(find.text('Welcome to Pocket'), findsOneWidget);
    expect(find.text('Follow README.md'), findsOneWidget);
  });
}
