import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'l10n/generated/app_localizations.dart';

import 'package:provider/provider.dart';

import 'firebase_options.dart';
import 'providers/auth_provider.dart';
import 'providers/expense_provider.dart';
import 'screens/auth_screen.dart';
import 'screens/dashboard.dart';
import 'screens/verify_code_screen.dart';
import 'theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  String? setupError;
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    // Explicitly configure Firestore offline persistence and cache size
    FirebaseFirestore.instance.settings = const Settings(
      persistenceEnabled: true,
      cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
    );
  } catch (_) {
    setupError = 'Firebase could not start. Check your connection and follow README.md to configure Firebase, then restart.';
  }
  runApp(ExpenseApp(setupError: setupError));
}

class ExpenseApp extends StatelessWidget {
  final String? setupError;
  const ExpenseApp({super.key, this.setupError});

  @override
  Widget build(BuildContext context) => setupError != null
      ? MaterialApp(
          title: 'Pocket • Expense Tracker',
          debugShowCheckedModeBanner: false,
          theme: pocketTheme(),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.account_balance_wallet_outlined, size: 64),
                    const SizedBox(height: 20),
                    const Text(
                      'Welcome to Pocket',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(setupError!, textAlign: TextAlign.center),
                  ],
                ),
              ),
            ),
          ),
        )
      : ChangeNotifierProvider(
          create: (_) => AuthProvider(),
          child: MaterialApp(
            title: 'Pocket • Expense Tracker',
            debugShowCheckedModeBanner: false,
            theme: pocketTheme(),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            routes: {'/login': (_) => const AuthGate()},
            home: const AuthGate(),
          ),
        );
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});
  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    if (auth.loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (auth.user == null) return const AuthScreen();
    if (!auth.isCodeVerified) return const VerifyCodeScreen();

    return ChangeNotifierProvider(
      key: ValueKey(auth.user!.uid),
      create: (_) => ExpenseProvider(auth.user!.uid),
      child: const Dashboard(),
    );
  }
}
