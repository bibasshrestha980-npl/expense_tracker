import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../theme.dart';

class VerifyCodeScreen extends StatefulWidget {
  const VerifyCodeScreen({super.key});

  @override
  State<VerifyCodeScreen> createState() => _VerifyCodeScreenState();
}

class _VerifyCodeScreenState extends State<VerifyCodeScreen> {
  final _codeController = TextEditingController();
  String? _errorMessage;
  bool _busy = false;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  void _verify() {
    final code = _codeController.text.trim();
    if (code.length != 6 || int.tryParse(code) == null) {
      setState(
        () => _errorMessage = 'Please enter a valid 6-digit verification code.',
      );
      return;
    }

    final auth = context.read<AuthProvider>();
    final ok = auth.verifyCode(code);
    if (!ok) {
      setState(
        () => _errorMessage =
            'Incorrect code. Please check the 6-digit code and try again.',
      );
    }
  }

  Future<void> _checkEmailLink() async {
    setState(() {
      _busy = true;
      _errorMessage = null;
    });
    final auth = context.read<AuthProvider>();
    final verified = await auth.checkEmailLinkVerified();
    if (mounted) {
      setState(() {
        _busy = false;
        if (!verified) {
          _errorMessage = 'Email not yet verified via link. Please click the link in your email or enter the 6-digit code below.';
        }
      });
    }
  }

  Future<void> _resendCode() async {
    final auth = context.read<AuthProvider>();
    await auth.sendVerificationCode();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('A new 6-digit verification code has been generated!'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final generatedCode = auth.currentVerificationCode;
    final email =
        auth.user?.email ??
        (auth.user?.isAnonymous == true ? 'Guest Session' : 'Your Account');

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
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Center(
                      child: CircleAvatar(
                        radius: 36,
                        backgroundColor: Color(0xffe6f3ed),
                        child: Icon(
                          Icons.security_rounded,
                          size: 40,
                          color: accent,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Two-Step Verification',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'A verification code is required to access your Pocket account for $email.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: muted, fontSize: 13),
                    ),
                    const SizedBox(height: 24),

                    // Display Current Verification Code Banner
                    if (generatedCode != null)
                      InkWell(
                        onTap: () {
                          _codeController.text = generatedCode;
                          Clipboard.setData(ClipboardData(text: generatedCode));
                        },
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 14,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xfff0fdf4),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xff86efac)),
                          ),
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: const [
                                  Icon(
                                    Icons.key_rounded,
                                    size: 16,
                                    color: accent,
                                  ),
                                  SizedBox(width: 6),
                                  Text(
                                    'Your Verification Code',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13,
                                      color: accent,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                generatedCode,
                                style: const TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 8,
                                  color: Color(0xff14532d),
                                ),
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                'Tap code to auto-fill & copy',
                                style: TextStyle(color: muted, fontSize: 11),
                              ),
                            ],
                          ),
                        ),
                      ),

                    const SizedBox(height: 24),

                    TextFormField(
                      controller: _codeController,
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      maxLength: 6,
                      style: const TextStyle(
                        fontSize: 22,
                        letterSpacing: 6,
                        fontWeight: FontWeight.bold,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Enter 6-Digit Code',
                        hintText: '------',
                        counterText: '',
                        prefixIcon: Icon(Icons.pin_outlined),
                      ),
                      onFieldSubmitted: (_) => _verify(),
                    ),

                    if (_errorMessage != null) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xfffef2f2),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xfffca5a5)),
                        ),
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(
                            color: Color(0xffb91c1c),
                            fontSize: 13,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],

                    const SizedBox(height: 20),

                    FilledButton(
                      onPressed: _busy ? null : _verify,
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text(
                        'Verify & Continue',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),

                    const SizedBox(height: 10),
                    OutlinedButton.icon(
                      onPressed: _busy ? null : _checkEmailLink,
                      icon: const Icon(
                        Icons.mark_email_read_outlined,
                        size: 18,
                      ),
                      label: const Text('I Clicked Verification Email Link'),
                    ),

                    const SizedBox(height: 14),
                    Wrap(
                      alignment: WrapAlignment.spaceBetween,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        TextButton(
                          onPressed: _busy ? null : _resendCode,
                          child: const Text('Resend code'),
                        ),
                        TextButton(
                          onPressed: () => auth.signOut(),
                          child: const Text('Log out / Back'),
                        ),
                      ],
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
