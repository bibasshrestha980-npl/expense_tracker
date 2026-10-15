import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:expense_tracker/providers/auth_provider.dart';
import 'package:expense_tracker/screens/verify_code_screen.dart';
import 'package:expense_tracker/theme.dart';

class MockAuthProvider extends ChangeNotifier implements AuthProvider {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  @override
  bool isCodeVerified = false;

  @override
  String? currentVerificationCode = '123456';

  @override
  get user => null;

  @override
  bool verifyCode(String inputCode) {
    if (inputCode.trim() == currentVerificationCode) {
      isCodeVerified = true;
      notifyListeners();
      return true;
    }
    return false;
  }
}

void main() {
  testWidgets(
    'VerifyCodeScreen displays verification code and handles input validation',
    (tester) async {
      final mockAuth = MockAuthProvider();

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<AuthProvider>.value(value: mockAuth),
          ],
          child: MaterialApp(
            theme: pocketTheme(),
            home: const VerifyCodeScreen(),
          ),
        ),
      );

      expect(find.text('Two-Step Verification'), findsOneWidget);
      expect(find.text('Your Verification Code'), findsOneWidget);
      expect(find.text('123456'), findsOneWidget);

      // Tap code banner to auto-fill
      await tester.tap(find.text('123456'));
      await tester.pumpAndSettle();

      // Verify & Continue
      await tester.tap(find.text('Verify & Continue'));
      await tester.pumpAndSettle();

      expect(mockAuth.isCodeVerified, isTrue);
    },
  );
}
