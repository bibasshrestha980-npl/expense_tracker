import 'dart:async';
import 'dart:math' as math;

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../models/expense.dart';
import '../services/account_deletion_service.dart';
import '../services/repositories/expense_repository.dart';

class AuthProvider extends ChangeNotifier {
  final FirebaseAuth? _customAuth;
  final ExpenseRepository _expenseRepository;
  StreamSubscription<User?>? _subscription;
  User? user;
  bool loading = true;
  bool _isCodeVerified = false;
  String? _verificationCode;

  FirebaseAuth get _auth => _customAuth ?? FirebaseAuth.instance;

  AuthProvider({FirebaseAuth? auth, ExpenseRepository? expenseRepository})
    : _customAuth = auth,
      _expenseRepository = expenseRepository ?? FirestoreExpenseRepository() {
    try {
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
    } catch (_) {
      // Allows instantiation in pure unit test environments without Firebase.initializeApp
      loading = false;
    }
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

  /// Preloads guest expenses while the anonymous auth session is still valid.
  Future<List<Expense>> _fetchGuestExpenses(User? guestUser) async {
    if (guestUser == null || !guestUser.isAnonymous) return [];
    try {
      return await _expenseRepository.getExpenses(guestUser.uid);
    } catch (e) {
      debugPrint('Warning: unable to preload guest expenses: $e');
      return [];
    }
  }

  /// Migrates transactions from an anonymous guest UID to a permanent UID.
  Future<int> migrateGuestData({
    required String guestUid,
    required String permanentUid,
    List<Expense>? preloadedExpenses,
  }) async {
    if (guestUid.isEmpty || permanentUid.isEmpty || guestUid == permanentUid) {
      return 0;
    }
    return _expenseRepository.migrateExpenses(
      fromUid: guestUid,
      toUid: permanentUid,
      preloadedExpenses: preloadedExpenses,
    );
  }

  Future<void> signIn(String email, String password) async {
    _isCodeVerified = false;
    final guest = user;
    final guestExpenses = await _fetchGuestExpenses(guest);

    await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );

    final permanent = _auth.currentUser;
    if (guest != null &&
        guest.isAnonymous &&
        permanent != null &&
        guest.uid != permanent.uid) {
      await migrateGuestData(
        guestUid: guest.uid,
        permanentUid: permanent.uid,
        preloadedExpenses: guestExpenses,
      );
    }

    _generateVerificationCode();
    notifyListeners();
  }

  Future<void> register(String email, String password) async {
    _isCodeVerified = false;
    final guest = user;

    // First attempt in-place linking if the user is currently anonymous
    if (guest != null && guest.isAnonymous) {
      try {
        final credential = EmailAuthProvider.credential(
          email: email.trim(),
          password: password,
        );
        await guest.linkWithCredential(credential);
        user = _auth.currentUser;
        _generateVerificationCode();
        notifyListeners();
        return;
      } on FirebaseAuthException catch (e) {
        if (e.code != 'credential-already-in-use' &&
            e.code != 'email-already-in-use') {
          rethrow;
        }
      }
    }

    final guestExpenses = await _fetchGuestExpenses(guest);
    await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );

    final permanent = _auth.currentUser;
    if (guest != null &&
        guest.isAnonymous &&
        permanent != null &&
        guest.uid != permanent.uid) {
      await migrateGuestData(
        guestUid: guest.uid,
        permanentUid: permanent.uid,
        preloadedExpenses: guestExpenses,
      );
    }

    _generateVerificationCode();
    notifyListeners();
  }

  Future<void> signInWithGoogle() async {
    _isCodeVerified = false;
    final guest = user;
    final googleProvider = GoogleAuthProvider();

    if (guest != null && guest.isAnonymous) {
      try {
        if (kIsWeb) {
          await guest.linkWithPopup(googleProvider);
        } else {
          await guest.linkWithProvider(googleProvider);
        }
        user = _auth.currentUser;
        _generateVerificationCode();
        notifyListeners();
        return;
      } on FirebaseAuthException catch (e) {
        if (e.code != 'credential-already-in-use' &&
            e.code != 'email-already-in-use') {
          rethrow;
        }
      }
    }

    final guestExpenses = await _fetchGuestExpenses(guest);
    if (kIsWeb) {
      await _auth.signInWithPopup(googleProvider);
    } else {
      await _auth.signInWithProvider(googleProvider);
    }

    final permanent = _auth.currentUser;
    if (guest != null &&
        guest.isAnonymous &&
        permanent != null &&
        guest.uid != permanent.uid) {
      await migrateGuestData(
        guestUid: guest.uid,
        permanentUid: permanent.uid,
        preloadedExpenses: guestExpenses,
      );
    }

    _generateVerificationCode();
    notifyListeners();
  }

  Future<void> linkWithEmail(String email, String password) async {
    final current = _auth.currentUser;
    if (current == null) return;
    final credential = EmailAuthProvider.credential(
      email: email.trim(),
      password: password,
    );
    await current.linkWithCredential(credential);
    user = _auth.currentUser;
    _generateVerificationCode();
    notifyListeners();
  }

  Future<void> linkWithGoogle() async {
    final current = _auth.currentUser;
    if (current == null) return;
    final googleProvider = GoogleAuthProvider();
    if (kIsWeb) {
      await current.linkWithPopup(googleProvider);
    } else {
      await current.linkWithProvider(googleProvider);
    }
    user = _auth.currentUser;
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

  Future<void> deleteAccount({
    required Future<AuthCredential?> Function(User user) onReauthenticate,
    AccountDeletionService? deletionService,
  }) async {
    final service = deletionService ?? AccountDeletionService(auth: _auth);
    await service.deleteAccount(onReauthenticate: onReauthenticate);
    _isCodeVerified = false;
    _verificationCode = null;
    user = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
