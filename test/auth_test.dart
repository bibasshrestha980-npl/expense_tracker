import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:expense_tracker/providers/auth_provider.dart';
import 'package:expense_tracker/screens/verify_email_screen.dart';

class VerificationUser extends Fake implements User {
  bool verified = false;
  bool anonymous = false;
  bool verifyOnReload = false;
  int sent = 0;
  int refreshes = 0;
  @override
  String get uid => 'user-1';
  @override
  String get email => 'person@gmail.com';
  @override
  bool get emailVerified => verified;
  @override
  bool get isAnonymous => anonymous;
  @override
  Future<void> sendEmailVerification([ActionCodeSettings? settings]) async {
    sent++;
  }

  @override
  Future<void> reload() async {
    if (verifyOnReload) verified = true;
  }

  @override
  Future<String?> getIdToken([bool forceRefresh = false]) async {
    if (forceRefresh) refreshes++;
    return 'test-token';
  }
}

class VerificationAuth extends Fake implements FirebaseAuth {
  VerificationAuth(this.current);
  User? current;
  @override
  User? get currentUser => current;
  @override
  Stream<User?> authStateChanges() => Stream.value(current);
}

class ScreenAuth extends ChangeNotifier implements AuthProvider {
  @override
  final user = VerificationUser();
  int sent = 0;
  bool verified = false;
  bool fail = false;
  @override
  Future<void> sendVerificationEmail() async {
    if (fail) throw FirebaseAuthException(code: 'network-request-failed');
    sent++;
  }

  @override
  Future<bool> checkEmailLinkVerified() async => verified;
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  test('Only unverified non-guest users require email verification', () async {
    final user = VerificationUser();
    final firebase = VerificationAuth(user);
    final auth = AuthProvider(auth: firebase);
    addTearDown(auth.dispose);
    await Future<void>.delayed(Duration.zero);
    expect(auth.requiresEmailVerification, isTrue);
    await auth.sendVerificationEmail();
    expect(user.sent, 1);
    expect(await auth.checkEmailLinkVerified(), isFalse);
    user.verifyOnReload = true;
    expect(await auth.checkEmailLinkVerified(), isTrue);
    expect(user.refreshes, 1);
    expect(auth.requiresEmailVerification, isFalse);
    await auth.sendVerificationEmail();
    expect(user.sent, 1);
    user.verified = false;
    user.anonymous = true;
    expect(auth.requiresEmailVerification, isFalse);
    await auth.sendVerificationEmail();
    expect(user.sent, 1);
    firebase.current = null;
    expect(await auth.checkEmailLinkVerified(), isFalse);
  });

  testWidgets(
    'Email screen sends link, hides codes, checks verification and limits resend',
    (tester) async {
      final auth = ScreenAuth();
      addTearDown(auth.dispose);
      await tester.pumpWidget(
        ChangeNotifierProvider<AuthProvider>.value(
          value: auth,
          child: const MaterialApp(home: VerifyEmailScreen()),
        ),
      );
      await tester.pumpAndSettle();
      expect(auth.sent, 1);
      expect(
        find.text('Verification email sent to person@gmail.com.'),
        findsOneWidget,
      );
      expect(find.byType(TextFormField), findsNothing);
      expect(find.text('Your Verification Code'), findsNothing);
      expect(
        tester.widget<OutlinedButton>(find.byType(OutlinedButton)).onPressed,
        isNull,
      );
      await tester.tap(find.text("I've verified my email"));
      await tester.pumpAndSettle();
      expect(find.textContaining('Email not verified yet.'), findsOneWidget);
      auth.verified = true;
      await tester.tap(find.text("I've verified my email"));
      await tester.pumpAndSettle();
      expect(find.textContaining('Email not verified yet.'), findsNothing);
      await tester.pump(const Duration(seconds: 60));
      await tester.tap(find.text('Resend verification email'));
      await tester.pumpAndSettle();
      expect(auth.sent, 2);
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets('Failed email send shows error and permits retry', (
    tester,
  ) async {
    final auth = ScreenAuth()..fail = true;
    addTearDown(auth.dispose);
    await tester.pumpWidget(
      ChangeNotifierProvider<AuthProvider>.value(
        value: auth,
        child: const MaterialApp(home: VerifyEmailScreen()),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('Could not connect.'), findsOneWidget);
    expect(find.textContaining('Verification email sent'), findsNothing);
    auth.fail = false;
    await tester.tap(find.text('Send verification email'));
    await tester.pumpAndSettle();
    expect(auth.sent, 1);
    expect(find.textContaining('Verification email sent'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });
}
