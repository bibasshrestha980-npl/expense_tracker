import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:expense_tracker/providers/auth_provider.dart';
import 'package:expense_tracker/screens/vault_gate.dart';
import 'package:expense_tracker/services/vault_cipher.dart';
import 'package:expense_tracker/theme.dart';

class VaultTestAuth extends ChangeNotifier implements AuthProvider {
  @override
  get user => null;
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  testWidgets('new account opens dashboard without a recovery key', (
    tester,
  ) async {
    final db = FakeFirebaseFirestore();
    final auth = VaultTestAuth();
    await tester.pumpWidget(
      ChangeNotifierProvider<AuthProvider>.value(
        value: auth,
        child: MaterialApp(
          theme: pocketTheme(),
          home: VaultGate(uid: 'alice', firestore: db),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Original recovery key'), findsNothing);
    expect(find.text('Overview'), findsWidgets);
    expect((await db.doc('users/alice/vault/config').get()).exists, isFalse);
    await tester.pumpWidget(const SizedBox());
    auth.dispose();
  });
  testWidgets(
    'existing ciphertext requires one-time conversion and is preserved on wrong key',
    (tester) async {
      final db = FakeFirebaseFirestore();
      final auth = VaultTestAuth();
      final key = await VaultCipher.generateKey();
      final cipher = VaultCipher.fromRecoveryKey(key);
      final encrypted = await cipher.seal({
        'title': 'Private',
        'category': 'Food',
        'amountCents': 100,
        'date': '2026-10-17T00:00:00.000',
        'note': '',
        'type': 'expense',
      }, 'alice/expenses/one');
      await db.doc('users/alice/expenses/one').set(encrypted);
      await db
          .doc('users/alice/vault/config')
          .set(
            await cipher.seal({'check': 'pocket-vault'}, 'alice/vault/config'),
          );
      await tester.pumpWidget(
        ChangeNotifierProvider<AuthProvider>.value(
          value: auth,
          child: MaterialApp(
            theme: pocketTheme(),
            home: VaultGate(uid: 'alice', firestore: db),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'wrong');
      await tester.ensureVisible(
        find.text('Convert and remove key requirement'),
      );
      await tester.tap(find.text('Convert and remove key requirement'));
      await tester.pumpAndSettle();
      expect(
        (await db.doc('users/alice/expenses/one').get()).data(),
        encrypted,
      );
      await tester.enterText(find.byType(TextField), key);
      await tester.ensureVisible(
        find.text('Convert and remove key requirement'),
      );
      await tester.tap(find.text('Convert and remove key requirement'));
      await tester.pumpAndSettle();
      expect(
        (await db.doc('users/alice/expenses/one').get()).data()!['title'],
        'Private',
      );
      expect((await db.doc('users/alice/vault/config').get()).exists, isFalse);
      expect(find.text('Original recovery key'), findsNothing);
      await tester.pumpWidget(const SizedBox());
      auth.dispose();
    },
  );
}
