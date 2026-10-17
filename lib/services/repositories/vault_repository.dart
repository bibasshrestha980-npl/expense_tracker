import 'package:cloud_firestore/cloud_firestore.dart';

import '../../models/expense.dart';
import '../vault_cipher.dart';
import 'expense_repository.dart';

class VaultRepository extends FirestoreExpenseRepository {
  final VaultCipher cipher;
  final String owner;
  VaultRepository(this.owner, this.cipher, {super.firestore});
  void _check(String uid) {
    if (uid != owner) throw StateError('Vault account mismatch');
  }

  Future<Map<String, dynamic>> _encode(Expense e, String id) => cipher.seal({
    'title': e.title,
    'category': e.category,
    'amountCents': e.amountCents,
    'date': e.date.toIso8601String(),
    'note': e.note,
    'type': e.isIncome ? 'income' : 'expense',
  }, '$owner/expenses/$id');
  Future<Expense> _decode(DocumentSnapshot<Map<String, dynamic>> d) async {
    final data = await cipher.open(d.data()!, '$owner/expenses/${d.id}');
    return Expense(
      id: d.id,
      title: data['title'] as String,
      category: data['category'] as String,
      amountCents: data['amountCents'] as int,
      date: DateTime.parse(data['date'] as String),
      note: data['note'] as String,
      isIncome: data['type'] == 'income',
    );
  }

  @override
  Stream<List<Expense>> watchExpenses(String uid) {
    _check(uid);
    return getCollection(uid)!.snapshots().asyncMap((s) async {
      final items = await Future.wait(s.docs.map(_decode));
      items.sort((a, b) => b.date.compareTo(a.date));
      return items;
    });
  }

  @override
  Future<List<Expense>> getExpenses(String uid) async {
    _check(uid);
    return Future.wait((await getCollection(uid)!.get()).docs.map(_decode));
  }

  @override
  Future<void> saveExpense(String uid, Expense expense) async {
    _check(uid);
    final ref = expense.id.isEmpty
        ? getCollection(uid)!.doc()
        : getCollection(uid)!.doc(expense.id);
    await ref.set(await _encode(expense, ref.id));
  }

  /// Read and encrypt in a transaction so a concurrent update is never overwritten.
  /// Interrupted migrations resume at the next unlock; no plaintext fallback in reads.
  Future<void> migrateLegacy() async {
    final docs = await getCollection(owner)!
        .get(const GetOptions(source: Source.server));
    for (final d in docs.docs) {
      await firestore.runTransaction((tx) async {
        final current = await tx.get(d.reference);
        if (!current.exists) return;
        if (current.data()!['v'] == 1) {
          await _decode(current);
          return;
        }
        final encrypted = await _encode(Expense.fromDoc(current), current.id);
        tx.set(current.reference, encrypted);
      });
    }
  }

  /// One-time retirement of the vault. Validate every ciphertext before writing.
  /// Per-document transactions preserve concurrent edits; retries skip converted data.
  Future<void> restorePlaintext() async {
    final docs = await getCollection(owner)!
        .get(const GetOptions(source: Source.server));
    for (final d in docs.docs) {
      if (d.data()['v'] == 1) await _decode(d);
    }
    for (final d in docs.docs) {
      await firestore.runTransaction((tx) async {
        final current = await tx.get(d.reference);
        if (!current.exists || current.data()!['v'] != 1) return;
        tx.set(current.reference, (await _decode(current)).toMap());
      });
    }
  }

  @override
  Future<int> migrateExpenses({
    required String fromUid,
    required String toUid,
    bool deleteSource = false,
    List<Expense>? preloadedExpenses,
  }) async {
    _check(toUid);
    if (preloadedExpenses == null) {
      throw StateError('Unlock the source vault before importing');
    }
    for (final e in preloadedExpenses) {
      final ref = getCollection(toUid)!.doc();
      await ref.set(await _encode(e, ref.id));
    }
    return preloadedExpenses.length;
  }
}
