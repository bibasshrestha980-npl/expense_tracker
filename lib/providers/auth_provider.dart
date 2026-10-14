import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class AuthProvider extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  late final StreamSubscription<User?> _subscription;
  User? user;
  bool loading = true;
  AuthProvider() {
    _subscription = _auth.authStateChanges().listen((value) {
      user = value;
      loading = false;
      notifyListeners();
    });
  }
  Future<void> signIn(String email, String password) async {
    await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  Future<void> register(String email, String password) async {
    await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  Future<void> resetPassword(String email) =>
      _auth.sendPasswordResetEmail(email: email.trim());
  Future<void> signOut() => _auth.signOut();
  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
