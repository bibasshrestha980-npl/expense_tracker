import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';

/// Removes Firestore records before deleting the Firebase Authentication account.
/// Storage cleanup is opt-in: Pocket currently has no uploaded user files.
/// Pass a storage instance only in clients that actually support file uploads.
class AccountDeletionService {
  final FirebaseAuth? _customAuth;
  final FirebaseFirestore? _customFirestore;
  final FirebaseStorage? _customStorage;
  final Duration requestTimeout;

  AccountDeletionService({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
    FirebaseStorage? storage,
    this.requestTimeout = const Duration(seconds: 20),
  }) : _customAuth = auth,
       _customFirestore = firestore,
       _customStorage = storage;

  FirebaseAuth get _auth => _customAuth ?? FirebaseAuth.instance;
  FirebaseFirestore get _firestore =>
      _customFirestore ?? FirebaseFirestore.instance;
  Future<T> _request<T>(Future<T> request, String step) => request.timeout(
    requestTimeout,
    onTimeout: () => throw TimeoutException(
      '$step timed out. Check your connection before retrying. Some records may already have been deleted.',
    ),
  );

  /// Deletes the authenticated user's:
  /// 1. Cloud Firestore documents (`users/{uid}/expenses/*`,
  ///    `users/{uid}/contributions/*`, and `users/{uid}`)
  /// 2. Firebase Storage media files (`users/{uid}/*`)
  /// 3. Firebase Authentication account (`user.delete()`)
  ///
  /// Handles `requires-recent-login` by delegating to [onReauthenticate].
  Future<void> deleteAccount({
    required Future<AuthCredential?> Function(User user) onReauthenticate,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw FirebaseAuthException(
        code: 'no-current-user',
        message: 'No authenticated user found to delete.',
      );
    }

    final uid = user.uid;

    // STEP 1: Delete Cloud Firestore data FIRST while user auth token is active
    await deleteFirestoreUserData(uid);

    // STEP 2: Delete Firebase Storage media/files while user auth token is active
    if (_customStorage != null) await deleteStorageUserData(uid);

    // STEP 3: Delete Firebase Authentication account
    try {
      await _request(user.delete(), 'Account deletion');
    } on FirebaseAuthException catch (e) {
      if (e.code == 'requires-recent-login') {
        final credential = await onReauthenticate(user);
        if (credential == null) {
          throw FirebaseAuthException(
            code: 'requires-recent-login',
            message: 'Account deletion requires recent sign-in. Re-authentication was cancelled.',
          );
        }

        await _request(
          user.reauthenticateWithCredential(credential),
          'Sign-in confirmation',
        );
        // Retry deletion after successful re-authentication
        await _request(user.delete(), 'Account deletion');
      } else {
        rethrow;
      }
    }
  }

  /// Deletes all expense and contribution documents (in batches), vault
  /// metadata, and the parent `users/{uid}` document.
  Future<void> deleteFirestoreUserData(String uid) async {
    try {
      final userDocRef = _firestore.collection('users').doc(uid);
      final expensesSnapshot = await _request(
        userDocRef
            .collection('expenses')
            .get(const GetOptions(source: Source.server)),
        'Loading account records',
      );
      final contributionsSnapshot = await _request(
        userDocRef
            .collection('contributions')
            .get(const GetOptions(source: Source.server)),
        'Loading contribution records',
      );

      final records = [...expensesSnapshot.docs, ...contributionsSnapshot.docs];
      if (records.isNotEmpty) {
        WriteBatch batch = _firestore.batch();
        int batchCount = 0;
        for (final doc in records) {
          batch.delete(doc.reference);
          batchCount++;
          if (batchCount >= 450) {
            await _request(batch.commit(), 'Deleting account records');
            batch = _firestore.batch();
            batchCount = 0;
          }
        }
        if (batchCount > 0) {
          await _request(batch.commit(), 'Deleting account records');
        }
      }

      await _request(
        userDocRef.collection('vault').doc('config').delete(),
        'Deleting vault metadata',
      );
      await _request(userDocRef.delete(), 'Deleting account profile');
    } catch (e) {
      debugPrint('Firestore data cleanup warning: $e');
      rethrow;
    }
  }

  /// Recursively deletes all files and folders under `users/{uid}/*` in Firebase Storage.
  Future<void> deleteStorageUserData(String uid) async {
    try {
      final storage = _customStorage;
      if (storage == null) return;
      final userFolderRef = storage.ref('users/$uid');
      await _deleteStorageFolderRecursively(userFolderRef);
    } on FirebaseException catch (e) {
      // If the folder or bucket does not exist, ignore (no files to clean up)
      if (e.code == 'object-not-found' || e.code == 'bucket-not-found') {
        return;
      }
      rethrow;
    }
  }

  Future<void> _deleteStorageFolderRecursively(Reference ref) async {
    try {
      final listResult = await _request(
        ref.listAll(),
        'Listing uploaded files',
      );
      for (final item in listResult.items) {
        await _request(item.delete(), 'Deleting uploaded files');
      }
      for (final prefix in listResult.prefixes) {
        await _deleteStorageFolderRecursively(prefix);
      }
    } on FirebaseException catch (e) {
      if (e.code != 'object-not-found') {
        rethrow;
      }
    }
  }
}
