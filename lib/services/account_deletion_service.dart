import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';

/// Service responsible for completely purging user data from Cloud Firestore,
/// Firebase Storage, and deleting the user account from Firebase Authentication.
///
/// ARCHITECTURAL NOTE:
/// In client-side deletion flows, Firestore documents MUST be deleted BEFORE
/// invoking `user.delete()`.
///
/// Why?
/// Cloud Firestore security rules typically enforce owner checks:
/// `request.auth != null && request.auth.uid == userId`.
/// When `user.delete()` is executed, the client's auth credentials are
/// immediately revoked. If Firestore deletion is attempted after `user.delete()`,
/// `request.auth` will evaluate to null, causing Firestore to reject the request
/// with a `permission-denied` error.
///
/// SERVER-SIDE ALTERNATIVE (Cloud Functions):
/// For enterprise resilience, an auth blocking trigger or Cloud Function
/// (`functions.auth.user().onDelete()`) using the Firebase Admin SDK can be deployed:
/// ```typescript
/// export const cleanupUser = functions.auth.user().onDelete(async (user) => {
///   const firestore = admin.firestore();
///   const storage = admin.storage();
///   await firestore.recursiveDelete(firestore.doc(`users/${user.uid}`));
///   await storage.bucket().deleteFiles({ prefix: `users/${user.uid}/` });
/// });
/// ```
/// The Admin SDK bypasses security rules entirely and completes cleanup even if
/// the user closes the app or loses network connection immediately after account deletion.
class AccountDeletionService {
  final FirebaseAuth? _customAuth;
  final FirebaseFirestore? _customFirestore;
  final FirebaseStorage? _customStorage;

  AccountDeletionService({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
    FirebaseStorage? storage,
  }) : _customAuth = auth,
       _customFirestore = firestore,
       _customStorage = storage;

  FirebaseAuth get _auth => _customAuth ?? FirebaseAuth.instance;
  FirebaseFirestore get _firestore =>
      _customFirestore ?? FirebaseFirestore.instance;
  FirebaseStorage get _storage => _customStorage ?? FirebaseStorage.instance;

  /// Deletes the authenticated user's:
  /// 1. Cloud Firestore documents (`users/{uid}/expenses/*` and `users/{uid}`)
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
    await deleteStorageUserData(uid);

    // STEP 3: Delete Firebase Authentication account
    try {
      await user.delete();
    } on FirebaseAuthException catch (e) {
      if (e.code == 'requires-recent-login') {
        final credential = await onReauthenticate(user);
        if (credential == null) {
          throw FirebaseAuthException(
            code: 'requires-recent-login',
            message: 'Account deletion requires recent sign-in. Re-authentication was cancelled.',
          );
        }

        await user.reauthenticateWithCredential(credential);
        // Retry deletion after successful re-authentication
        await user.delete();
      } else {
        rethrow;
      }
    }
  }

  /// Deletes all documents in `users/{uid}/expenses` (in batches) and the parent `users/{uid}` document.
  Future<void> deleteFirestoreUserData(String uid) async {
    try {
      final userDocRef = _firestore.collection('users').doc(uid);
      final expensesRef = userDocRef.collection('expenses');
      final snapshot = await expensesRef.get();

      if (snapshot.docs.isNotEmpty) {
        WriteBatch batch = _firestore.batch();
        int batchCount = 0;
        for (final doc in snapshot.docs) {
          batch.delete(doc.reference);
          batchCount++;
          if (batchCount >= 450) {
            await batch.commit();
            batch = _firestore.batch();
            batchCount = 0;
          }
        }
        if (batchCount > 0) {
          await batch.commit();
        }
      }

      // Delete the parent user profile document
      await userDocRef.delete();
    } catch (e) {
      debugPrint('Firestore data cleanup warning: $e');
      rethrow;
    }
  }

  /// Recursively deletes all files and folders under `users/{uid}/*` in Firebase Storage.
  Future<void> deleteStorageUserData(String uid) async {
    try {
      final userFolderRef = _storage.ref('users/$uid');
      await _deleteStorageFolderRecursively(userFolderRef);
    } on FirebaseException catch (e) {
      // If the folder or bucket does not exist, ignore (no files to clean up)
      if (e.code == 'object-not-found' || e.code == 'bucket-not-found') {
        return;
      }
      debugPrint('Storage cleanup non-fatal warning: ${e.message}');
    } catch (e) {
      debugPrint('Storage cleanup non-fatal error: $e');
    }
  }

  Future<void> _deleteStorageFolderRecursively(Reference ref) async {
    try {
      final listResult = await ref.listAll();
      for (final item in listResult.items) {
        await item.delete();
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
