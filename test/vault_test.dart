import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:expense_tracker/services/vault_cipher.dart';
import 'package:expense_tracker/services/repositories/vault_repository.dart';
import 'package:expense_tracker/models/expense.dart';

void main() {
  test('random keys, unique nonces, roundtrip and context binding', () async {
    final key = await VaultCipher.generateKey();
    expect(base64Url.decode(key).length, 32);
    expect(await VaultCipher.generateKey(), isNot(key));
    final cipher = VaultCipher.fromRecoveryKey(key);
    final a = await cipher.seal({
      'title': 'Private lunch',
    }, 'alice/expenses/one');
    final b = await cipher.seal({
      'title': 'Private lunch',
    }, 'alice/expenses/one');
    expect(a['nonce'], isNot(b['nonce']));
    expect(jsonEncode(a), isNot(contains('Private lunch')));
    expect(await cipher.open(a, 'alice/expenses/one'), {
      'title': 'Private lunch',
    });
    await expectLater(cipher.open(a, 'bob/expenses/one'), throwsA(anything));
    await expectLater(cipher.open(a, 'alice/expenses/two'), throwsA(anything));
    final wrong = VaultCipher.fromRecoveryKey(await VaultCipher.generateKey());
    await expectLater(wrong.open(a, 'alice/expenses/one'), throwsA(anything));
    final bytes = base64Decode(a['ciphertext'] as String);
    bytes[0] ^= 1;
    await expectLater(
      cipher.open({
        ...a,
        'ciphertext': base64Encode(bytes),
      }, 'alice/expenses/one'),
      throwsA(anything),
    );
  });
  test(
    'migration encrypts all fields, is repeatable, and preserves totals',
    () async {
      final db = FakeFirebaseFirestore();
      final original = Expense(
        id: 'one',
        title: 'Lunch',
        category: 'Food',
        amountCents: 45000,
        date: DateTime(2026, 10, 17),
        note: 'Private',
      );
      await db.doc('users/alice/expenses/one').set(original.toMap());
      final repo = VaultRepository(
        'alice',
        VaultCipher.fromRecoveryKey(await VaultCipher.generateKey()),
        firestore: db,
      );
      await repo.migrateLegacy();
      await repo.migrateLegacy();
      final stored = (await db.doc('users/alice/expenses/one').get()).data()!;
      expect(stored.keys.toSet(), {'v', 'nonce', 'ciphertext', 'mac'});
      final decoded = (await repo.getExpenses('alice')).single;
      expect(decoded.amountCents, 45000);
      expect(decoded.note, 'Private');
      expect(decoded.date, original.date);
      await repo.saveExpense(
        'alice',
        Expense(
          id: '',
          title: 'Salary',
          category: 'Salary',
          amountCents: 3000000,
          date: DateTime(2026, 10, 17),
          isIncome: true,
        ),
      );
      expect((await repo.watchExpenses('alice').first).length, 2);
      await expectLater(repo.getExpenses('bob'), throwsStateError);
      await repo.deleteExpense('alice', 'one');
      expect((await repo.getExpenses('alice')).length, 1);
    },
  );
  test('malformed recovery keys are rejected', () {
    expect(() => VaultCipher.fromRecoveryKey('password'), throwsA(anything));
  });
}
