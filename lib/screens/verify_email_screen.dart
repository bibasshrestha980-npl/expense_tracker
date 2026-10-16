import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart' show FirebaseAuthException;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../theme.dart';

class VerifyEmailScreen extends StatefulWidget {
  const VerifyEmailScreen({super.key});

  @override
  State<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends State<VerifyEmailScreen> {
  String? _error;
  bool _busy = false;
  bool _sent = false;
  int _remaining = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _sendEmail();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _message(Object error) =>
      error is FirebaseAuthException && error.code == 'too-many-requests'
      ? 'Too many requests. Please wait a few minutes and try again.'
      : 'Could not connect. Check your connection and try again.';

  Future<void> _sendEmail() async {
    if (_busy || _remaining > 0) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await context.read<AuthProvider>().sendVerificationEmail();
      if (!mounted) return;
      setState(() {
        _sent = true;
        _remaining = 60;
      });
      _timer?.cancel();
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (!mounted) {
          timer.cancel();
          return;
        }
        setState(() => _remaining--);
        if (_remaining == 0) timer.cancel();
      });
    } catch (error) {
      if (mounted) setState(() => _error = _message(error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _checkEmail() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final verified = await context
          .read<AuthProvider>()
          .checkEmailLinkVerified();
      if (mounted && !verified) {
        setState(
          () => _error = 'Email not verified yet. Open the link in your email, then try again.',
        );
      }
    } catch (error) {
      if (mounted) setState(() => _error = _message(error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _signOut() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await context.read<AuthProvider>().signOut();
    } catch (error) {
      if (mounted) setState(() => _error = _message(error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final email =
        context.watch<AuthProvider>().user?.email ?? 'your email address';
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Icon(
                      Icons.mark_email_unread_outlined,
                      size: 56,
                      color: context.appAccent,
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Verify your email',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _sent
                          ? 'Verification email sent to $email.'
                          : 'Send a verification link to $email.',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Open Gmail or your email app and click the verification link. Then return here to continue. Check Spam if the email is missing.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: context.appMuted),
                    ),
                    if (_error != null) ...[
                      const SizedBox(height: 16),
                      Text(
                        _error!,
                        textAlign: TextAlign.center,
                        style: TextStyle(color: context.palette.error),
                      ),
                    ],
                    const SizedBox(height: 24),
                    FilledButton.icon(
                      onPressed: _busy ? null : _checkEmail,
                      icon: const Icon(Icons.mark_email_read_outlined),
                      label: const Text("I've verified my email"),
                    ),
                    const SizedBox(height: 8),
                    OutlinedButton(
                      onPressed: _busy || _remaining > 0 ? null : _sendEmail,
                      child: Text(
                        _remaining > 0
                            ? 'Resend in ${_remaining}s'
                            : _sent
                            ? 'Resend verification email'
                            : 'Send verification email',
                      ),
                    ),
                    TextButton(
                      onPressed: _busy ? null : _signOut,
                      child: const Text('Use a different account'),
                    ),
                    if (_busy)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(8),
                          child: CircularProgressIndicator(),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
