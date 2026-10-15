import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:expense_tracker/services/account_deletion_service.dart';

class MockUser extends Fake implements User {
  @override
  final String uid;

  @override
  final String? email;

  bool deleteCalled = false;
  bool reauthCalled = false;
  AuthCredential? lastCredential;
  int deleteAttempts = 0;
  bool failWithRecentLoginOnFirstTry;
  String? failWithOtherCode;

  MockUser({
    required this.uid,
    this.email = 'tester@pocket.app',
    this.failWithRecentLoginOnFirstTry = false,
    this.failWithOtherCode,
  });

  @override
  Future<void> delete() async {
    deleteAttempts++;
    if (failWithOtherCode != null) {
      throw FirebaseAuthException(code: failWithOtherCode!);
    }
    if (failWithRecentLoginOnFirstTry && deleteAttempts == 1) {
      throw FirebaseAuthException(code: 'requires-recent-login');
    }
    deleteCalled = true;
  }

  @override
  Future<UserCredential> reauthenticateWithCredential(
    AuthCredential credential,
  ) async {
    reauthCalled = true;
    lastCredential = credential;
    return FakeUserCredential();
  }
}

class FakeUserCredential extends Fake implements UserCredential {}

class MockFirebaseAuth extends Fake implements FirebaseAuth {
  User? mockCurrentUser;

  MockFirebaseAuth({this.mockCurrentUser});

  @override
  User? get currentUser => mockCurrentUser;
}

class MockStorage extends Fake implements FirebaseStorage {
  @override
  Reference ref([String? path]) => MockStorageReference();
}

class MockStorageReference extends Fake implements Reference {
  @override
  Future<ListResult> listAll() async => MockListResult();

  @override
  Future<void> delete() async {}
}

class MockListResult extends Fake implements ListResult {
  @override
  List<Reference> get items => [];

  @override
  List<Reference> get prefixes => [];
}

void main() {
  group('AccountDeletionService', () {
    late FakeFirebaseFirestore fakeFirestore;
    late MockStorage mockStorage;

    setUp(() {
      fakeFirestore = FakeFirebaseFirestore();
      mockStorage = MockStorage();
    });

    test(
      'deleteAccount throws no-current-user when auth has no user',
      () async {
        final mockAuth = MockFirebaseAuth(mockCurrentUser: null);
        final service = AccountDeletionService(
          auth: mockAuth,
          firestore: fakeFirestore,
          storage: mockStorage,
        );

        expect(
          () => service.deleteAccount(onReauthenticate: (user) async => null),
          throwsA(
            isA<FirebaseAuthException>().having(
              (e) => e.code,
              'code',
              'no-current-user',
            ),
          ),
        );
      },
    );

    test(
      'deleteFirestoreUserData purges subcollection and user document',
      () async {
        const uid = 'user-delete-test';

        // Seed parent doc and subcollection docs
        await fakeFirestore.collection('users').doc(uid).set({
          'name': 'Pocket User',
        });
        await fakeFirestore
            .collection('users')
            .doc(uid)
            .collection('expenses')
            .doc('doc-1')
            .set({'title': 'Tea', 'amountCents': 5000});
        await fakeFirestore
            .collection('users')
            .doc(uid)
            .collection('expenses')
            .doc('doc-2')
            .set({'title': 'Bus', 'amountCents': 2500});

        final service = AccountDeletionService(
          firestore: fakeFirestore,
          storage: mockStorage,
        );

        await service.deleteFirestoreUserData(uid);

        final expensesSnapshot = await fakeFirestore
            .collection('users')
            .doc(uid)
            .collection('expenses')
            .get();
        expect(expensesSnapshot.docs, isEmpty);

        final userDoc = await fakeFirestore.collection('users').doc(uid).get();
        expect(userDoc.exists, isFalse);
      },
    );

    test(
      'deleteFirestoreUserData handles large subcollection with batching',
      () async {
        const uid = 'batch-user';

        // Seed 460 documents to test batch splitting (> 450)
        for (int i = 0; i < 460; i++) {
          await fakeFirestore
              .collection('users')
              .doc(uid)
              .collection('expenses')
              .doc('item-$i')
              .set({'title': 'Item $i', 'amountCents': 1000});
        }

        final before = await fakeFirestore
            .collection('users')
            .doc(uid)
            .collection('expenses')
            .get();
        expect(before.docs.length, 460);

        final service = AccountDeletionService(
          firestore: fakeFirestore,
          storage: mockStorage,
        );

        await service.deleteFirestoreUserData(uid);

        final after = await fakeFirestore
            .collection('users')
            .doc(uid)
            .collection('expenses')
            .get();
        expect(after.docs, isEmpty);
      },
    );

    test(
      'deleteAccount executes end-to-end deletion when recent login is fresh',
      () async {
        const uid = 'fresh-user';
        final mockUser = MockUser(uid: uid);
        final mockAuth = MockFirebaseAuth(mockCurrentUser: mockUser);

        await fakeFirestore
            .collection('users')
            .doc(uid)
            .collection('expenses')
            .doc('e1')
            .set({'title': 'Rent', 'amountCents': 1500000});

        final service = AccountDeletionService(
          auth: mockAuth,
          firestore: fakeFirestore,
          storage: mockStorage,
        );

        await service.deleteAccount(onReauthenticate: (user) async => null);

        expect(mockUser.deleteCalled, isTrue);

        final remaining = await fakeFirestore
            .collection('users')
            .doc(uid)
            .collection('expenses')
            .get();
        expect(remaining.docs, isEmpty);
      },
    );

    test('deleteAccount prompts for re-authentication and succeeds when credential provided', () async {
      const uid = 'reauth-user';
      final mockUser = MockUser(uid: uid, failWithRecentLoginOnFirstTry: true);
      final mockAuth = MockFirebaseAuth(mockCurrentUser: mockUser);

      final service = AccountDeletionService(
        auth: mockAuth,
        firestore: fakeFirestore,
        storage: mockStorage,
      );

      bool reauthPrompted = false;
      final dummyCredential = FakeAuthCredential();

      await service.deleteAccount(
        onReauthenticate: (user) async {
          reauthPrompted = true;
          return dummyCredential;
        },
      );

      expect(reauthPrompted, isTrue);
      expect(mockUser.reauthCalled, isTrue);
      expect(mockUser.lastCredential, dummyCredential);
      expect(mockUser.deleteCalled, isTrue);
      expect(mockUser.deleteAttempts, 2);
    });

    test('deleteAccount throws requires-recent-login when re-authentication is cancelled', () async {
      const uid = 'cancel-user';
      final mockUser = MockUser(uid: uid, failWithRecentLoginOnFirstTry: true);
      final mockAuth = MockFirebaseAuth(mockCurrentUser: mockUser);

      final service = AccountDeletionService(
        auth: mockAuth,
        firestore: fakeFirestore,
        storage: mockStorage,
      );

      expect(
        () => service.deleteAccount(
          onReauthenticate: (user) async => null, // cancelled
        ),
        throwsA(
          isA<FirebaseAuthException>().having(
            (e) => e.code,
            'code',
            'requires-recent-login',
          ),
        ),
      );

      expect(mockUser.reauthCalled, isFalse);
      expect(mockUser.deleteCalled, isFalse);
    });

    test('deleteAccount rethrows non-recent-login auth exceptions', () async {
      const uid = 'network-err-user';
      final mockUser = MockUser(
        uid: uid,
        failWithOtherCode: 'network-request-failed',
      );
      final mockAuth = MockFirebaseAuth(mockCurrentUser: mockUser);

      final service = AccountDeletionService(
        auth: mockAuth,
        firestore: fakeFirestore,
        storage: mockStorage,
      );

      expect(
        () => service.deleteAccount(onReauthenticate: (user) async => null),
        throwsA(
          isA<FirebaseAuthException>().having(
            (e) => e.code,
            'code',
            'network-request-failed',
          ),
        ),
      );
    });
  });
}

class FakeAuthCredential extends Fake implements AuthCredential {}
