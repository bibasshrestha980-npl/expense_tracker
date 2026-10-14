import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/expense.dart';
import '../providers/auth_provider.dart';
import '../providers/expense_provider.dart';
import '../theme.dart';
import 'expense_editor.dart';
import 'spending_stories.dart';

String money(int cents) =>
    NumberFormat.currency(symbol: 'NPR ', decimalDigits: 2).format(cents / 100);

class Dashboard extends StatefulWidget {
  const Dashboard({super.key});
  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  int page = 0;
  final search = TextEditingController();
  static const titles = ['Overview', 'Transactions', 'Insights'];
  @override
  void dispose() {
    search.dispose();
    super.dispose();
  }

  Future<void> edit(ExpenseProvider p, [Expense? e]) async {
    final saved = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => ExpenseEditor(provider: p, expense: e),
    );
    if (saved == true && mounted) message('Expense saved successfully.');
  }

  void message(String text) => ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(text), behavior: SnackBarBehavior.floating),
  );
  Future<void> remove(ExpenseProvider p, Expense e) async {
    final yes = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Delete this expense?'),
        content: Text(
          '${e.title}\n${money(e.amountCents)}\n\nThis action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: const Text('Keep expense'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(c, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (yes != true) return;
    try {
      await p.delete(e.id);
      if (mounted) message('Expense deleted.');
    } catch (_) {
      if (mounted) message('Could not delete. Please try again.');
    }
  }

  Future<void> export(ExpenseProvider p) async {
    String quote(String value) => '"${value.replaceAll('"', '""')}"';
    final csv = [
      'Date,Title,Category,Amount (NPR),Note',
      ...p.visible.map(
        (e) =>
            '${DateFormat('yyyy-MM-dd').format(e.date)},${quote(e.title)},${quote(e.category)},${(e.amountCents / 100).toStringAsFixed(2)},${quote(e.note)}',
      ),
    ].join('\r\n');
    try {
      await Clipboard.setData(ClipboardData(text: csv));
      if (mounted) {
        message(
          'Filtered transactions copied as CSV. Paste into a spreadsheet.',
        );
      }
    } catch (_) {
      if (mounted) message('Clipboard unavailable. Please try again.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.watch<ExpenseProvider>();
    final auth = context.watch<AuthProvider>();
    final wide = MediaQuery.sizeOf(context).width >= 950;
    return Scaffold(
      bottomNavigationBar: wide
          ? null
          : NavigationBar(
              selectedIndex: page,
              onDestinationSelected: (i) => setState(() => page = i),
              destinations: const [
                NavigationDestination(
                  icon: Icon(Icons.space_dashboard_outlined),
                  label: 'Overview',
                ),
                NavigationDestination(
                  icon: Icon(Icons.receipt_long_outlined),
                  label: 'Transactions',
                ),
                NavigationDestination(
                  icon: Icon(Icons.bar_chart_rounded),
                  label: 'Insights',
                ),
              ],
            ),
      body: SafeArea(
        child: Row(
          children: [
            if (wide)
              Container(
                width: 260,
                color: Colors.white,
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 14),
                    const Row(
                      children: [
                        Icon(
                          Icons.account_balance_wallet_rounded,
                          color: accent,
                          size: 30,
                        ),
                        SizedBox(width: 10),
                        Text(
                          'pocket',
                          style: TextStyle(
                            fontSize: 29,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -1,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'YOUR MONEY, MADE CLEAR',
                      style: TextStyle(
                        fontSize: 10,
                        letterSpacing: 1.5,
                        color: muted,
                      ),
                    ),
                    const SizedBox(height: 48),
                    ...List.generate(
                      3,
                      (i) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Material(
                          color: Colors.transparent,
                          child: ListTile(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            selected: page == i,
                            selectedTileColor: const Color(0xffe6f3ed),
                            selectedColor: accent,
                            leading: Icon(
                              [
                                Icons.space_dashboard_outlined,
                                Icons.receipt_long_outlined,
                                Icons.bar_chart_rounded,
                              ][i],
                            ),
                            title: Text(titles[i]),
                            onTap: () => setState(() => page = i),
                          ),
                        ),
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xfff3f7f5),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.lightbulb_outline, color: accent),
                          SizedBox(height: 10),
                          Text(
                            'Make every rupee count',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          SizedBox(height: 6),
                          Text(
                            'Log the small things. Understand the bigger picture.',
                            style: TextStyle(color: muted, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Personal expense tracker',
                      style: TextStyle(fontSize: 11, color: muted),
                    ),
                  ],
                ),
              ),
            Expanded(
              child: Column(
                children: [
                  Container(
                    color: Colors.white,
                    padding: EdgeInsets.symmetric(
                      horizontal: wide ? 36 : 18,
                      vertical: 14,
                    ),
                    child: Row(
                      children: [
                        if (!wide) ...[
                          const Icon(
                            Icons.account_balance_wallet_rounded,
                            color: accent,
                          ),
                          const SizedBox(width: 10),
                        ],
                        Text(
                          titles[page],
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        const Spacer(),
                        const Icon(Icons.lock_outline, size: 15, color: muted),
                        const SizedBox(width: 6),
                        if (wide)
                          const Text(
                            'Personal account',
                            style: TextStyle(color: muted, fontSize: 12),
                          ),
                        const SizedBox(width: 10),
                        PopupMenuButton<String>(
                          tooltip: 'Account',
                          icon: const CircleAvatar(
                            radius: 18,
                            backgroundColor: Color(0xffe6f3ed),
                            child: Icon(
                              Icons.person_outline,
                              size: 21,
                              color: accent,
                            ),
                          ),
                          itemBuilder: (_) => [
                            PopupMenuItem(
                              enabled: false,
                              child: Text(auth.user?.email ?? 'Your account'),
                            ),
                            const PopupMenuItem(
                              value: 'logout',
                              child: Text('Sign out'),
                            ),
                          ],
                          onSelected: (_) async {
                            try {
                              await auth.signOut();
                            } catch (_) {
                              if (mounted) {
                                message('Sign out failed. Please try again.');
                              }
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: EdgeInsets.all(wide ? 36 : 18),
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 1200),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Wrap(
                                alignment: WrapAlignment.spaceBetween,
                                runSpacing: 18,
                                spacing: 24,
                                children: [
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        [
                                          'A little clarity. A lot of control.',
                                          'Every expense, in one place.',
                                          'Understand your spending.',
                                        ][page],
                                        style: Theme.of(context)
                                            .textTheme
                                            .headlineSmall,
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        [
                                          'Here is how your month is shaping up.',
                                          'Search, review and organize your daily spending.',
                                          'Turn your everyday expenses into useful insights.',
                                        ][page],
                                        style: const TextStyle(color: muted),
                                      ),
                                    ],
                                  ),
                                  FilledButton.icon(
                                    onPressed: () => edit(p),
                                    icon: const Icon(Icons.add, size: 19),
                                    label: const Text('Add expense'),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 26),
                              Row(
                                children: [
                                  Container(
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Row(
                                      children: [
                                        IconButton(
                                          tooltip: 'Previous month',
                                          onPressed: () => p.changeMonth(-1),
                                          icon: const Icon(Icons.chevron_left),
                                        ),
                                        Text(
                                          DateFormat.yMMMM().format(p.month),
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        IconButton(
                                          tooltip: 'Next month',
                                          onPressed: () => p.changeMonth(1),
                                          icon: const Icon(Icons.chevron_right),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const Spacer(),
                                  if (wide)
                                    const Text(
                                      'Currency: Nepalese Rupee (NPR)',
                                      style: TextStyle(
                                        color: muted,
                                        fontSize: 12,
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 24),
                              if (p.loading)
                                const Padding(
                                  padding: EdgeInsets.all(70),
                                  child: Center(
                                    child: CircularProgressIndicator(),
                                  ),
                                )
                              else if (p.error != null)
                                panel(
                                  'Unable to load your expenses',
                                  Text(p.error!),
                                )
                              else ...[
                                if (page == 2) ...[
                                  SpendingStories(
                                    expenses: p.monthly,
                                    month: p.month,
                                  ),
                                  const SizedBox(height: 24),
                                ],
                                if (page != 1) ...[
                                  summary(p),
                                  const SizedBox(height: 24),
                                  LayoutBuilder(
                                    builder: (context, box) {
                                      final chart = panel(
                                        'Daily spending',
                                        dailyChart(p),
                                      );
                                      final breakdown = panel(
                                        'Spending by category',
                                        categoryBreakdown(p),
                                      );
                                      return box.maxWidth > 750
                                          ? Row(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Expanded(flex: 3, child: chart),
                                                const SizedBox(width: 20),
                                                Expanded(
                                                  flex: 2,
                                                  child: breakdown,
                                                ),
                                              ],
                                            )
                                          : Column(
                                              children: [
                                                chart,
                                                const SizedBox(height: 20),
                                                breakdown,
                                              ],
                                            );
                                    },
                                  ),
                                  const SizedBox(height: 24),
                                ],
                                if (page == 2)
                                  panel(
                                    'Your monthly perspective',
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          p.previousTotal == 0
                                              ? 'No spending recorded last month to compare yet.'
                                              : '${money((p.total - p.previousTotal).abs())} ${p.total > p.previousTotal ? 'more' : 'less'} than last month.',
                                          style: const TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        const SizedBox(height: 10),
                                        const Text(
                                          'Comparisons use whole calendar months. A month still in progress may have a lower total.',
                                          style: TextStyle(color: muted),
                                        ),
                                      ],
                                    ),
                                  )
                                else
                                  transactions(p),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget panel(String title, Widget child, {Widget? action}) => Card(
    child: Padding(
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              ?action,
            ],
          ),
          const SizedBox(height: 22),
          child,
        ],
      ),
    ),
  );
  Widget summary(ExpenseProvider p) => LayoutBuilder(
    builder: (_, box) {
      final cards = [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xff125d50), Color(0xff21836d)],
            ),
            borderRadius: BorderRadius.circular(22),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(
                    Icons.account_balance_wallet_outlined,
                    color: Colors.white70,
                    size: 20,
                  ),
                  SizedBox(width: 10),
                  Text(
                    'Total spending',
                    style: TextStyle(color: Colors.white70),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  money(p.total),
                  style: const TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'For the selected month',
                style: TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ],
          ),
        ),
        metric(
          'Transactions',
          '${p.monthly.length}',
          'Expenses recorded',
          Icons.receipt_long_outlined,
        ),
        metric(
          'Average expense',
          money(p.monthly.isEmpty ? 0 : (p.total / p.monthly.length).round()),
          'Per transaction this month',
          Icons.stacked_line_chart,
        ),
      ];
      return box.maxWidth < 650
          ? Column(
              children: cards
                  .map(
                    (c) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: SizedBox(width: double.infinity, child: c),
                    ),
                  )
                  .toList(),
            )
          : Row(
              children: [
                Expanded(flex: 4, child: cards[0]),
                const SizedBox(width: 18),
                Expanded(flex: 3, child: cards[1]),
                const SizedBox(width: 18),
                Expanded(flex: 3, child: cards[2]),
              ],
            );
    },
  );
  Widget metric(
    String title,
    String value,
    String subtitle,
    IconData icon,
  ) => Card(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: accent),
              const SizedBox(width: 10),
              Flexible(
                child: Text(title, style: const TextStyle(color: muted)),
              ),
            ],
          ),
          const SizedBox(height: 18),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(height: 12),
          Text(subtitle, style: const TextStyle(fontSize: 12, color: muted)),
        ],
      ),
    ),
  );
  Widget dailyChart(ExpenseProvider p) {
    final days = p.dailyTotals;
    final maxValue = days.fold<int>(0, math.max);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          maxValue == 0
              ? 'Add an expense to start your spending timeline.'
              : 'Highest day: ${money(maxValue)}',
          style: const TextStyle(color: muted, fontSize: 12),
        ),
        const SizedBox(height: 24),
        SizedBox(
          height: 160,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: List.generate(
              days.length,
              (i) => Expanded(
                child: Tooltip(
                  message:
                      '${DateFormat.MMMd().format(DateTime(p.month.year, p.month.month, i + 1))}: ${money(days[i])}',
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: Container(
                      height: maxValue == 0
                          ? 4
                          : math.max(4, days[i] / maxValue * 155),
                      decoration: BoxDecoration(
                        color: days[i] == 0 ? const Color(0xffedf3f0) : accent,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(5),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('01', style: TextStyle(color: muted, fontSize: 11)),
            const Text(
              'Day of month',
              style: TextStyle(color: muted, fontSize: 11),
            ),
            Text(
              '${days.length}',
              style: const TextStyle(color: muted, fontSize: 11),
            ),
          ],
        ),
      ],
    );
  }

  Widget categoryBreakdown(ExpenseProvider p) {
    final ranked = categories.where((c) => p.categoryTotal(c) > 0).toList()
      ..sort((a, b) => p.categoryTotal(b).compareTo(p.categoryTotal(a)));
    if (ranked.isEmpty) {
      return const SizedBox(
        height: 230,
        child: Center(
          child: Text(
            'Your categories will appear here.',
            style: TextStyle(color: muted),
          ),
        ),
      );
    }
    return Column(
      children: ranked
          .map(
            (c) => Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Column(
                children: [
                  Row(
                    children: [
                      Icon(categoryIcon(c), color: categoryColor(c), size: 18),
                      const SizedBox(width: 8),
                      Expanded(child: Text(c)),
                      Text(
                        '${(p.categoryTotal(c) / p.total * 100).round()}%',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        money(p.categoryTotal(c)),
                        style: const TextStyle(fontSize: 12, color: muted),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: p.categoryTotal(c) / p.total,
                    minHeight: 6,
                    borderRadius: BorderRadius.circular(6),
                    color: categoryColor(c),
                    backgroundColor: const Color(0xfff0f3f4),
                  ),
                ],
              ),
            ),
          )
          .toList(),
    );
  }

  Widget transactions(ExpenseProvider p) {
    final items = page == 0 ? p.monthly.take(5).toList() : p.visible;
    return panel(
      page == 0 ? 'Recent transactions' : 'Transaction history',
      Column(
        children: [
          if (page == 1) ...[
            TextField(
              controller: search,
              onChanged: p.find,
              decoration: InputDecoration(
                hintText: 'Search title or note',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: IconButton(
                  tooltip: 'Clear search',
                  onPressed: () {
                    search.clear();
                    p.find('');
                  },
                  icon: const Icon(Icons.close, size: 18),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: ['All', ...categories]
                  .map(
                    (c) => ChoiceChip(
                      label: Text(c),
                      selected: p.category == c,
                      onSelected: (_) => p.filter(c),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${items.length} results',
                    style: const TextStyle(color: muted),
                  ),
                ),
                DropdownButton<String>(
                  value: p.sort,
                  underline: const SizedBox(),
                  items:
                      [
                            'Newest first',
                            'Oldest first',
                            'Highest amount',
                            'Lowest amount',
                          ]
                          .map(
                            (v) => DropdownMenuItem(
                              value: v,
                              child: Text(
                                v,
                                style: const TextStyle(fontSize: 13),
                              ),
                            ),
                          )
                          .toList(),
                  onChanged: (v) => p.setSort(v!),
                ),
              ],
            ),
            const Divider(),
          ],
          if (items.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 36),
              child: Column(
                children: [
                  const Icon(
                    Icons.receipt_long_outlined,
                    size: 42,
                    color: muted,
                  ),
                  const SizedBox(height: 14),
                  Text(
                    page == 1 && (p.search.isNotEmpty || p.category != 'All')
                        ? 'No matching expenses'
                        : 'A fresh start for this month',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Add an expense or try another month or filter.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: muted),
                  ),
                ],
              ),
            )
          else
            ...items.map(
              (e) => Column(
                children: [
                  InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () => edit(p, e),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      child: Row(
                        children: [
                          Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              color: categoryColor(e.category)
                                  .withValues(alpha: .12),
                              borderRadius: BorderRadius.circular(13),
                            ),
                            child: Icon(
                              categoryIcon(e.category),
                              color: categoryColor(e.category),
                              size: 21,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  e.title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  '${e.category} · ${DateFormat.MMMd().format(e.date)}',
                                  style: const TextStyle(
                                    color: muted,
                                    fontSize: 12,
                                  ),
                                ),
                                if (e.note.isNotEmpty)
                                  Text(
                                    e.note,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: muted,
                                      fontSize: 12,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              money(e.amountCents),
                              textAlign: TextAlign.right,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                              ),
                            ),
                          ),
                          PopupMenuButton<String>(
                            tooltip: 'Expense actions',
                            onSelected: (v) =>
                                v == 'edit' ? edit(p, e) : remove(p, e),
                            itemBuilder: (_) => const [
                              PopupMenuItem(
                                value: 'edit',
                                child: Text('Edit expense'),
                              ),
                              PopupMenuItem(
                                value: 'delete',
                                child: Text('Delete expense'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const Divider(height: 1),
                ],
              ),
            ),
        ],
      ),
      action: page == 0
          ? TextButton(
              onPressed: () => setState(() => page = 1),
              child: const Text('View all'),
            )
          : IconButton(
              tooltip: 'Copy filtered transactions as CSV',
              onPressed: p.visible.isEmpty ? null : () => export(p),
              icon: const Icon(Icons.copy_all_outlined),
            ),
    );
  }
}
