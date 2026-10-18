import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:expense_tracker/models/expense.dart';
import 'package:expense_tracker/providers/expense_provider.dart';
import 'package:expense_tracker/services/repositories/expense_repository.dart';

class MockExpenseRepository implements ExpenseRepository {
  final StreamController<List<Expense>> streamController =
      StreamController<List<Expense>>.broadcast();
  final List<Expense> savedExpenses = [];
  final List<String> deletedIds = [];
  bool wipedAll = false;

  void emit(List<Expense> expenses) {
    streamController.add(expenses);
  }

  void emitError(Object error) {
    streamController.addError(error);
  }

  @override
  Stream<List<Expense>> watchExpenses(String uid) => streamController.stream;

  @override
  Future<List<Expense>> getExpenses(String uid) async =>
      List.from(savedExpenses);

  @override
  Future<void> saveExpense(String uid, Expense expense) async {
    savedExpenses.add(expense);
  }

  @override
  Future<void> deleteExpense(String uid, String expenseId) async {
    deletedIds.add(expenseId);
  }

  @override
  Future<void> deleteAllExpenses(String uid) async {
    wipedAll = true;
    savedExpenses.clear();
  }

  @override
  Future<int> migrateExpenses({
    required String fromUid,
    required String toUid,
    bool deleteSource = false,
    List<Expense>? preloadedExpenses,
  }) async => 0;

  @override
  CollectionReference<Map<String, dynamic>>? getCollection(String uid) => null;
}

void main() {
  group('ExpenseProvider with Mock Repository', () {
    late MockExpenseRepository mockRepo;

    setUp(() {
      mockRepo = MockExpenseRepository();
    });

    tearDown(() {
      mockRepo.streamController.close();
    });

    test('initializes with initialExpenses and bypasses stream listening', () {
      final sample = [
        Expense(
          id: '1',
          title: 'Coffee',
          category: 'Food',
          amountCents: 25000,
          date: DateTime.now(),
        ),
      ];

      final provider = ExpenseProvider(
        'user-1',
        repository: mockRepo,
        initialExpenses: sample,
      );
      addTearDown(provider.dispose);

      expect(provider.loading, isFalse);
      expect(provider.monthlyTransactions.length, 1);
      expect(provider.total, 25000);
      expect(provider.error, isNull);
    });

    test('handles empty uid without watching repository', () {
      final provider = ExpenseProvider('', repository: mockRepo);
      addTearDown(provider.dispose);

      expect(provider.loading, isFalse);
      expect(provider.monthlyTransactions, isEmpty);
    });

    test(
      'streams expense items from repository and notifies listeners',
      () async {
        final provider = ExpenseProvider('user-1', repository: mockRepo);
        addTearDown(provider.dispose);

        expect(provider.loading, isTrue);

        final now = DateTime.now();
        final sampleData = [
          Expense(
            id: 'exp-1',
            title: 'Groceries',
            category: 'Food',
            amountCents: 50000,
            date: now,
          ),
          Expense(
            id: 'inc-1',
            title: 'Monthly Salary',
            category: 'Salary',
            amountCents: 200000,
            date: now,
            isIncome: true,
          ),
        ];

        mockRepo.emit(sampleData);
        await pumpEventQueue();

        expect(provider.loading, isFalse);
        expect(provider.error, isNull);
        expect(provider.monthlyTransactions.length, 2);
        expect(provider.monthly.length, 1);
        expect(provider.income, 200000);
        expect(provider.total, 50000);
        expect(provider.monthlyNet, 150000);
        expect(provider.balance, 150000);
      },
    );

    test('emits error state on repository stream error', () async {
      final provider = ExpenseProvider('user-1', repository: mockRepo);
      addTearDown(provider.dispose);

      mockRepo.emitError(Exception('Network error'));
      await pumpEventQueue();

      expect(provider.loading, isFalse);
      expect(
        provider.error,
        'Could not load expenses. Check your connection and Firebase permissions.',
      );
    });

    test('calculates daily totals across calendar days', () async {
      final now = DateTime.now();
      final provider = ExpenseProvider(
        'user-1',
        repository: mockRepo,
        initialExpenses: [
          Expense(
            id: '1',
            title: 'Lunch',
            category: 'Food',
            amountCents: 12000,
            date: now,
          ),
          Expense(
            id: '2',
            title: 'Dinner',
            category: 'Food',
            amountCents: 18000,
            date: now,
          ),
        ],
      );
      addTearDown(provider.dispose);

      final currentDay = provider.period.dayNumber(now);
      expect(currentDay, isPositive);
      final daily = provider.dailyTotals;
      expect(daily.length, provider.period.days);
      expect(daily[currentDay - 1], 30000);
    });

    test(
      'filters visible transactions by search, category, and transactionType',
      () {
        final now = DateTime.now();
        final provider = ExpenseProvider(
          'user-1',
          repository: mockRepo,
          initialExpenses: [
            Expense(
              id: '1',
              title: 'Bus fare to office',
              category: 'Transport',
              amountCents: 2500,
              date: now,
            ),
            Expense(
              id: '2',
              title: 'Momo lunch',
              category: 'Food',
              amountCents: 15000,
              date: now,
            ),
            Expense(
              id: '3',
              title: 'Client payment',
              category: 'Freelance',
              amountCents: 80000,
              date: now,
              isIncome: true,
            ),
          ],
        );
        addTearDown(provider.dispose);

        expect(provider.visible.length, 3);

        // Filter by type: Income
        provider.setType('Income');
        expect(provider.visible.length, 1);
        expect(provider.visible.first.title, 'Client payment');

        // Filter by type: Expense
        provider.setType('Expense');
        expect(provider.visible.length, 2);

        // Filter by category
        provider.filter('Food');
        expect(provider.visible.length, 1);
        expect(provider.visible.first.title, 'Momo lunch');

        // Filter by search query
        provider.filter('All');
        provider.setType('All');
        provider.find('office');
        expect(provider.visible.length, 1);
        expect(provider.visible.first.title, 'Bus fare to office');
      },
    );

    test(
      'sorts visible items by newest, oldest, highest and lowest amount',
      () {
        final base = DateTime.now();
        final provider = ExpenseProvider(
          'user-1',
          repository: mockRepo,
          initialExpenses: [
            Expense(
              id: '1',
              title: 'Mid item',
              category: 'Food',
              amountCents: 30000,
              date: base.subtract(const Duration(days: 2)),
            ),
            Expense(
              id: '2',
              title: 'High item',
              category: 'Food',
              amountCents: 90000,
              date: base.subtract(const Duration(days: 1)),
            ),
            Expense(
              id: '3',
              title: 'Low item',
              category: 'Food',
              amountCents: 10000,
              date: base,
            ),
          ],
        );
        addTearDown(provider.dispose);
        provider.setCalendar(false);

        // Newest first (default)
        expect(provider.visible.first.title, 'Low item');

        // Oldest first
        provider.setSort('Oldest first');
        expect(provider.visible.first.title, 'Mid item');

        // Highest amount
        provider.setSort('Highest amount');
        expect(provider.visible.first.title, 'High item');

        // Lowest amount
        provider.setSort('Lowest amount');
        expect(provider.visible.first.title, 'Low item');
      },
    );

    test('switches calendar mode and shifts months', () {
      final provider = ExpenseProvider(
        'user-1',
        repository: mockRepo,
        initialExpenses: [],
      );
      addTearDown(provider.dispose);

      expect(provider.nepali, isTrue);
      final initialMonth = provider.month;

      provider.setCalendar(false);
      expect(provider.nepali, isFalse);

      provider.changeMonth(1);
      expect(provider.month.isAfter(initialMonth), isTrue);

      provider.changeMonth(-1);
      provider.setCalendar(true);
      expect(provider.nepali, isTrue);
    });

    test('delegates save, delete, and deleteAllData to repository', () async {
      final provider = ExpenseProvider('user-1', repository: mockRepo);
      addTearDown(provider.dispose);

      final exp = Expense(
        id: 'new-1',
        title: 'Taxi',
        category: 'Transport',
        amountCents: 50000,
        date: DateTime.now(),
      );

      await provider.save(exp);
      expect(mockRepo.savedExpenses.length, 1);
      expect(mockRepo.savedExpenses.first.title, 'Taxi');

      await provider.delete('new-1');
      expect(mockRepo.deletedIds, contains('new-1'));

      await provider.deleteAllData();
      expect(mockRepo.wipedAll, isTrue);
    });

    test(
      'offline mode (empty uid) updates local state without repository calls',
      () async {
        final provider = ExpenseProvider('', repository: mockRepo);
        addTearDown(provider.dispose);

        final exp = Expense(
          id: 'local-1',
          title: 'Local Item',
          category: 'Food',
          amountCents: 15000,
          date: DateTime.now(),
        );

        await provider.save(exp);
        expect(provider.monthlyTransactions.length, 1);
        expect(mockRepo.savedExpenses, isEmpty);

        await provider.delete('local-1');
        expect(provider.monthlyTransactions, isEmpty);
        expect(mockRepo.deletedIds, isEmpty);

        await provider.save(exp);
        expect(provider.monthlyTransactions.length, 1);
        await provider.deleteAllData();
        expect(provider.monthlyTransactions, isEmpty);
        expect(mockRepo.wipedAll, isFalse);
      },
    );
  });
}
