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
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../providers/expense_provider.dart';
import '../theme.dart';

class SettingsScreen extends StatefulWidget {
  final ExpenseProvider expenseProvider;

  const SettingsScreen({super.key, required this.expenseProvider});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  Timer? _countdownTimer;
  int _remainingSeconds = 60;
  bool _countdownActive = false;
  bool _isDeleting = false;
  bool _isDeletingAccount = false;

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
        const SnackBar(
          content: Text('Data deletion cancelled. Your data is safe.'),
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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('All your records have been permanently deleted.'),
            backgroundColor: Color(0xffb91c1c),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
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
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Color(0xffdc2626)),
            SizedBox(width: 8),
            Expanded(
              child: Text('Delete Account Permanently?'),
            ),
          ],
        ),
        content: const Text(
          'This will permanently delete your Pocket account, all expense and income records from Cloud Firestore, and any associated files from Firebase Storage.\n\nThis action cannot be undone. Are you sure you want to proceed?',
          style: TextStyle(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xffdc2626),
            ),
            onPressed: () => Navigator.of(dialogCtx).pop(true),
            child: const Text('Delete Account'),
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
        const SnackBar(
          content: Text(
            'Your account and all associated data have been permanently deleted.',
          ),
          backgroundColor: Color(0xffb91c1c),
          behavior: SnackBarBehavior.floating,
        ),
      );

      // Route user to /login while clearing the navigation stack
      Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
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
              title: const Row(
                children: [
                  Icon(Icons.lock_clock_outlined, color: Color(0xffdc2626)),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text('Confirm Password'),
                  ),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'For security, please enter your password to confirm account deletion.',
                    style: TextStyle(fontSize: 13, color: muted),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: passwordController,
                    obscureText: obscure,
                    autofocus: true,
                    decoration: InputDecoration(
                      labelText: 'Password',
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
                      final pass = passwordController.text.trim();
                      if (pass.isEmpty) {
                        setDialogState(() => errorMessage = 'Password is required');
                        return;
                      }
                      if (user.email == null) {
                        setDialogState(
                          () => errorMessage = 'No email associated with account',
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
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xffdc2626),
                  ),
                  onPressed: () {
                    final pass = passwordController.text.trim();
                    if (pass.isEmpty) {
                      setDialogState(() => errorMessage = 'Password is required');
                      return;
                    }
                    if (user.email == null) {
                      setDialogState(
                        () => errorMessage = 'No email associated with account',
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
                  child: const Text('Confirm'),
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
    final userEmail =
        auth.user?.email ??
        (auth.user?.isAnonymous == true
            ? 'Guest Session'
            : 'Offline / Personal');

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 800),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Account Section
            _buildCard(
              title: 'Account & Security',
              icon: Icons.shield_outlined,
              child: Column(
                children: [
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const CircleAvatar(
                      backgroundColor: Color(0xffe6f3ed),
                      child: Icon(Icons.person_outline, color: accent),
                    ),
                    title: Text(
                      userEmail,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text(
                      auth.user?.isAnonymous == true
                          ? 'Anonymous guest account'
                          : 'Authenticated user • 2FA enabled',
                      style: const TextStyle(color: muted, fontSize: 13),
                    ),
                    trailing: OutlinedButton.icon(
                      onPressed: (_isDeleting ||
                              _isDeletingAccount ||
                              _countdownActive)
                          ? null
                          : () => auth.signOut(),
                      icon: const Icon(Icons.logout, size: 16),
                      label: const Text('Sign out'),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Preferences Section
            _buildCard(
              title: 'Preferences',
              icon: Icons.tune_rounded,
              child: Column(
                children: [
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Nepali Bikram Sambat (BS) Calendar'),
                    subtitle: Text(
                      p.nepali
                          ? 'Active: Showing Nepali dates and tithi'
                          : 'Inactive: Showing Gregorian (AD) calendar',
                      style: const TextStyle(color: muted, fontSize: 13),
                    ),
                    value: p.nepali,
                    onChanged: (val) => p.setCalendar(val),
                  ),
                  const Divider(height: 24),
                  const ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text('Base Currency'),
                    subtitle: Text(
                      'NPR — Nepalese Rupee (paisa-exact precision)',
                      style: TextStyle(color: muted, fontSize: 13),
                    ),
                    trailing: Chip(
                      label: Text(
                        'NPR',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      backgroundColor: Color(0xfff3f4f6),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Data Overview Section
            _buildCard(
              title: 'Data & Storage',
              icon: Icons.folder_outlined,
              child: ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Recorded Transactions'),
                subtitle: Text(
                  '${p.monthlyTransactions.length} in this period • ${p.income > 0 ? "Income & expenses recorded" : "Expenses recorded"}',
                  style: const TextStyle(color: muted, fontSize: 13),
                ),
                trailing: const Icon(Icons.cloud_done_outlined, color: accent),
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
                      : const Color(0xfffee2e2),
                  width: _countdownActive ? 2 : 1,
                ),
              ),
              color: _countdownActive
                  ? const Color(0xfffff1f2)
                  : const Color(0xfffffbfb),
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
                          color: const Color(0xffdc2626),
                          size: 24,
                        ),
                        const SizedBox(width: 10),
                        const Expanded(
                          child: Text(
                            'Danger Zone',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                              color: Color(0xffb91c1c),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    if (_isDeleting) ...[
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 24),
                          child: Column(
                            children: [
                              CircularProgressIndicator(
                                color: Color(0xffdc2626),
                              ),
                              SizedBox(height: 14),
                              Text(
                                'Deleting all data permanently...',
                                style: TextStyle(fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ] else if (_countdownActive) ...[
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xfffecaca)),
                        ),
                        child: Column(
                          children: [
                            const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.timer_outlined,
                                  color: Color(0xffdc2626),
                                  size: 20,
                                ),
                                SizedBox(width: 8),
                                Text(
                                  'Your data will be deleted in 1 minute',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xffb91c1c),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              _timerFormatted,
                              style: const TextStyle(
                                fontSize: 44,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 4,
                                color: Color(0xffdc2626),
                              ),
                            ),
                            const SizedBox(height: 8),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: _remainingSeconds / 60.0,
                                minHeight: 8,
                                color: const Color(0xffdc2626),
                                backgroundColor: const Color(0xfffee2e2),
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              '$_remainingSeconds seconds remaining before automatic permanent deletion.',
                              style: const TextStyle(
                                color: muted,
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
                            onPressed: _isDeletingAccount ? null : _cancelCountdown,
                            icon: const Icon(Icons.close_rounded, size: 18),
                            label: const Text('Cancel Deletion'),
                            style: FilledButton.styleFrom(
                              backgroundColor: accent,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 18,
                                vertical: 12,
                              ),
                            ),
                          ),
                          OutlinedButton.icon(
                            onPressed: _isDeletingAccount ? null : _performDelete,
                            icon: const Icon(Icons.delete_forever, size: 18),
                            label: const Text('Delete Immediately'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xffdc2626),
                              side: const BorderSide(color: Color(0xffdc2626)),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 18,
                                vertical: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ] else ...[
                      const Text(
                        'Permanently erase all your expense and income records from Cloud Firestore. Once deleted, your financial history cannot be recovered.',
                        style: TextStyle(color: muted, fontSize: 13),
                      ),
                      const SizedBox(height: 16),
                      FilledButton.tonalIcon(
                        onPressed: _isDeletingAccount ? null : _startCountdown,
                        icon: const Icon(Icons.delete_outline, size: 18),
                        label: const Text('Delete My Data'),
                        style: FilledButton.styleFrom(
                          foregroundColor: const Color(0xffb91c1c),
                          backgroundColor: const Color(0xfffee2e2),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 12,
                          ),
                        ),
                      ),
                    ],

                    const Divider(height: 36, color: Color(0xfffecaca)),
                    const Text(
                      'Delete Account',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Color(0xffb91c1c),
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Permanently delete your account credentials from Firebase Authentication, all documents in Cloud Firestore (users/{uid}), and any uploaded media in Firebase Storage. This action cannot be undone.',
                      style: TextStyle(color: muted, fontSize: 13),
                    ),
                    const SizedBox(height: 14),
                    if (_isDeletingAccount)
                      const Row(
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: Color(0xffdc2626),
                            ),
                          ),
                          SizedBox(width: 12),
                          Text(
                            'Permanently deleting account and all data...',
                            style: TextStyle(
                              color: Color(0xffb91c1c),
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
                        label: const Text('Delete Account'),
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
      side: const BorderSide(color: Color(0xffe5e7eb)),
    ),
    child: Padding(
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: accent, size: 20),
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
