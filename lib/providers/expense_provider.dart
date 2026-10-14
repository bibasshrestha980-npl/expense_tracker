import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../models/expense.dart';

class ExpenseProvider extends ChangeNotifier {
  final String uid;
  late final StreamSubscription<QuerySnapshot<Map<String, dynamic>>>
  _subscription;
  List<Expense> _items = [];
  bool loading = true;
  String? error;
  DateTime month = DateTime(DateTime.now().year, DateTime.now().month);
  String category = 'All', search = '';
  String sort = 'Newest first';
  int get previousTotal {
    final previous = DateTime(month.year, month.month - 1);
    return _items
        .where(
          (e) => e.date.year == previous.year && e.date.month == previous.month,
        )
        .fold(0, (value, e) => value + e.amountCents);
  }

  List<int> get dailyTotals => List.generate(
    DateTime(month.year, month.month + 1, 0).day,
    (index) => monthly
        .where((e) => e.date.day == index + 1)
        .fold(0, (value, e) => value + e.amountCents),
  );
  void setSort(String value) {
    sort = value;
    notifyListeners();
  }

  ExpenseProvider(this.uid) {
    _subscription = collection
        .orderBy('date', descending: true)
        .snapshots()
        .listen(
          (s) {
            _items = s.docs.map(Expense.fromDoc).toList();
            loading = false;
            error = null;
            notifyListeners();
          },
          onError: (Object e) {
            loading = false;
            error = 'Could not load expenses. Check your connection and Firebase permissions.';
            notifyListeners();
          },
        );
  }
  CollectionReference<Map<String, dynamic>> get collection => FirebaseFirestore
      .instance
      .collection('users')
      .doc(uid)
      .collection('expenses');
  List<Expense> get monthly => _items
      .where((e) => e.date.year == month.year && e.date.month == month.month)
      .toList();
  List<Expense> get visible {
    final result = monthly
        .where(
          (e) =>
              (category == 'All' || e.category == category) &&
              '${e.title} ${e.note}'.toLowerCase().contains(
                search.toLowerCase(),
              ),
        )
        .toList();
    result.sort(
      (a, b) => switch (sort) {
        'Oldest first' => a.date.compareTo(b.date),
        'Highest amount' => b.amountCents.compareTo(a.amountCents),
        'Lowest amount' => a.amountCents.compareTo(b.amountCents),
        _ => b.date.compareTo(a.date),
      },
    );
    return result;
  }

  int get total => monthly.fold(0, (total, e) => total + e.amountCents);
  int categoryTotal(String value) => monthly
      .where((e) => e.category == value)
      .fold(0, (total, e) => total + e.amountCents);
  void changeMonth(int delta) {
    month = DateTime(month.year, month.month + delta);
    notifyListeners();
  }

  void filter(String value) {
    category = value;
    notifyListeners();
  }

  void find(String value) {
    search = value;
    notifyListeners();
  }

  Future<void> save(Expense e) async {
    if (e.id.isEmpty) {
      await collection.add(e.toMap());
    } else {
      await collection.doc(e.id).update(e.toMap());
    }
  }

  Future<void> delete(String id) => collection.doc(id).delete();
  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
