import 'package:flutter_test/flutter_test.dart';
import 'package:expense_tracker/models/expense.dart';
import 'package:expense_tracker/providers/auth_provider.dart';
import 'package:expense_tracker/services/repositories/expense_repository.dart';

class MockMigrationRepository implements ExpenseRepository {
  final Map<String, List<Expense>> storage = {};
  int fetchCount = 0;

  @override
  Future<List<Expense>> getExpenses(String uid) async {
    fetchCount++;
    return List<Expense>.from(storage[uid] ?? []);
  }

  @override
  Future<void> saveExpense(String uid, Expense expense) async {
    storage.putIfAbsent(uid, () => []).add(expense);
  }

  @override
  Future<int> migrateExpenses({
    required String fromUid,
    required String toUid,
    bool deleteSource = false,
    List<Expense>? preloadedExpenses,
  }) async {
    final expenses = preloadedExpenses ?? await getExpenses(fromUid);
    if (expenses.isEmpty) return 0;

    storage.putIfAbsent(toUid, () => []).addAll(expenses);
    if (deleteSource) {
      storage.remove(fromUid);
    }
    return expenses.length;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('AuthProvider Guest Migration', () {
    test('migrateGuestData transfers guest transactions to permanent user dynamically', () async {
      final mockRepo = MockMigrationRepository();
      final date = DateTime(2026, 10, 15);

      mockRepo.storage['guest-1'] = [
        Expense(
          id: '1',
          title: 'Guest Meal',
          category: 'Food',
          amountCents: 15000,
          date: date,
        ),
        Expense(
          id: '2',
          title: 'Guest Salary',
          category: 'Salary',
          amountCents: 5000000,
          date: date,
          isIncome: true,
        ),
      ];

      final auth = AuthProvider(expenseRepository: mockRepo);
      addTearDown(auth.dispose);

      final count = await auth.migrateGuestData(
        guestUid: 'guest-1',
        permanentUid: 'perm-1',
      );

      expect(count, 2);
      expect(mockRepo.fetchCount, 1);
      expect(mockRepo.storage['perm-1']?.length, 2);
      expect(mockRepo.storage['perm-1']?[0].title, 'Guest Meal');
      expect(mockRepo.storage['perm-1']?[1].title, 'Guest Salary');
    });

    test(
      'migrateGuestData uses preloadedExpenses without fetching again',
      () async {
        final mockRepo = MockMigrationRepository();
        final date = DateTime(2026, 10, 15);
        final preloaded = [
          Expense(
            id: 'p-1',
            title: 'Preloaded Coffee',
            category: 'Food',
            amountCents: 20000,
            date: date,
          ),
        ];

        final auth = AuthProvider(expenseRepository: mockRepo);
        addTearDown(auth.dispose);

        final count = await auth.migrateGuestData(
          guestUid: 'guest-1',
          permanentUid: 'perm-1',
          preloadedExpenses: preloaded,
        );

        expect(count, 1);
        expect(mockRepo.fetchCount, 0); // Didn't call getExpenses
        expect(mockRepo.storage['perm-1']?.length, 1);
        expect(mockRepo.storage['perm-1']?.first.title, 'Preloaded Coffee');
      },
    );

    test(
      'migrateGuestData handles empty or identical UIDs gracefully',
      () async {
        final mockRepo = MockMigrationRepository();
        final auth = AuthProvider(expenseRepository: mockRepo);
        addTearDown(auth.dispose);

        expect(
          await auth.migrateGuestData(guestUid: '', permanentUid: 'perm-1'),
          0,
        );
        expect(
          await auth.migrateGuestData(guestUid: 'guest-1', permanentUid: ''),
          0,
        );
        expect(
          await auth.migrateGuestData(guestUid: 'same', permanentUid: 'same'),
          0,
        );
      },
    );

    test('migrateGuestData returns 0 when source has no records', () async {
      final mockRepo = MockMigrationRepository();
      final auth = AuthProvider(expenseRepository: mockRepo);
      addTearDown(auth.dispose);

      final count = await auth.migrateGuestData(
        guestUid: 'empty-guest',
        permanentUid: 'perm-1',
      );
      expect(count, 0);
      expect(mockRepo.storage['perm-1'], isNull);
    });
  });
}
