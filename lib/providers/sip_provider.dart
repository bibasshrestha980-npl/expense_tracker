import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../models/expense.dart';
import '../models/sip.dart';
import 'expense_provider.dart';

class SipProvider extends ChangeNotifier {
  final String uid;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _subscription;
  List<Sip> _items = [];
  bool loading = true;
  String? error;

  SipProvider(this.uid, {List<Sip>? initialSips}) {
    if (initialSips != null) {
      _items = initialSips;
      loading = false;
      return;
    }
    if (uid.isNotEmpty) {
      _subscription = collection.snapshots().listen(
        (snapshot) {
          _items = snapshot.docs.map(Sip.fromDoc).toList();
          loading = false;
          error = null;
          notifyListeners();
        },
        onError: (Object e) {
          loading = false;
          error = 'Could not load SIPs. Check your connection.';
          notifyListeners();
        },
      );
    } else {
      loading = false;
    }
  }

  CollectionReference<Map<String, dynamic>> get collection => FirebaseFirestore
      .instance
      .collection('users')
      .doc(uid)
      .collection('sips');

  List<Sip> get sips => List.unmodifiable(_items);
  List<Sip> get activeSips => _items.where((s) => s.active).toList();
  List<Sip> get pausedSips => _items.where((s) => !s.active).toList();

  int get totalMonthlyCommitmentCents =>
      activeSips.fold(0, (total, s) => total + s.monthlyAmountCents);

  int get totalInvestedAllSipsCents =>
      _items.fold(0, (total, s) => total + s.totalInvestedCents());

  double get totalCurrentCorpusEstimate =>
      _items.fold(0.0, (total, s) => total + s.currentEstimatedValue());

  Future<void> save(Sip sip) async {
    if (uid.isEmpty) {
      final index = _items.indexWhere((s) => s.id == sip.id);
      if (index >= 0) {
        _items[index] = sip;
      } else {
        _items.add(sip);
      }
      notifyListeners();
      return;
    }
    if (sip.id.isEmpty) {
      await collection.add(sip.toMap());
    } else {
      await collection.doc(sip.id).update(sip.toMap());
    }
  }

  Future<void> delete(String id) async {
    if (uid.isEmpty) {
      _items.removeWhere((s) => s.id == id);
      notifyListeners();
      return;
    }
    await collection.doc(id).delete();
  }

  Future<void> toggleActive(Sip sip) =>
      save(Sip(
        id: sip.id,
        name: sip.name,
        monthlyAmountCents: sip.monthlyAmountCents,
        dayOfMonth: sip.dayOfMonth,
        startDate: sip.startDate,
        targetMonths: sip.targetMonths,
        expectedReturnRate: sip.expectedReturnRate,
        folioNumber: sip.folioNumber,
        active: !sip.active,
      ));

  Future<void> logInstallmentAsExpense(
    Sip sip,
    ExpenseProvider expenseProvider,
  ) async {
    final now = DateTime.now();
    await expenseProvider.save(
      Expense(
        id: '',
        title: 'SIP: ${sip.name}',
        category: 'Other',
        amountCents: sip.monthlyAmountCents,
        date: now,
        note: 'Monthly installment for ${sip.name}',
      ),
    );
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
