import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../models/expense.dart';
import '../models/calendar_period.dart';

class ExpenseProvider extends ChangeNotifier {
  final String uid;
  final FirebaseFirestore? database;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _subscription;
  List<Expense> _items = [];
  bool loading = true;
  String? error;
  DateTime month = DateTime(DateTime.now().year, DateTime.now().month);
  String category = 'All', search = '';
  String sort = 'Newest first';
  String transactionType = 'All';
  void setType(String value) {
    transactionType = value;
    category = 'All';
    notifyListeners();
  }

  List<Expense> get monthlyTransactions =>
      _items.where((e) => period.contains(e.date)).toList();
  int get income => monthlyTransactions
      .where((e) => e.isIncome)
      .fold(0, (value, e) => value + e.amountCents);
  int get balance => _items.fold(
    0,
    (value, e) => value + (e.isIncome ? e.amountCents : -e.amountCents),
  );
  int get monthlyNet => income - total;
  bool nepali = false;
  CalendarPeriod get period => CalendarPeriod(month, nepali: nepali);
  void setCalendar(bool value) {
    if (nepali == value) return;
    final now = DateTime.now();
    final anchor = period.contains(now) ? now : month;
    nepali = value;
    month = CalendarPeriod(anchor, nepali: value).start;
    notifyListeners();
  }

  int get previousTotal {
    final previous = CalendarPeriod(period.shifted(-1), nepali: nepali);
    return _items
        .where((e) => !e.isIncome && previous.contains(e.date))
        .fold(0, (value, e) => value + e.amountCents);
  }

  List<int> get dailyTotals => List.generate(
    period.days,
    (index) => monthly
        .where((e) => period.dayNumber(e.date) == index + 1)
        .fold(0, (value, e) => value + e.amountCents),
  );
  void setSort(String value) {
    sort = value;
    notifyListeners();
  }

  ExpenseProvider(
    this.uid, {
    FirebaseFirestore? firestore,
    List<Expense>? initialExpenses,
  }) : database = firestore ?? (uid.isEmpty ? null : FirebaseFirestore.instance) {
    if (initialExpenses != null) {
      _items = initialExpenses;
      loading = false;
      return;
    }
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
  CollectionReference<Map<String, dynamic>> get collection =>
      database!.collection('users').doc(uid).collection('expenses');
  List<Expense> get monthly =>
      monthlyTransactions.where((e) => !e.isIncome).toList();
  List<Expense> get visible {
    final result = monthlyTransactions
        .where(
          (e) =>
              (transactionType == 'All' ||
                  (transactionType == 'Income' ? e.isIncome : !e.isIncome)) &&
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
    final next = period.shifted(delta);
    if (next.year < 2000 || next.year > 2100) return;
    month = next;
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
    if (uid.isEmpty) {
      _items.add(e);
      notifyListeners();
      return;
    }
    if (e.id.isEmpty) {
      await collection.add(e.toMap());
    } else {
      await collection.doc(e.id).update(e.toMap());
    }
  }

  Future<void> delete(String id) => collection.doc(id).delete();
  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
