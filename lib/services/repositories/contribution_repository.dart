import 'package:cloud_firestore/cloud_firestore.dart';

import '../../models/contribution.dart';

class ContributionRepository {
  final String uid;
  final FirebaseFirestore? _customFirestore;

  ContributionRepository({required this.uid, FirebaseFirestore? firestore})
    : _customFirestore = firestore;

  FirebaseFirestore get firestore =>
      _customFirestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _collection =>
      firestore.collection('users').doc(uid).collection('contributions');

  Stream<List<Contribution>> watchContributions() {
    if (uid.isEmpty) return Stream.value(const <Contribution>[]);
    return _collection
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map(Contribution.fromDoc).toList());
  }

  Future<void> saveContribution(Contribution contribution) async {
    _requireUser();
    final collection = _collection;
    if (contribution.id.isEmpty) {
      await collection.add(contribution.toMap());
    } else {
      await collection
          .doc(contribution.id)
          .set(contribution.toMap(), SetOptions(merge: true));
    }
  }

  Future<void> deleteContribution(String id) async {
    _requireUser();
    if (id.isEmpty) throw ArgumentError.value(id, 'id', 'Must not be empty');
    await _collection.doc(id).delete();
  }

  Future<void> deleteAllContributions() async {
    _requireUser();
    final snapshot = await _collection.get();
    if (snapshot.docs.isEmpty) return;

    WriteBatch batch = firestore.batch();
    var batchCount = 0;
    for (final doc in snapshot.docs) {
      batch.delete(doc.reference);
      batchCount++;
      if (batchCount == 450) {
        await batch.commit();
        batch = firestore.batch();
        batchCount = 0;
      }
    }
    if (batchCount > 0) await batch.commit();
  }

  void _requireUser() {
    if (uid.isEmpty) {
      throw StateError('A signed-in user is required to change contributions.');
    }
  }
}
