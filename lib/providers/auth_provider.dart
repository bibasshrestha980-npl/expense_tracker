import 'dart:async';

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

  FirebaseAuth get _auth => _customAuth ?? FirebaseAuth.instance;

  AuthProvider({FirebaseAuth? auth, ExpenseRepository? expenseRepository})
    : _customAuth = auth,
      _expenseRepository = expenseRepository ?? FirestoreExpenseRepository() {
    try {
      _subscription = _auth.authStateChanges().listen((value) {
        user = value;
        loading = false;
        notifyListeners();
      });
    } catch (_) {
      // Allows instantiation in pure unit test environments without Firebase.initializeApp
      loading = false;
    }
  }

  bool get requiresEmailVerification =>
      user != null && !user!.isAnonymous && !user!.emailVerified;

  Future<void> sendVerificationEmail() async {
    final current = _auth.currentUser;
    if (current == null || current.isAnonymous || current.emailVerified) return;
    await current.sendEmailVerification();
  }

  Future<bool> checkEmailLinkVerified() async {
    final current = _auth.currentUser;
    if (current == null) return false;
    await current.reload();
    final refreshed = _auth.currentUser;
    if (refreshed == null || refreshed.uid != current.uid) return false;
    if (refreshed.emailVerified) await refreshed.getIdToken(true);
    user = refreshed;
    notifyListeners();
    return refreshed.emailVerified;
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

    user = _auth.currentUser;
    notifyListeners();
  }

  Future<void> register(String email, String password) async {
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

    user = _auth.currentUser;
    notifyListeners();
  }

  Future<void> signInWithGoogle() async {
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

    user = _auth.currentUser;
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
    notifyListeners();
  }

  Future<void> signInAnonymously() async {
    await _auth.signInAnonymously();
    user = _auth.currentUser;
    notifyListeners();
  }

  Future<void> resetPassword(String email) =>
      _auth.sendPasswordResetEmail(email: email.trim());

  Future<void> signOut() async {
    await _auth.signOut();
  }

  Future<void> deleteAccount({
    required Future<AuthCredential?> Function(User user) onReauthenticate,
    AccountDeletionService? deletionService,
  }) async {
    final service = deletionService ?? AccountDeletionService(auth: _auth);
    await service.deleteAccount(onReauthenticate: onReauthenticate);
    user = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
