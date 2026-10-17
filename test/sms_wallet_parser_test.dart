import 'package:flutter_test/flutter_test.dart';
import 'package:expense_tracker/services/sms_wallet_parser.dart';

void main() {
  group('SmsWalletParser Tests', () {
    test('Parses plain user input: income 60000', () {
      final parsed = SmsWalletParser.parse('income 60000');
      expect(parsed, isNotNull);
      expect(parsed!.amount, 60000.0);
      expect(parsed.amountCents, 6000000);
      expect(parsed.isIncome, isTrue);
      expect(parsed.category, 'Other income');
      expect(parsed.title, 'Income');
    });

    test('Parses plain user input: salary 50000', () {
      final parsed = SmsWalletParser.parse('salary 50000');
      expect(parsed, isNotNull);
      expect(parsed!.amount, 50000.0);
      expect(parsed.isIncome, isTrue);
      expect(parsed.category, 'Salary');
      expect(parsed.title, 'Monthly Salary');
    });

    test('Parses plain user input: freelance 25000', () {
      final parsed = SmsWalletParser.parse('freelance 25000');
      expect(parsed, isNotNull);
      expect(parsed!.amount, 25000.0);
      expect(parsed.isIncome, isTrue);
      expect(parsed.category, 'Freelance');
      expect(parsed.title, 'Freelance Payment');
    });

    test('Parses plain number with defaultIsIncome = true', () {
      final parsed = SmsWalletParser.parse('60000', defaultIsIncome: true);
      expect(parsed, isNotNull);
      expect(parsed!.amount, 60000.0);
      expect(parsed.isIncome, isTrue);
    });

    test('Parses plain expense: food 500', () {
      final parsed = SmsWalletParser.parse('food 500');
      expect(parsed, isNotNull);
      expect(parsed!.amount, 500.0);
      expect(parsed.isIncome, isFalse);
      expect(parsed.category, 'Food');
    });

    test('Parses eSewa restaurant payment correctly', () {
      const sms = 'Paid Rs. 450 to Himalayan Java via eSewa. Txn ID: ESW10928374.';
      final parsed = SmsWalletParser.parse(sms);

      expect(parsed, isNotNull);
      expect(parsed!.amount, 450.0);
      expect(parsed.amountCents, 45000);
      expect(parsed.isIncome, isFalse);
      expect(parsed.category, 'Food');
      expect(parsed.merchant, 'Himalayan Java Coffee');
      expect(parsed.referenceId, 'ESW10928374');
    });

    test('Parses supermarket grocery alert from Bhatbhateni', () {
      const sms = 'Payment of NPR 2,500.00 for Bhatbhateni Supermarket via Fonepay successful. Ref: FNP987654';
      final parsed = SmsWalletParser.parse(sms);

      expect(parsed, isNotNull);
      expect(parsed!.amount, 2500.0);
      expect(parsed.amountCents, 250000);
      expect(parsed.isIncome, isFalse);
      expect(parsed.category, 'Groceries');
      expect(parsed.merchant, 'Bhatbhateni Supermarket');
      expect(parsed.referenceId, 'FNP987654');
    });

    test('Parses bank salary deposit (Income)', () {
      const sms = 'A/C *1234 credited with Rs. 55,000.00 on 01-Oct-2026 by SALARY from TECH LTD. Avl Bal: Rs. 60,000.00';
      final parsed = SmsWalletParser.parse(sms);

      expect(parsed, isNotNull);
      expect(parsed!.amount, 55000.0);
      expect(parsed.amountCents, 5500000);
      expect(parsed.isIncome, isTrue);
      expect(parsed.category, 'Salary');
      expect(parsed.title, 'Monthly Salary');
    });

    test('Parses Worldlink internet utility payment via Khalti', () {
      const sms = 'Khalti: Payment of Rs. 1400 paid for Worldlink bill successfully. TxnID: KHL776655.';
      final parsed = SmsWalletParser.parse(sms);

      expect(parsed, isNotNull);
      expect(parsed!.amount, 1400.0);
      expect(parsed.isIncome, isFalse);
      expect(parsed.category, 'Utilities');
      expect(parsed.merchant, 'Worldlink Communications');
      expect(parsed.referenceId, 'KHL776655');
    });

    test('Parses ride sharing transport via Pathao', () {
      const sms = 'Paid Rs. 210 to Pathao for your recent ride.';
      final parsed = SmsWalletParser.parse(sms);

      expect(parsed, isNotNull);
      expect(parsed!.amount, 210.0);
      expect(parsed.isIncome, isFalse);
      expect(parsed.category, 'Transport');
      expect(parsed.merchant, 'Pathao');
    });

    test('Parses Nepali Devanagari numerals and currency format', () {
      const sms = 'तपाईंको खाताबाट रु. १,२५० काटिएको छ।';
      final parsed = SmsWalletParser.parse(sms);

      expect(parsed, isNotNull);
      expect(parsed!.amount, 1250.0);
      expect(parsed.amountCents, 125000);
      expect(parsed.isIncome, isFalse);
    });

    test('Returns null on non-financial strings', () {
      expect(SmsWalletParser.parse('Hello, how are you doing today?'), isNull);
      expect(SmsWalletParser.parse('Your OTP code is 987654. Do not share it.'), isNull);
      expect(SmsWalletParser.parse(''), isNull);
    });
  });
}
