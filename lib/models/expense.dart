import 'package:cloud_firestore/cloud_firestore.dart';

const categories = [
  'Food',
  'Transport',
  'Shopping',
  'Bills',
  'Health',
  'Education',
  'Other',
];
const incomeCategories = [
  'Salary',
  'Freelance',
  'Allowance',
  'Gift',
  'Refund',
  'Opening balance',
  'Other income',
];

class Expense {
  final String id, title, category, note;
  final int amountCents;
  final DateTime date;
  final bool isIncome;
  const Expense({
    required this.id,
    required this.title,
    required this.category,
    required this.amountCents,
    required this.date,
    this.note = '',
    this.isIncome = false,
  });
  factory Expense.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) =>
      Expense.fromMap(doc.id, doc.data() ?? {});

  factory Expense.fromMap(String id, Map<String, dynamic> d) {
    final rawDate = d['date'];
    final DateTime resolvedDate;
    if (rawDate is Timestamp) {
      resolvedDate = rawDate.toDate();
    } else if (rawDate is String) {
      resolvedDate = DateTime.tryParse(rawDate) ?? DateTime.now();
    } else if (rawDate is int) {
      resolvedDate = DateTime.fromMillisecondsSinceEpoch(rawDate);
    } else {
      resolvedDate = DateTime.now();
    }
    return Expense(
      id: id,
      title: d['title'] as String? ?? '',
      category: d['category'] as String? ?? 'Other',
      amountCents: (d['amountCents'] as num?)?.toInt() ?? 0,
      date: resolvedDate,
      note: d['note'] as String? ?? '',
      isIncome: d['type'] == 'income',
    );
  }

  Map<String, dynamic> toMap() => {
    'title': title,
    'category': category,
    'amountCents': amountCents,
    'date': Timestamp.fromDate(date),
    'note': note,
    'type': isIncome ? 'income' : 'expense',
  };
}

int? parseAmount(String input) {
  if (!RegExp(r'^\d+(\.\d{1,2})?$').hasMatch(input.trim())) return null;
  final parts = input.trim().split('.');
  final whole = int.tryParse(parts[0]);
  if (whole == null || whole > 999999999) return null;
  final cents =
      whole * 100 +
      (parts.length == 2 ? int.parse(parts[1].padRight(2, '0')) : 0);
  return cents > 0 ? cents : null;
}
