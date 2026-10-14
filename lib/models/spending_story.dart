import 'expense.dart';

/// Descriptive calculations over recorded transactions, never predictions.
class SpendingStory {
  final List<Expense> expenses;
  SpendingStory(this.expenses);
  int get total => expenses.fold(0, (sum, e) => sum + e.amountCents);
  int categoryTotal(String category) => expenses
      .where((e) => e.category == category)
      .fold(0, (sum, e) => sum + e.amountCents);
  String? get leadingCategory {
    if (expenses.isEmpty) return null;
    return (categories.toList()
          ..sort((a, b) => categoryTotal(b).compareTo(categoryTotal(a))))
        .first;
  }

  int get activeDays => expenses
      .map((e) => DateTime(e.date.year, e.date.month, e.date.day))
      .toSet()
      .length;
  List<List<Expense>> get repeatedTitles {
    final groups = <String, List<Expense>>{};
    for (final e in expenses) {
      final key = e.title.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
      groups.putIfAbsent(key, () => []).add(e);
    }
    return groups.values.where((g) => g.length >= 2).toList()
      ..sort((a, b) => b.length.compareTo(a.length));
  }

  int hypotheticalReduction(String category, int percent) =>
      (categoryTotal(category) * percent.clamp(0, 100) / 100).round();
}
