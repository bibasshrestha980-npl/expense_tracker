import 'dart:math' as math;
import 'package:cloud_firestore/cloud_firestore.dart';

class Sip {
  final String id;
  final String name;
  final int monthlyAmountCents;
  final int dayOfMonth;
  final DateTime startDate;
  final int targetMonths;
  final double expectedReturnRate;
  final String folioNumber;
  final bool active;

  const Sip({
    required this.id,
    required this.name,
    required this.monthlyAmountCents,
    required this.dayOfMonth,
    required this.startDate,
    this.targetMonths = 60,
    this.expectedReturnRate = 12.0,
    this.folioNumber = '',
    this.active = true,
  });

  factory Sip.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data()!;
    return Sip(
      id: doc.id,
      name: d['name'] as String? ?? 'Unnamed SIP',
      monthlyAmountCents: (d['monthlyAmountCents'] as num?)?.toInt() ?? 0,
      dayOfMonth: (d['dayOfMonth'] as num?)?.toInt() ?? 1,
      startDate: (d['startDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      targetMonths: (d['targetMonths'] as num?)?.toInt() ?? 60,
      expectedReturnRate: (d['expectedReturnRate'] as num?)?.toDouble() ?? 12.0,
      folioNumber: d['folioNumber'] as String? ?? '',
      active: d['active'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toMap() => {
    'name': name,
    'monthlyAmountCents': monthlyAmountCents,
    'dayOfMonth': dayOfMonth,
    'startDate': Timestamp.fromDate(startDate),
    'targetMonths': targetMonths,
    'expectedReturnRate': expectedReturnRate,
    'folioNumber': folioNumber,
    'active': active,
  };

  /// Calculates number of monthly installments elapsed from [startDate] up to [atDate]
  int elapsedInstallments([DateTime? atDate]) {
    final current = atDate ?? DateTime.now();
    if (current.isBefore(startDate)) return 0;
    int months =
        (current.year - startDate.year) * 12 +
        (current.month - startDate.month) +
        1;
    if (targetMonths > 0 && months > targetMonths) return targetMonths;
    return months > 0 ? months : 0;
  }

  /// Total invested amount in cents so far
  int totalInvestedCents([DateTime? atDate]) =>
      elapsedInstallments(atDate) * monthlyAmountCents;

  /// Future value calculation using standard compound formula:
  /// FV = P * [ ((1 + r)^n - 1) / r ] * (1 + r)
  double calculateCorpus({int? months, double? annualRate}) {
    final n = months ?? (targetMonths > 0 ? targetMonths : 60);
    final rate = (annualRate ?? expectedReturnRate) / 100.0;
    final r = rate / 12.0;
    final p = monthlyAmountCents / 100.0;
    if (r <= 0 || n <= 0) return p * n;
    return p * ((math.pow(1 + r, n) - 1) / r) * (1 + r);
  }

  /// Estimated current portfolio value based on elapsed installments and expected rate
  double currentEstimatedValue([DateTime? atDate]) {
    final n = elapsedInstallments(atDate);
    if (n <= 0) return 0.0;
    return calculateCorpus(months: n);
  }
}
