import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:expense_tracker/models/expense.dart';
import 'package:expense_tracker/models/spending_story.dart';
import 'package:expense_tracker/screens/spending_stories.dart';
import 'package:expense_tracker/theme.dart';

void main() {
  final expenses = [
    Expense(
      id: 'a',
      title: ' Coffee ',
      category: 'Food',
      amountCents: 10000,
      date: DateTime(2026, 10, 1),
    ),
    Expense(
      id: 'b',
      title: 'coffee',
      category: 'Food',
      amountCents: 15000,
      date: DateTime(2026, 10, 2),
    ),
    Expense(
      id: 'c',
      title: 'Bus',
      category: 'Transport',
      amountCents: 5000,
      date: DateTime(2026, 10, 2),
    ),
  ];
  test(
    'Stories group normalized titles and calculate category-only scenarios',
    () {
      final story = SpendingStory(expenses);
      expect(story.total, 30000);
      expect(story.leadingCategory, 'Food');
      expect(story.activeDays, 2);
      expect(story.repeatedTitles.single.length, 2);
      expect(story.hypotheticalReduction('Food', 20), 5000);
      expect(story.hypotheticalReduction('Bills', 20), 0);
      expect(story.hypotheticalReduction('Food', 200), 25000);
      expect(SpendingStory([]).leadingCategory, isNull);
      expect(SpendingStory([]).activeDays, 0);
    },
  );
  testWidgets('Journal calendar and scenario controls work on a phone', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        theme: pocketTheme(),
        home: Scaffold(
          body: SingleChildScrollView(
            child: SpendingStories(
              expenses: expenses,
              month: DateTime(2026, 10),
            ),
          ),
        ),
      ),
    );
    await tester.ensureVisible(find.text('1').first);
    await tester.tap(find.text('1').first);
    await tester.pumpAndSettle();
    expect(find.textContaining('October 1, 2026'), findsOneWidget);
    await tester.ensureVisible(find.byType(Slider));
    await tester.tap(find.byType(Slider));
    await tester.pumpAndSettle();
    expect(find.text('50% less on Food'), findsOneWidget);
    await tester.ensureVisible(find.text('Reset experiment'));
    await tester.tap(find.text('Reset experiment'));
    await tester.pumpAndSettle();
    expect(find.text('10% less on Food'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
