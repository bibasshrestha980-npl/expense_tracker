import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/gestures.dart' show PointerDeviceKind;
import 'package:flutter/material.dart';

import 'l10n/generated/app_localizations.dart';

import 'package:provider/provider.dart';

import 'firebase_options.dart';
import 'services/app_integrity.dart';
import 'providers/auth_provider.dart';
import 'providers/locale_provider.dart';
import 'providers/theme_provider.dart';
import 'screens/auth_screen.dart';
import 'screens/vault_gate.dart';
import 'screens/verify_email_screen.dart';
import 'theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  String? setupError;
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    await activateAppIntegrity();
    // Financial records stay in memory instead of an unlimited persistent cache.
    FirebaseFirestore.instance.settings = const Settings(
      persistenceEnabled: false,
    );
  } catch (_) {
    setupError = 'Firebase could not start. Check your connection and follow README.md to configure Firebase, then restart.';
  }
  final themeProvider = ThemeProvider();
  await themeProvider.load();
  final localeProvider = LocaleProvider();
  await localeProvider.load();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: themeProvider),
        ChangeNotifierProvider.value(value: localeProvider),
      ],
      child: ExpenseApp(setupError: setupError),
    ),
  );
}

class PocketScrollBehavior extends MaterialScrollBehavior {
  const PocketScrollBehavior();

  @override
  Set<PointerDeviceKind> get dragDevices => {
    PointerDeviceKind.touch,
    PointerDeviceKind.mouse,
    PointerDeviceKind.trackpad,
    PointerDeviceKind.stylus,
  };
}

class ExpenseApp extends StatelessWidget {
  final String? setupError;
  const ExpenseApp({super.key, this.setupError});

  @override
  Widget build(BuildContext context) => setupError != null
      ? MaterialApp(
          title: 'Pocket • Expense Tracker',
          debugShowCheckedModeBanner: false,
          scrollBehavior: const PocketScrollBehavior(),
          theme: pocketTheme(),
          darkTheme: pocketTheme(brightness: Brightness.dark),
          themeMode: context.watch<ThemeProvider?>()?.mode ?? ThemeMode.system,
          locale: context.watch<LocaleProvider?>()?.locale,
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
            scrollBehavior: const PocketScrollBehavior(),
            theme: pocketTheme(),
            darkTheme: pocketTheme(brightness: Brightness.dark),
            themeMode:
                context.watch<ThemeProvider?>()?.mode ?? ThemeMode.system,
            locale: context.watch<LocaleProvider?>()?.locale,
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
    if (auth.requiresEmailVerification) return const VerifyEmailScreen();

    return VaultGate(key: ValueKey(auth.user!.uid), uid: auth.user!.uid);
  }
}
