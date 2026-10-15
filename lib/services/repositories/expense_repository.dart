import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../../models/expense.dart';

/// Abstract repository defining data operations for Expense and Income records.
abstract class ExpenseRepository {
  /// Real-time stream of all expenses for the given [uid], ordered by date descending.
  Stream<List<Expense>> watchExpenses(String uid);

  /// Fetch a one-time snapshot of all expenses for [uid].
  Future<List<Expense>> getExpenses(String uid);

  /// Add a new expense or update an existing one.
  Future<void> saveExpense(String uid, Expense expense);

  /// Delete a single expense record by [expenseId].
  Future<void> deleteExpense(String uid, String expenseId);

  /// Permanently delete all expense documents for [uid].
  Future<void> deleteAllExpenses(String uid);

  /// Transfer all expenses from [fromUid] to [toUid].
  /// Returns the number of migrated records.
  Future<int> migrateExpenses({
    required String fromUid,
    required String toUid,
    bool deleteSource = false,
    List<Expense>? preloadedExpenses,
  });

  /// Access the underlying collection for tests or legacy checks.
  CollectionReference<Map<String, dynamic>>? getCollection(String uid);
}

/// Production implementation of [ExpenseRepository] backed by Cloud Firestore.
class FirestoreExpenseRepository implements ExpenseRepository {
  final FirebaseFirestore? _customFirestore;

  FirestoreExpenseRepository({FirebaseFirestore? firestore})
    : _customFirestore = firestore;

  FirebaseFirestore get firestore =>
      _customFirestore ?? FirebaseFirestore.instance;

  @override
  CollectionReference<Map<String, dynamic>>? getCollection(String uid) {
    if (uid.isEmpty) return null;
    return firestore.collection('users').doc(uid).collection('expenses');
  }

  @override
  Stream<List<Expense>> watchExpenses(String uid) {
    if (uid.isEmpty) return Stream.value(const <Expense>[]);
    final col = getCollection(uid);
    if (col == null) return Stream.value(const <Expense>[]);
    return col
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map(Expense.fromDoc).toList());
  }

  @override
  Future<List<Expense>> getExpenses(String uid) async {
    if (uid.isEmpty) return const <Expense>[];
    final col = getCollection(uid);
    if (col == null) return const <Expense>[];
    final snapshot = await col.orderBy('date', descending: true).get();
    return snapshot.docs.map(Expense.fromDoc).toList();
  }

  @override
  Future<void> saveExpense(String uid, Expense expense) async {
    if (uid.isEmpty) return;
    final collection = getCollection(uid);
    if (collection == null) return;

    // Ensure date is strictly a native Timestamp and amountCents is an integer
    final data = expense.toMap();

    if (expense.id.isEmpty) {
      await collection.add(data);
    } else {
      await collection.doc(expense.id).set(data, SetOptions(merge: true));
    }
  }

  @override
  Future<void> deleteExpense(String uid, String expenseId) async {
    if (uid.isEmpty || expenseId.isEmpty) return;
    final collection = getCollection(uid);
    if (collection == null) return;
    await collection.doc(expenseId).delete();
  }

  @override
  Future<void> deleteAllExpenses(String uid) async {
    if (uid.isEmpty) return;
    final collection = getCollection(uid);
    if (collection == null) return;
    final snapshot = await collection.get();
    if (snapshot.docs.isEmpty) return;

    WriteBatch batch = firestore.batch();
    int batchCount = 0;
    for (final doc in snapshot.docs) {
      batch.delete(doc.reference);
      batchCount++;
      if (batchCount >= 450) {
        await batch.commit();
        batch = firestore.batch();
        batchCount = 0;
      }
    }
    if (batchCount > 0) {
      await batch.commit();
    }
  }

  @override
  Future<int> migrateExpenses({
    required String fromUid,
    required String toUid,
    bool deleteSource = false,
    List<Expense>? preloadedExpenses,
  }) async {
    if (fromUid.isEmpty || toUid.isEmpty || fromUid == toUid) return 0;

    final expenses = preloadedExpenses ?? await getExpenses(fromUid);
    if (expenses.isEmpty) return 0;

    final targetCollection = getCollection(toUid);
    if (targetCollection == null) return 0;
    WriteBatch batch = firestore.batch();
    int count = 0;

    for (final expense in expenses) {
      // Create new doc in target user's collection, strictly serialized
      final targetDocRef = targetCollection.doc();
      batch.set(targetDocRef, expense.toMap());
      count++;
      if (count >= 450) {
        await batch.commit();
        batch = firestore.batch();
        count = 0;
      }
    }
    if (count > 0) {
      await batch.commit();
    }

    if (deleteSource) {
      try {
        await deleteAllExpenses(fromUid);
      } catch (_) {
        // Source deletion may fail if auth session already switched
      }
    }

    return expenses.length;
  }
}
