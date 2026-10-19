import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:expense_tracker/models/contribution.dart';
import 'package:expense_tracker/services/repositories/contribution_repository.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ContributionRepository', () {
    late FakeFirebaseFirestore firestore;
    late ContributionRepository repository;

    setUp(() {
      firestore = FakeFirebaseFirestore();
      repository = ContributionRepository(uid: 'user-1', firestore: firestore);
    });

    test('saves contribution activity with a Firestore timestamp', () async {
      final contribution = Contribution(
        id: '',
        title: 'Fix documentation',
        repository: 'owner/project',
        type: 'Pull request',
        date: DateTime(2026, 10, 15),
        note: 'Clarified setup steps',
      );

      await repository.saveContribution(contribution);

      final snapshot = await firestore
          .collection('users')
          .doc('user-1')
          .collection('contributions')
          .get();
      expect(snapshot.docs, hasLength(1));
      final data = snapshot.docs.single.data();
      expect(data['title'], 'Fix documentation');
      expect(data['repository'], 'owner/project');
      expect(data['type'], 'Pull request');
      expect(data['date'], isA<Timestamp>());
      expect((data['date'] as Timestamp).toDate(), DateTime(2026, 10, 15));
      expect(data['note'], 'Clarified setup steps');
    });

    test(
      'updates saved contribution and delete removes it from the count',
      () async {
        await repository.saveContribution(
          Contribution(
            id: 'contribution-1',
            title: 'Old title',
            repository: '',
            type: 'Commit',
            date: DateTime(2026, 10, 15),
          ),
        );
        await repository.saveContribution(
          Contribution(
            id: 'contribution-1',
            title: 'Updated title',
            repository: 'owner/project',
            type: 'Issue',
            date: DateTime(2026, 10, 16),
          ),
        );

        final contributions = await repository.watchContributions().first;
        expect(contributions, hasLength(1));
        expect(contributions.single.title, 'Updated title');
        expect(contributions.single.type, 'Issue');

        await repository.deleteContribution('contribution-1');
        expect(await repository.watchContributions().first, isEmpty);
      },
    );

    test('deleteAllContributions clears every saved activity', () async {
      for (var index = 0; index < 4; index++) {
        await repository.saveContribution(
          Contribution(
            id: 'contribution-$index',
            title: 'Activity $index',
            repository: 'owner/project-$index',
            type: contributionTypes[index],
            date: DateTime(2026, 10, 15),
          ),
        );
      }

      await repository.deleteAllContributions();

      expect(await repository.watchContributions().first, isEmpty);
    });

    test('writes require a user and deletion requires an id', () async {
      final anonymousRepository = ContributionRepository(uid: '');
      final contribution = Contribution(
        id: '',
        title: 'Activity',
        repository: '',
        type: 'Commit',
        date: DateTime(2026, 10, 15),
      );

      await expectLater(
        anonymousRepository.saveContribution(contribution),
        throwsStateError,
      );
      await expectLater(repository.deleteContribution(''), throwsArgumentError);
    });
  });
}
