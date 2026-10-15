import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart' as app;
import '../theme.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});
  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController(), _password = TextEditingController();
  bool _register = false, _busy = false, _hidden = true;
  String? _message;

  Future<void> _submit({bool reset = false}) async {
    if (reset) {
      if (!_email.text.contains('@')) {
        setState(() => _message = 'Enter your email address first.');
        return;
      }
    } else if (!_form.currentState!.validate()) {
      return;
    }
    setState(() {
      _busy = true;
      _message = null;
    });
    try {
      final auth = context.read<app.AuthProvider>();
      if (reset) {
        await auth.resetPassword(_email.text);
        if (mounted) {
          setState(
            () => _message =
                'If an account exists, a reset email will arrive shortly.',
          );
        }
      } else if (_register) {
        await auth.register(_email.text, _password.text);
      } else {
        await auth.signIn(_email.text, _password.text);
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        setState(
          () => _message =
              e.message ?? 'Authentication failed. Please try again.',
        );
      }
    } catch (_) {
      if (mounted) {
        setState(() => _message = 'Unable to connect. Please try again.');
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _signInWithGoogle() async {
    setState(() {
      _busy = true;
      _message = null;
    });
    try {
      final auth = context.read<app.AuthProvider>();
      await auth.signInWithGoogle();
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        setState(
          () => _message =
              e.message ?? 'Google sign-in failed. Please try again.',
        );
      }
    } catch (_) {
      if (mounted) {
        setState(() => _message = 'Unable to connect to Google sign-in.');
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _signInAnonymously() async {
    setState(() {
      _busy = true;
      _message = null;
    });
    try {
      final auth = context.read<app.AuthProvider>();
      await auth.signInAnonymously();
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        setState(
          () => _message = e.message ?? 'Guest login failed. Please try again.',
        );
      }
    } catch (_) {
      if (mounted) {
        setState(() => _message = 'Unable to start guest session.');
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(28),
              child: Form(
                key: _form,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Icon(
                      Icons.account_balance_wallet_rounded,
                      size: 64,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Pocket',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 38,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const Text(
                      'A clearer view of your everyday spending.',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 36),
                    Text(
                      _register ? 'Create your account' : 'Welcome back',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      _register
                          ? 'Start tracking your expenses with a personal account.'
                          : 'Sign in to your personal spending dashboard.',
                      style: const TextStyle(color: muted),
                    ),
                    const SizedBox(height: 24),
                    TextFormField(
                      controller: _email,
                      keyboardType: TextInputType.emailAddress,
                      autofillHints: const [AutofillHints.email],
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        prefixIcon: Icon(Icons.mail_outline),
                      ),
                      validator: (v) =>
                          RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$')
                              .hasMatch(v?.trim() ?? '')
                          ? null
                          : 'Enter a valid email',
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _password,
                      autofillHints: [
                        _register
                            ? AutofillHints.newPassword
                            : AutofillHints.password,
                      ],
                      obscureText: _hidden,
                      decoration: InputDecoration(
                        labelText: 'Password',
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          tooltip: _hidden ? 'Show password' : 'Hide password',
                          onPressed: () => setState(() => _hidden = !_hidden),
                          icon: Icon(
                            _hidden
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                          ),
                        ),
                      ),
                      validator: (v) => (v?.length ?? 0) >= 6
                          ? null
                          : 'Use at least 6 characters',
                      onFieldSubmitted: (_) {
                        if (!_busy) _submit();
                      },
                    ),
                    if (_register) ...[
                      const SizedBox(height: 16),
                      TextFormField(
                        obscureText: _hidden,
                        decoration: const InputDecoration(
                          labelText: 'Confirm password',
                          prefixIcon: Icon(Icons.lock_outline),
                        ),
                        validator: (value) => value == _password.text
                            ? null
                            : 'Passwords do not match',
                      ),
                    ],
                    if (_message != null)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Text(_message!, semanticsLabel: _message),
                      ),
                    const SizedBox(height: 20),
                    FilledButton(
                      onPressed: _busy ? null : _submit,
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: _busy
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : Text(_register ? 'Create account' : 'Sign in'),
                      ),
                    ),
                    TextButton(
                      onPressed: _busy ? null : () => _submit(reset: true),
                      child: const Text('Forgot password?'),
                    ),
                    TextButton(
                      onPressed: _busy
                          ? null
                          : () => setState(() {
                              _register = !_register;
                              _message = null;
                            }),
                      child: Text(
                        _register
                            ? 'Already registered? Sign in'
                            : 'New to Pocket? Create account',
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: const [
                        Expanded(child: Divider()),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 12),
                          child: Text(
                            'OR',
                            style: TextStyle(color: muted, fontSize: 12),
                          ),
                        ),
                        Expanded(child: Divider()),
                      ],
                    ),
                    const SizedBox(height: 16),
                    OutlinedButton.icon(
                      onPressed: _busy ? null : _signInWithGoogle,
                      icon: const Icon(Icons.account_circle_outlined, size: 20),
                      label: const Padding(
                        padding: EdgeInsets.symmetric(vertical: 10),
                        child: Text('Continue with Google'),
                      ),
                    ),
                    const SizedBox(height: 10),
                    OutlinedButton.icon(
                      onPressed: _busy ? null : _signInAnonymously,
                      icon: const Icon(Icons.person_outline, size: 20),
                      label: const Padding(
                        padding: EdgeInsets.symmetric(vertical: 10),
                        child: Text('Continue as Guest'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
