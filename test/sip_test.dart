import 'package:flutter_test/flutter_test.dart';
import 'package:expense_tracker/models/expense.dart';
import 'package:expense_tracker/models/sip.dart';
import 'package:expense_tracker/providers/expense_provider.dart';
import 'package:expense_tracker/providers/sip_provider.dart';

void main() {
  group('Sip Model', () {
    test('Calculates elapsed installments and invested amount correctly', () {
      final startDate = DateTime(2026, 1, 15);
      final sip = Sip(
        id: 'sip_1',
        name: 'NIBL Sahabhagita Fund',
        monthlyAmountCents: 200000, // NPR 2,000
        dayOfMonth: 15,
        startDate: startDate,
        targetMonths: 60,
        expectedReturnRate: 12.0,
      );

      // In October 2026 (month 10) from January 2026 (month 1), elapsed = 10 installments
      final now = DateTime(2026, 10, 14);
      expect(sip.elapsedInstallments(now), 10);
      expect(sip.totalInvestedCents(now), 2000000); // NPR 20,000 in cents

      // Before start date should be 0
      expect(sip.elapsedInstallments(DateTime(2025, 12, 1)), 0);
      expect(sip.totalInvestedCents(DateTime(2025, 12, 1)), 0);

      // Beyond target months caps at target
      expect(sip.elapsedInstallments(DateTime(2035, 1, 1)), 60);
    });

    test('Compound interest corpus calculation produces positive wealth gain', () {
      final sip = Sip(
        id: 'sip_1',
        name: 'Siddhartha Scheme',
        monthlyAmountCents: 500000, // NPR 5,000 / mo
        dayOfMonth: 10,
        startDate: DateTime(2026, 1, 1),
        targetMonths: 120, // 10 years
        expectedReturnRate: 12.0,
      );

      final corpus = sip.calculateCorpus(months: 120, annualRate: 12.0);
      final principal = 5000.0 * 120; // 600,000 NPR
      expect(corpus, greaterThan(principal));
      // At 12% p.a. for 10 years, 5,000/mo reaches ~1.15 million NPR
      expect(corpus, greaterThan(1100000));
    });
  });

  group('SipProvider', () {
    test('Computes total monthly commitment and logs installment as expense', () async {
      final sampleSips = [
        Sip(
          id: 'sip_1',
          name: 'NIBL Fund',
          monthlyAmountCents: 300000,
          dayOfMonth: 10,
          startDate: DateTime(2026, 1, 1),
          active: true,
        ),
        Sip(
          id: 'sip_2',
          name: 'NIC Asia Fund',
          monthlyAmountCents: 200000,
          dayOfMonth: 20,
          startDate: DateTime(2026, 1, 1),
          active: false, // Paused
        ),
      ];

      final provider = SipProvider('', initialSips: sampleSips);
      expect(provider.sips.length, 2);
      expect(provider.activeSips.length, 1);
      // Only active SIPs count towards monthly commitment
      expect(provider.totalMonthlyCommitmentCents, 300000);

      // Test logging installment into ExpenseProvider
      final sampleExpenses = <Expense>[];
      final expProvider = ExpenseProvider('', initialExpenses: sampleExpenses);

      await provider.logInstallmentAsExpense(sampleSips.first, expProvider);
      expect(expProvider.monthlyTransactions.length, 1);
      final logged = expProvider.monthlyTransactions.first;
      expect(logged.title, contains('NIBL Fund'));
      expect(logged.amountCents, 300000);
      expect(logged.category, 'Other');
    });
  });
}
