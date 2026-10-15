import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:expense_tracker/models/expense.dart';
import 'package:expense_tracker/services/repositories/expense_repository.dart';

void main() {
  group('FirestoreExpenseRepository', () {
    late FakeFirebaseFirestore fakeFirestore;
    late FirestoreExpenseRepository repository;

    setUp(() {
      fakeFirestore = FakeFirebaseFirestore();
      repository = FirestoreExpenseRepository(firestore: fakeFirestore);
    });

    test('saveExpense writes native Timestamp and integer amountCents to Firestore', () async {
      final date = DateTime(2026, 10, 15, 14, 30);
      final expense = Expense(
        id: '',
        title: 'Momo & Chai',
        category: 'Food',
        amountCents: 25000,
        date: date,
        note: 'Afternoon snack',
      );

      await repository.saveExpense('user-1', expense);

      final snapshot = await fakeFirestore
          .collection('users')
          .doc('user-1')
          .collection('expenses')
          .get();

      expect(snapshot.docs.length, 1);
      final docData = snapshot.docs.first.data();

      expect(docData['title'], 'Momo & Chai');
      expect(docData['category'], 'Food');
      expect(docData['amountCents'], 25000);
      expect(docData['amountCents'], isA<int>());
      expect(docData['date'], isA<Timestamp>());
      expect((docData['date'] as Timestamp).toDate(), date);
      expect(docData['type'], 'expense');
      expect(docData['note'], 'Afternoon snack');
    });

    test(
      'updateExpense preserves existing document id and updates fields',
      () async {
        final initial = Expense(
          id: 'exp-123',
          title: 'Old Title',
          category: 'Other',
          amountCents: 10000,
          date: DateTime(2026, 10, 1),
        );
        await repository.saveExpense('user-1', initial);

        final updated = Expense(
          id: 'exp-123',
          title: 'New Title',
          category: 'Bills',
          amountCents: 15000,
          date: DateTime(2026, 10, 2),
        );
        await repository.saveExpense('user-1', updated);

        final doc = await fakeFirestore
            .collection('users')
            .doc('user-1')
            .collection('expenses')
            .doc('exp-123')
            .get();

        expect(doc.data()!['title'], 'New Title');
        expect(doc.data()!['category'], 'Bills');
        expect(doc.data()!['amountCents'], 15000);
        expect(doc.data()!['date'], isA<Timestamp>());
      },
    );

    test('deleteExpense removes specified document', () async {
      final e1 = Expense(
        id: 'doc-1',
        title: 'Taxi',
        category: 'Transport',
        amountCents: 50000,
        date: DateTime.now(),
      );
      await repository.saveExpense('user-1', e1);

      expect((await repository.getExpenses('user-1')).length, 1);

      await repository.deleteExpense('user-1', 'doc-1');
      expect((await repository.getExpenses('user-1')).length, 0);
    });

    test('deleteAllExpenses wipes all user records in batch', () async {
      for (int i = 0; i < 5; i++) {
        await repository.saveExpense(
          'user-1',
          Expense(
            id: 'item-$i',
            title: 'Expense $i',
            category: 'Food',
            amountCents: 1000 * (i + 1),
            date: DateTime.now(),
          ),
        );
      }

      expect((await repository.getExpenses('user-1')).length, 5);

      await repository.deleteAllExpenses('user-1');
      expect((await repository.getExpenses('user-1')).length, 0);
    });

    test('migrateExpenses transfers all transactions from guest UID to permanent UID', () async {
      const guestUid = 'guest-abc';
      const permUid = 'perm-xyz';

      // Save 3 guest transactions
      final date1 = DateTime(2026, 10, 10);
      final date2 = DateTime(2026, 10, 11);
      final date3 = DateTime(2026, 10, 12);

      await repository.saveExpense(
        guestUid,
        Expense(
          id: '',
          title: 'Guest Grocery',
          category: 'Food',
          amountCents: 350000,
          date: date1,
        ),
      );
      await repository.saveExpense(
        guestUid,
        Expense(
          id: '',
          title: 'Guest Salary',
          category: 'Salary',
          amountCents: 8000000,
          date: date2,
          isIncome: true,
        ),
      );
      await repository.saveExpense(
        guestUid,
        Expense(
          id: '',
          title: 'Guest Bus',
          category: 'Transport',
          amountCents: 2500,
          date: date3,
        ),
      );

      final migratedCount = await repository.migrateExpenses(
        fromUid: guestUid,
        toUid: permUid,
        deleteSource: true,
      );

      expect(migratedCount, 3);

      final permExpenses = await repository.getExpenses(permUid);
      expect(permExpenses.length, 3);

      // Verify records in target collection
      final titles = permExpenses.map((e) => e.title).toSet();
      expect(
        titles,
        containsAll(['Guest Grocery', 'Guest Salary', 'Guest Bus']),
      );

      // Verify date Timestamp serialization in Firestore
      final permDocs = await fakeFirestore
          .collection('users')
          .doc(permUid)
          .collection('expenses')
          .get();

      for (final doc in permDocs.docs) {
        expect(doc.data()['date'], isA<Timestamp>());
        expect(doc.data()['amountCents'], isA<int>());
      }

      // Verify source collection was cleaned up
      final guestRemaining = await repository.getExpenses(guestUid);
      expect(guestRemaining, isEmpty);
    });
  });
}
