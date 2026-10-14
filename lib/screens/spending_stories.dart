import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/expense.dart';
import '../models/calendar_period.dart';
import '../models/spending_story.dart';
import '../theme.dart';
import 'calendar_details.dart';

String _cash(int cents) =>
    NumberFormat.currency(symbol: 'NPR ', decimalDigits: 2).format(cents / 100);

class SpendingStories extends StatefulWidget {
  final List<Expense> expenses;
  final DateTime month;
  final bool nepali;
  const SpendingStories({
    super.key,
    required this.expenses,
    required this.month,
    this.nepali = false,
  });
  @override
  State<SpendingStories> createState() => _SpendingStoriesState();
}

class _SpendingStoriesState extends State<SpendingStories> {
  String category = 'Food';
  int percent = 10;
  int? selectedDay;
  @override
  void didUpdateWidget(covariant SpendingStories oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.month != widget.month || oldWidget.nepali != widget.nepali) {
      selectedDay = null;
    }
  }

  Widget card(String number, String title, Widget child) => Card(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            number,
            style: const TextStyle(
              color: accent,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 8),
          Text(title, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 18),
          child,
        ],
      ),
    ),
  );
  @override
  Widget build(BuildContext context) {
    final story = SpendingStory(widget.expenses);
    final lead = story.leadingCategory;
    final repeated = story.repeatedTitles;
    final reduction = story.hypotheticalReduction(category, percent);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: const Color(0xff202f32),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.auto_stories_outlined, color: Color(0xffc9e6b4)),
                  SizedBox(width: 12),
                  Flexible(
                    child: Text(
                      'THE POCKET JOURNAL',
                      style: TextStyle(
                        color: Color(0xffc9e6b4),
                        fontSize: 11,
                        letterSpacing: 2,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              const Text(
                'Your money has a story.',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -.7,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                lead == null
                    ? 'Your first expense is the first page. Add a transaction to see your story take shape.'
                    : '$lead takes the largest share this month: ${(story.categoryTotal(lead) / story.total * 100).round()}% of your recorded spending, across ${story.activeDays} days with entries.',
                style: const TextStyle(color: Color(0xffd0dddd), height: 1.6),
              ),
              const SizedBox(height: 18),
              const Text(
                'Based only on the expenses you record. No external AI service.',
                style: TextStyle(color: Color(0xffa5b8b5), fontSize: 11),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        card(
          '01 / SPENDING RHYTHM',
          'A month in little moments',
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Tap a day to see its expenses. Darker tiles mean more recorded spending.',
                style: TextStyle(color: muted),
              ),
              const SizedBox(height: 20),
              calendar(),
              const SizedBox(height: 14),
              const Text(
                'An empty tile means no entry, not necessarily no spending.',
                style: TextStyle(color: muted, fontSize: 11),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        card(
          '02 / THE REPEAT EDIT',
          'Small things, seen together',
          repeated.isEmpty
              ? const Text(
                  'When the same expense title appears more than once in this month, it will show here. These are repeated entries, not detected subscriptions.',
                  style: TextStyle(color: muted),
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Matching titles in this month. These may be separate purchases, not subscriptions.',
                      style: TextStyle(color: muted, fontSize: 12),
                    ),
                    const SizedBox(height: 14),
                    ...repeated
                        .take(4)
                        .map(
                          (group) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: const Color(0xfff2eee6),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(
                                    Icons.repeat,
                                    size: 20,
                                    color: Color(0xff9a7850),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        group.first.title,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      Text(
                                        '${group.length} entries this month',
                                        style: const TextStyle(
                                          color: muted,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Flexible(
                                  child: Text(
                                    _cash(
                                      group.fold(
                                        0,
                                        (sum, e) => sum + e.amountCents,
                                      ),
                                    ),
                                    textAlign: TextAlign.right,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                  ],
                ),
        ),
        const SizedBox(height: 20),
        card(
          '03 / WHAT-IF STUDIO',
          'Try a different version of this month',
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Explore how a smaller category total would change your recorded spending. This is a calculation, not a prediction or a saved budget.',
                style: TextStyle(color: muted),
              ),
              const SizedBox(height: 20),
              DropdownButtonFormField<String>(
                initialValue: category,
                decoration: const InputDecoration(
                  labelText: 'Explore a category',
                ),
                items: categories
                    .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                    .toList(),
                onChanged: (value) => setState(() => category = value!),
              ),
              const SizedBox(height: 18),
              Text(
                '$percent% less on $category',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Slider(
                value: percent.toDouble(),
                min: 0,
                max: 100,
                divisions: 20,
                label: '$percent%',
                onChanged: (value) => setState(() => percent = value.round()),
              ),
              Wrap(
                spacing: 32,
                runSpacing: 16,
                children: [
                  result(
                    'Recorded in $category',
                    _cash(story.categoryTotal(category)),
                  ),
                  result('Hypothetical difference', _cash(reduction)),
                  result(
                    'Revised monthly total',
                    _cash(story.total - reduction),
                  ),
                ],
              ),
              if (story.categoryTotal(category) == 0)
                const Padding(
                  padding: EdgeInsets.only(top: 16),
                  child: Text(
                    'No expenses in this category for this month. Choose another category to explore.',
                    style: TextStyle(color: muted),
                  ),
                ),
              const SizedBox(height: 16),
              TextButton.icon(
                onPressed: () => setState(() {
                  category = 'Food';
                  percent = 10;
                }),
                icon: const Icon(Icons.restart_alt),
                label: const Text('Reset experiment'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget result(String label, String value) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: const TextStyle(color: muted, fontSize: 12)),
      const SizedBox(height: 6),
      Text(
        value,
        style: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: accent,
        ),
      ),
    ],
  );
  Widget calendar() {
    final period = CalendarPeriod(widget.month, nepali: widget.nepali);
    final count = period.days;
    final offset = widget.nepali
        ? period.start.weekday % 7
        : period.start.weekday - 1;
    final totals = List.generate(
      count,
      (i) => widget.expenses
          .where((e) => period.dayNumber(e.date) == i + 1)
          .fold<int>(0, (sum, e) => sum + e.amountCents),
    );
    final peak = totals.fold<int>(0, (a, b) => a > b ? a : b);
    final entries = widget.expenses
        .where((e) => period.dayNumber(e.date) == selectedDay)
        .toList();
    final now = DateTime.now();
    return Column(
      children: [
        Row(
          children:
              (widget.nepali
                      ? ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat']
                      : ['M', 'T', 'W', 'T', 'F', 'S', 'S'])
                  .map(
                    (day) => Expanded(
                      child: Center(
                        child: Text(
                          day,
                          style: const TextStyle(color: muted, fontSize: 12),
                        ),
                      ),
                    ),
                  )
                  .toList(),
        ),
        const SizedBox(height: 10),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: offset + count,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            crossAxisSpacing: 6,
            mainAxisSpacing: 6,
            mainAxisExtent: 42,
          ),
          itemBuilder: (_, index) {
            if (index < offset) return const SizedBox();
            final day = index - offset + 1;
            final amount = totals[day - 1];
            final future = period
                .day(day)
                .isAfter(DateTime(now.year, now.month, now.day));
            return Tooltip(
              message:
                  '${DateFormat.MMMd().format(period.day(day))}: ${_cash(amount)} recorded',
              child: Semantics(
                button: true,
                selected: selectedDay == day,
                label: 'Day $day, ${_cash(amount)} recorded',
                child: InkWell(
                  onTap: () => setState(() => selectedDay = day),
                  borderRadius: BorderRadius.circular(9),
                  child: Container(
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: amount == 0
                          ? const Color(0xfff2f5f4)
                          : Color.lerp(
                              const Color(0xffb6dfcc),
                              accent,
                              peak == 0 ? 0 : amount / peak,
                            ),
                      borderRadius: BorderRadius.circular(9),
                      border: selectedDay == day
                          ? Border.all(color: ink, width: 2)
                          : null,
                    ),
                    child: Text(
                      '$day',
                      style: TextStyle(
                        fontSize: 12,
                        color: amount > peak / 2 && amount > 0
                            ? Colors.white
                            : future
                            ? const Color(0xff9faeaa)
                            : ink,
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
        if (widget.nepali)
          CalendarDetails(
            year: toBs(period.start).year,
            month: toBs(period.start).month,
            day: selectedDay,
          ),
        if (selectedDay != null)
          Container(
            width: double.infinity,
            margin: const EdgeInsets.only(top: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xfff6f8f7),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${DateFormat.yMMMMd().format(period.day(selectedDay!))} / ${bsDate(period.day(selectedDay!))}',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                if (entries.isEmpty)
                  const Text(
                    'No expenses recorded for this day.',
                    style: TextStyle(color: muted),
                  )
                else
                  ...entries.map(
                    (e) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Wrap(
                        spacing: 12,
                        children: [
                          Text(e.title),
                          Text(
                            _cash(e.amountCents),
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}
