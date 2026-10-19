import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart'
    show
        AuthCredential,
        EmailAuthProvider,
        FirebaseAuthException,
        GoogleAuthProvider,
        User;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

import '../l10n/generated/app_localizations.dart';

import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../providers/expense_provider.dart';
import '../providers/locale_provider.dart';
import '../providers/theme_provider.dart';
import '../services/repositories/contribution_repository.dart';
import '../theme.dart';

class SettingsScreen extends StatefulWidget {
  final ExpenseProvider expenseProvider;
  final ContributionRepository? contributionRepository;

  const SettingsScreen({
    super.key,
    required this.expenseProvider,
    this.contributionRepository,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  Timer? _countdownTimer;
  int _remainingSeconds = 60;
  bool _countdownActive = false;
  bool _isDeleting = false;
  bool _isDeletingAccount = false;
  int _appearanceRevision = 0;
  int _localeRevision = 0;

  AppLocalizations? get _l10n => AppLocalizations.of(context);

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  void _startCountdown() {
    setState(() {
      _countdownActive = true;
      _remainingSeconds = 60;
    });

    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_remainingSeconds <= 1) {
        timer.cancel();
        _performDelete();
      } else {
        setState(() {
          _remainingSeconds--;
        });
      }
    });
  }

  void _cancelCountdown() {
    _countdownTimer?.cancel();
    setState(() {
      _countdownActive = false;
      _remainingSeconds = 60;
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _l10n?.dataDeletionCancelled ??
                'Data deletion cancelled. Your data is safe.',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _performDelete() async {
    _countdownTimer?.cancel();
    setState(() {
      _isDeleting = true;
      _countdownActive = false;
    });

    try {
      await widget.expenseProvider.deleteAllData();
      await widget.contributionRepository?.deleteAllContributions();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _l10n?.allRecordsDeleted ??
                  'All your records have been permanently deleted.',
            ),
            backgroundColor: const Color(0xffb91c1c),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _l10n?.failedToDeleteData ??
                  'Failed to delete data. Please check your connection.',
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isDeleting = false;
          _remainingSeconds = 60;
        });
      }
    }
  }

  Future<void> _confirmAndDeleteAccount() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: context.palette.error),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                _l10n?.deleteAccountPermanentlyTitle ??
                    'Delete Account Permanently?',
              ),
            ),
          ],
        ),
        content: Text(
          _l10n?.deleteAccountPermanentlyContent ?? 'This will permanently delete your Pocket account, all expense and income records from Cloud Firestore.\n\nThis action cannot be undone. Are you sure you want to proceed?',
          style: const TextStyle(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(false),
            child: Text(_l10n?.cancel ?? 'Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xffdc2626),
            ),
            onPressed: () => Navigator.of(dialogCtx).pop(true),
            child: Text(_l10n?.deleteAccount ?? 'Delete Account'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() {
      _isDeletingAccount = true;
    });

    try {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      await auth.deleteAccount(onReauthenticate: _promptReauthentication);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _l10n?.accountDeletedSuccess ?? 'Your account and all associated data have been permanently deleted.',
          ),
          backgroundColor: const Color(0xffb91c1c),
          behavior: SnackBarBehavior.floating,
        ),
      );

      // Route user to /login while clearing the navigation stack
      Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
    } on TimeoutException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.message ??
                'Deletion timed out. Check your connection before retrying.',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message ?? 'Failed to delete account. (${e.code})'),
          backgroundColor: const Color(0xffb91c1c),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to delete account: $e'),
          backgroundColor: const Color(0xffb91c1c),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isDeletingAccount = false;
        });
      }
    }
  }

  Future<AuthCredential?> _promptReauthentication(User user) async {
    final isGoogleUser = user.providerData.any(
      (p) => p.providerId == 'google.com',
    );

    if (isGoogleUser) {
      final googleProvider = GoogleAuthProvider();
      if (kIsWeb) {
        final result = await user.reauthenticateWithPopup(googleProvider);
        return result.credential;
      } else {
        final result = await user.reauthenticateWithProvider(googleProvider);
        return result.credential;
      }
    }

    if (!mounted) {
      throw FirebaseAuthException(
        code: 'requires-recent-login',
        message: 'Re-authentication was cancelled.',
      );
    }

    final cred = await showDialog<AuthCredential>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        final passwordController = TextEditingController();
        bool obscure = true;
        String? errorMessage;

        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: Row(
                children: [
                  Icon(Icons.lock_clock_outlined, color: context.palette.error),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _l10n?.confirmPasswordTitle ?? 'Confirm Password',
                    ),
                  ),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _l10n?.confirmPasswordSecurityPrompt ?? 'For security, please enter your password to confirm account deletion.',
                    style: TextStyle(fontSize: 13, color: context.appMuted),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: passwordController,
                    obscureText: obscure,
                    autofocus: true,
                    decoration: InputDecoration(
                      labelText: _l10n?.password ?? 'Password',
                      errorText: errorMessage,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      suffixIcon: IconButton(
                        icon: Icon(
                          obscure ? Icons.visibility_off : Icons.visibility,
                          size: 20,
                        ),
                        onPressed: () {
                          setDialogState(() => obscure = !obscure);
                        },
                      ),
                    ),
                    onSubmitted: (_) {
                      final pass = passwordController.text;
                      if (pass.isEmpty) {
                        setDialogState(
                          () => errorMessage =
                              _l10n?.passwordIsRequired ??
                              'Password is required',
                        );
                        return;
                      }
                      if (user.email == null) {
                        setDialogState(
                          () => errorMessage =
                              _l10n?.noEmailAssociated ??
                              'No email associated with account',
                        );
                        return;
                      }
                      Navigator.of(dialogContext).pop(
                        EmailAuthProvider.credential(
                          email: user.email!,
                          password: pass,
                        ),
                      );
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(null),
                  child: Text(_l10n?.cancel ?? 'Cancel'),
                ),
                FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xffdc2626),
                  ),
                  onPressed: () {
                    final pass = passwordController.text;
                    if (pass.isEmpty) {
                      setDialogState(
                        () => errorMessage =
                            _l10n?.passwordIsRequired ?? 'Password is required',
                      );
                      return;
                    }
                    if (user.email == null) {
                      setDialogState(
                        () => errorMessage =
                            _l10n?.noEmailAssociated ??
                            'No email associated with account',
                      );
                      return;
                    }
                    Navigator.of(dialogContext).pop(
                      EmailAuthProvider.credential(
                        email: user.email!,
                        password: pass,
                      ),
                    );
                  },
                  child: Text(_l10n?.confirm ?? 'Confirm'),
                ),
              ],
            );
          },
        );
      },
    );

    if (cred == null) {
      throw FirebaseAuthException(
        code: 'requires-recent-login',
        message: 'Re-authentication was cancelled.',
      );
    }
    return cred;
  }

  String get _timerFormatted {
    final mins = (_remainingSeconds ~/ 60).toString().padLeft(2, '0');
    final secs = (_remainingSeconds % 60).toString().padLeft(2, '0');
    return '$mins:$secs';
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final p = widget.expenseProvider;
    final l10n = _l10n;
    final appearance = context.watch<ThemeProvider?>();
    final localeProvider = context.watch<LocaleProvider?>();
    final userEmail =
        auth.user?.email ??
        (auth.user?.isAnonymous == true
            ? (l10n?.guestSession ?? 'Guest Session')
            : (l10n?.offlinePersonal ?? 'Offline / Personal'));

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 800),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Account Section
            _buildCard(
              title: l10n?.accountAndSecurity ?? 'Account & Security',
              icon: Icons.shield_outlined,
              child: Column(
                children: [
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: CircleAvatar(
                      backgroundColor: context.palette.primaryContainer,
                      child: Icon(
                        Icons.person_outline,
                        color: context.appAccent,
                      ),
                    ),
                    title: Text(
                      userEmail,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text(
                      auth.user == null
                          ? (l10n?.offlinePersonal ?? 'Offline / Personal')
                          : auth.user?.isAnonymous == true
                          ? (l10n?.anonymousGuestAccount ??
                                'Anonymous guest account')
                          : (l10n?.authenticatedUser ?? 'Signed-in account'),
                      style: TextStyle(color: context.appMuted, fontSize: 13),
                    ),
                    trailing: OutlinedButton.icon(
                      onPressed:
                          (_isDeleting ||
                              _isDeletingAccount ||
                              _countdownActive)
                          ? null
                          : () => auth.signOut(),
                      icon: const Icon(Icons.logout, size: 16),
                      label: Text(l10n?.signOut ?? 'Sign out'),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Preferences Section
            _buildCard(
              title: l10n?.preferences ?? 'Preferences',
              icon: Icons.tune_rounded,
              child: Column(
                children: [
                  if (appearance != null) ...[
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.brightness_6_outlined),
                      title: Text(l10n?.appearance ?? 'Appearance'),
                    ),
                    SizedBox(
                      width: double.infinity,
                      child: DropdownButtonFormField<ThemeMode>(
                        key: ValueKey((appearance.mode, _appearanceRevision)),
                        initialValue: appearance.mode,
                        decoration: InputDecoration(
                          labelText: l10n?.appearance ?? 'Appearance',
                        ),
                        items: [
                          DropdownMenuItem(
                            value: ThemeMode.system,
                            child: Text(l10n?.themeSystem ?? 'Follow system'),
                          ),
                          DropdownMenuItem(
                            value: ThemeMode.light,
                            child: Text(l10n?.themeLight ?? 'Light'),
                          ),
                          DropdownMenuItem(
                            value: ThemeMode.dark,
                            child: Text(l10n?.themeDark ?? 'Dark'),
                          ),
                        ],
                        onChanged: (mode) async {
                          if (mode == null) return;
                          try {
                            await appearance.setMode(mode);
                          } catch (_) {
                            if (!context.mounted) return;
                            setState(() => _appearanceRevision++);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  l10n?.themeSaveFailed ?? 'Could not save appearance. Please try again.',
                                ),
                              ),
                            );
                          }
                        },
                      ),
                    ),
                    const Divider(height: 24),
                  ],
                  if (localeProvider != null) ...[
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.language_rounded),
                      title: Text(l10n?.language ?? 'Language'),
                    ),
                    SizedBox(
                      width: double.infinity,
                      child: DropdownButtonFormField<String>(
                        key: ValueKey((
                          localeProvider.languageCode,
                          _localeRevision,
                        )),
                        initialValue: localeProvider.languageCode,
                        decoration: InputDecoration(
                          labelText: l10n?.language ?? 'Language',
                        ),
                        items: [
                          DropdownMenuItem(
                            value: 'system',
                            child: Text(
                              l10n?.languageSystem ?? 'Follow system',
                            ),
                          ),
                          DropdownMenuItem(
                            value: 'en',
                            child: Text(l10n?.languageEnglish ?? 'English'),
                          ),
                          DropdownMenuItem(
                            value: 'ne',
                            child: Text(
                              l10n?.languageNepali ?? 'नेपाली (Nepali)',
                            ),
                          ),
                        ],
                        onChanged: (code) async {
                          if (code == null) return;
                          try {
                            await localeProvider.setLanguageCode(code);
                          } catch (_) {
                            if (!context.mounted) return;
                            setState(() => _localeRevision++);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  l10n?.languageSaveFailed ?? 'Could not save language preference. Please try again.',
                                ),
                              ),
                            );
                          }
                        },
                      ),
                    ),
                    const Divider(height: 24),
                  ],
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      l10n?.nepaliCalendarTitle ??
                          'Nepali Bikram Sambat (BS) Calendar',
                    ),
                    subtitle: Text(
                      p.nepali
                          ? (l10n?.nepaliCalendarActive ??
                                'Active: Showing Nepali dates and tithi')
                          : (l10n?.nepaliCalendarInactive ??
                                'Inactive: Showing Gregorian (AD) calendar'),
                      style: TextStyle(color: context.appMuted, fontSize: 13),
                    ),
                    value: p.nepali,
                    onChanged: (val) => p.setCalendar(val),
                  ),
                  const Divider(height: 24),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(l10n?.baseCurrency ?? 'Base Currency'),
                    subtitle: Text(
                      l10n?.baseCurrencySubtitle ??
                          'NPR — Nepalese Rupee (paisa-exact precision)',
                      style: TextStyle(color: context.appMuted, fontSize: 13),
                    ),
                    trailing: Chip(
                      label: const Text(
                        'NPR',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      backgroundColor: context.appPanel,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Data Overview Section
            _buildCard(
              title: l10n?.dataAndStorage ?? 'Data & Storage',
              icon: Icons.folder_outlined,
              child: ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  l10n?.recordedTransactions ?? 'Recorded Transactions',
                ),
                subtitle: Text(
                  l10n?.recordedTransactionsSubtitle(
                        p.monthlyTransactions.length,
                        p.income > 0
                            ? (l10n.incomeAndExpensesRecorded)
                            : (l10n.expensesRecorded),
                      ) ??
                      '${p.monthlyTransactions.length} in this period • ${p.income > 0 ? "Income & expenses recorded" : "Expenses recorded"}',
                  style: TextStyle(color: context.appMuted, fontSize: 13),
                ),
                trailing: Icon(
                  Icons.cloud_done_outlined,
                  color: context.appAccent,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Danger Zone: Delete My Data with 1-Minute Countdown
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(
                  color: _countdownActive
                      ? const Color(0xffef4444)
                      : context.palette.errorContainer,
                  width: _countdownActive ? 2 : 1,
                ),
              ),
              color: Color.alphaBlend(
                context.palette.error.withValues(
                  alpha: _countdownActive ? 0.12 : 0.06,
                ),
                context.appSurface,
              ),
              child: Padding(
                padding: const EdgeInsets.all(22),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          _countdownActive
                              ? Icons.warning_rounded
                              : Icons.delete_forever_outlined,
                          color: context.palette.error,
                          size: 24,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            l10n?.dangerZone ?? 'Danger Zone',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                              color: context.palette.onErrorContainer,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    if (_isDeleting) ...[
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 24),
                          child: Column(
                            children: [
                              CircularProgressIndicator(
                                color: context.palette.error,
                              ),
                              const SizedBox(height: 14),
                              Text(
                                l10n?.deletingAllDataPermanently ??
                                    'Deleting all data permanently...',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ] else if (_countdownActive) ...[
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: context.appSurface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: context.palette.outlineVariant,
                          ),
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.timer_outlined,
                                  color: context.palette.error,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  l10n?.dataWillBeDeletedIn1Min ??
                                      'Your data will be deleted in 1 minute',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: context.palette.onErrorContainer,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              _timerFormatted,
                              style: TextStyle(
                                fontSize: 44,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 4,
                                color: context.palette.error,
                              ),
                            ),
                            const SizedBox(height: 8),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: _remainingSeconds / 60.0,
                                minHeight: 8,
                                color: context.palette.error,
                                backgroundColor: context.palette.errorContainer,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              l10n?.secondsRemaining(_remainingSeconds) ??
                                  '$_remainingSeconds seconds remaining before automatic permanent deletion.',
                              style: TextStyle(
                                color: context.appMuted,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 12,
                        runSpacing: 10,
                        alignment: WrapAlignment.spaceBetween,
                        children: [
                          FilledButton.icon(
                            onPressed: _isDeletingAccount
                                ? null
                                : _cancelCountdown,
                            icon: const Icon(Icons.close_rounded, size: 18),
                            label: Text(
                              l10n?.cancelDeletion ?? 'Cancel Deletion',
                            ),
                            style: FilledButton.styleFrom(
                              backgroundColor: context.appAccent,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 18,
                                vertical: 12,
                              ),
                            ),
                          ),
                          OutlinedButton.icon(
                            onPressed: _isDeletingAccount
                                ? null
                                : _performDelete,
                            icon: const Icon(Icons.delete_forever, size: 18),
                            label: Text(
                              l10n?.deleteImmediately ?? 'Delete Immediately',
                            ),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xffdc2626),
                              side: BorderSide(color: context.palette.error),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 18,
                                vertical: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ] else ...[
                      Text(
                        l10n?.deleteMyDataDesc ?? 'Permanently erase all your expense and income records from Cloud Firestore. Once deleted, your financial history cannot be recovered.',
                        style: TextStyle(color: context.appMuted, fontSize: 13),
                      ),
                      const SizedBox(height: 16),
                      FilledButton.tonalIcon(
                        onPressed: _isDeletingAccount ? null : _startCountdown,
                        icon: const Icon(Icons.delete_outline, size: 18),
                        label: Text(l10n?.deleteMyData ?? 'Delete My Data'),
                        style: FilledButton.styleFrom(
                          foregroundColor: const Color(0xffb91c1c),
                          backgroundColor: context.palette.errorContainer,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 12,
                          ),
                        ),
                      ),
                    ],

                    Divider(height: 36, color: context.palette.outlineVariant),
                    Text(
                      l10n?.deleteAccount ?? 'Delete Account',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: context.palette.onErrorContainer,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      l10n?.deleteAccountDesc ?? 'Permanently delete your account credentials from Firebase Authentication, all documents in Cloud Firestore (users/{uid}), and any uploaded media in Firebase Storage. This action cannot be undone.',
                      style: TextStyle(color: context.appMuted, fontSize: 13),
                    ),
                    const SizedBox(height: 14),
                    if (_isDeletingAccount)
                      Row(
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: context.palette.error,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            l10n?.deletingAccountAndDataProgress ??
                                'Permanently deleting account and all data...',
                            style: TextStyle(
                              color: context.palette.onErrorContainer,
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      )
                    else
                      FilledButton.icon(
                        onPressed: (_isDeleting || _countdownActive)
                            ? null
                            : _confirmAndDeleteAccount,
                        icon: const Icon(
                          Icons.person_remove_outlined,
                          size: 18,
                        ),
                        label: Text(l10n?.deleteAccount ?? 'Delete Account'),
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xffb91c1c),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 12,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildCard({
    required String title,
    required IconData icon,
    required Widget child,
  }) => Card(
    elevation: 0,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
      side: BorderSide(color: context.palette.outlineVariant),
    ),
    child: Padding(
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: context.appAccent, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    ),
  );
}
