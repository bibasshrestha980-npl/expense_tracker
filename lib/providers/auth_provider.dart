import 'dart:async';
import 'dart:math' as math;

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class AuthProvider extends ChangeNotifier {
  final FirebaseAuth _auth;
  late final StreamSubscription<User?> _subscription;
  User? user;
  bool loading = true;
  bool _isCodeVerified = false;
  String? _verificationCode;

  AuthProvider({FirebaseAuth? auth}) : _auth = auth ?? FirebaseAuth.instance {
    _subscription = _auth.authStateChanges().listen((value) {
      final prevUser = user;
      user = value;
      loading = false;
      if (value != null &&
          (prevUser?.uid != value.uid || _verificationCode == null)) {
        _generateVerificationCode();
      }
      notifyListeners();
    });
  }

  bool get isCodeVerified => _isCodeVerified;
  String? get currentVerificationCode => _verificationCode;

  void _generateVerificationCode() {
    _verificationCode = (100000 + math.Random().nextInt(900000)).toString();
    _isCodeVerified = false;
    try {
      user?.sendEmailVerification().catchError((_) {});
    } catch (_) {}
  }

  Future<void> sendVerificationCode() async {
    _generateVerificationCode();
    notifyListeners();
  }

  bool verifyCode(String inputCode) {
    if (_verificationCode != null && inputCode.trim() == _verificationCode) {
      _isCodeVerified = true;
      notifyListeners();
      return true;
    }
    return false;
  }

  Future<bool> checkEmailLinkVerified() async {
    try {
      await user?.reload();
      user = _auth.currentUser;
      if (user?.emailVerified == true) {
        _isCodeVerified = true;
        notifyListeners();
        return true;
      }
    } catch (_) {}
    return false;
  }

  Future<void> signIn(String email, String password) async {
    _isCodeVerified = false;
    await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    _generateVerificationCode();
    notifyListeners();
  }

  Future<void> register(String email, String password) async {
    _isCodeVerified = false;
    await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    _generateVerificationCode();
    notifyListeners();
  }

  Future<void> signInWithGoogle() async {
    _isCodeVerified = false;
    final googleProvider = GoogleAuthProvider();
    if (kIsWeb) {
      await _auth.signInWithPopup(googleProvider);
    } else {
      await _auth.signInWithProvider(googleProvider);
    }
    _generateVerificationCode();
    notifyListeners();
  }

  Future<void> signInAnonymously() async {
    _isCodeVerified = false;
    await _auth.signInAnonymously();
    _generateVerificationCode();
    notifyListeners();
  }

  Future<void> resetPassword(String email) =>
      _auth.sendPasswordResetEmail(email: email.trim());

  Future<void> signOut() async {
    _isCodeVerified = false;
    _verificationCode = null;
    await _auth.signOut();
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
