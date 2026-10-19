import 'package:cloud_firestore/cloud_firestore.dart';

const contributionTypes = [
  'Commit',
  'Pull request',
  'Issue',
  'Code review',
  'Discussion',
  'Sponsorship',
  'Other',
];

class Contribution {
  final String id;
  final String title;
  final String repository;
  final String type;
  final String note;
  final DateTime date;

  const Contribution({
    required this.id,
    required this.title,
    required this.repository,
    required this.type,
    required this.date,
    this.note = '',
  });

  factory Contribution.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) =>
      Contribution.fromMap(doc.id, doc.data() ?? {});

  factory Contribution.fromMap(String id, Map<String, dynamic> data) {
    final rawDate = data['date'];
    final date = switch (rawDate) {
      Timestamp timestamp => timestamp.toDate(),
      String value => DateTime.tryParse(value) ?? DateTime.now(),
      int value => DateTime.fromMillisecondsSinceEpoch(value),
      _ => DateTime.now(),
    };

    return Contribution(
      id: id,
      title: data['title'] as String? ?? '',
      repository: data['repository'] as String? ?? '',
      type: contributionTypes.contains(data['type'])
          ? data['type'] as String
          : 'Other',
      date: date,
      note: data['note'] as String? ?? '',
    );
  }

  Map<String, dynamic> toMap() => {
    'title': title,
    'repository': repository,
    'type': type,
    'date': Timestamp.fromDate(date),
    'note': note,
  };
}
