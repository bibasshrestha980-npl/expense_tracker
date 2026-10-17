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
  testWidgets(
    'wrong key stays locked; correct key unlocks; background locks vault',
    (tester) async {
      final db = FakeFirebaseFirestore();
      final key = await VaultCipher.generateKey();
      final cipher = VaultCipher.fromRecoveryKey(key);
      await db
          .doc('users/alice/vault/config')
          .set(
            await cipher.seal({'check': 'pocket-vault'}, 'alice/vault/config'),
          );
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
      await tester.enterText(find.byType(TextField), 'wrong-key');
      await tester.tap(find.text('Unlock vault'));
      await tester.pumpAndSettle();
      expect(find.text('Encrypted vault unlocked'), findsNothing);
      await tester.enterText(find.byType(TextField), key);
      await tester.tap(find.text('Unlock vault'));
      await tester.pumpAndSettle();
      expect(find.text('Encrypted vault unlocked'), findsOneWidget);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pumpAndSettle();
      expect(find.text('Encrypted vault unlocked'), findsNothing);
      expect(find.text('Unlock vault'), findsOneWidget);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pumpWidget(const SizedBox());
      auth.dispose();
    },
  );
  testWidgets('new vault requires recovery key confirmation', (tester) async {
    final db = FakeFirebaseFirestore();
    await tester.pumpWidget(
      MaterialApp(
        theme: pocketTheme(),
        home: VaultGate(uid: 'alice', firestore: db),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Save your recovery key'), findsOneWidget);
    await tester.ensureVisible(find.text('Create vault and encrypt records'));
    await tester.tap(find.text('Create vault and encrypt records'));
    await tester.pumpAndSettle();
    expect((await db.doc('users/alice/vault/config').get()).exists, isFalse);
    expect(find.text('Encrypted vault unlocked'), findsNothing);
  });
}
