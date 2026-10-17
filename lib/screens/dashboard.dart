import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:nepali_utils/nepali_utils.dart';
import 'package:provider/provider.dart';

import '../models/expense.dart';
import '../providers/auth_provider.dart';
import '../providers/expense_provider.dart';
import '../providers/locale_provider.dart';
import '../theme.dart';
import 'expense_editor.dart';
import 'report_dialog.dart';
import 'settings_screen.dart';
import 'spending_stories.dart';
import '../models/calendar_period.dart';

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
  static const titles = ['Overview', 'Transactions', 'Insights', 'Settings'];
  @override
  void dispose() {
    search.dispose();
    super.dispose();
  }

  Future<void> edit(
    ExpenseProvider p, [
    Expense? e,
    bool income = false,
  ]) async {
    final saved = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => ExpenseEditor(provider: p, expense: e, income: income),
    );
    if (saved == true && mounted) message('Transaction saved successfully.');
  }

  void message(String text) => ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(text), behavior: SnackBarBehavior.floating),
  );
  Future<void> remove(ExpenseProvider p, Expense e) async {
    final yes = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Delete this transaction?'),
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
      if (mounted) message('Transaction deleted.');
    } catch (_) {
      if (mounted) message('Could not delete. Please try again.');
    }
  }

  Future<void> export(ExpenseProvider p) async {
    showDialog<void>(
      context: context,
      builder: (_) => ReportDialog(expenseProvider: p),
    );
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
                NavigationDestination(
                  icon: Icon(Icons.settings_outlined),
                  label: 'Settings',
                ),
              ],
            ),
      body: SafeArea(
        child: Row(
          children: [
            if (wide)
              Container(
                width: 260,
                color: context.appSurface,
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Icon(
                          Icons.account_balance_wallet_rounded,
                          color: context.appAccent,
                          size: 30,
                        ),
                        const SizedBox(width: 10),
                        const Text(
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
                    Text(
                      'YOUR MONEY, MADE CLEAR',
                      style: TextStyle(
                        fontSize: 10,
                        letterSpacing: 1.5,
                        color: context.appMuted,
                      ),
                    ),
                    const SizedBox(height: 48),
                    ...List.generate(
                      titles.length,
                      (i) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Material(
                          color: Colors.transparent,
                          child: ListTile(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            selected: page == i,
                            selectedTileColor: context.palette.primaryContainer,
                            selectedColor: context.appAccent,
                            leading: Icon(
                              [
                                Icons.space_dashboard_outlined,
                                Icons.receipt_long_outlined,
                                Icons.bar_chart_rounded,
                                Icons.settings_outlined,
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
                        color: context.palette.primaryContainer,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.lightbulb_outline,
                            color: context.appAccent,
                          ),
                          const SizedBox(height: 10),
                          const Text(
                            'Make every rupee count',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Log the small things. Understand the bigger picture.',
                            style: TextStyle(
                              color: context.appMuted,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Personal expense tracker',
                      style: TextStyle(fontSize: 11, color: context.appMuted),
                    ),
                  ],
                ),
              ),
            Expanded(
              child: Column(
                children: [
                  Container(
                    color: context.appSurface,
                    padding: EdgeInsets.symmetric(
                      horizontal: wide ? 36 : 18,
                      vertical: 14,
                    ),
                    child: Row(
                      children: [
                        if (!wide) ...[
                          Icon(
                            Icons.account_balance_wallet_rounded,
                            color: context.appAccent,
                          ),
                          const SizedBox(width: 10),
                        ],
                        Text(
                          titles[page],
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        const Spacer(),
                        if (wide) ...[
                          FilledButton.tonalIcon(
                            onPressed: () => showDialog<void>(
                              context: context,
                              builder: (_) => ReportDialog(expenseProvider: p),
                            ),
                            icon: const Icon(
                              Icons.summarize_outlined,
                              size: 16,
                            ),
                            label: const Text('Share Report'),
                          ),
                          const SizedBox(width: 14),
                        ] else ...[
                          IconButton(
                            tooltip: 'Share Report',
                            icon: const Icon(Icons.summarize_outlined),
                            onPressed: () => showDialog<void>(
                              context: context,
                              builder: (_) => ReportDialog(expenseProvider: p),
                            ),
                          ),
                        ],
                        if (wide) ...[
                          Icon(
                            Icons.lock_outline,
                            size: 15,
                            color: context.appMuted,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Personal account',
                            style: TextStyle(
                              color: context.appMuted,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(width: 10),
                        ],
                        if (wide) ...[
                          IconButton(
                            tooltip:
                                context.watch<LocaleProvider?>()?.isNepali == true
                                    ? 'Switch to English'
                                    : 'नेपालीमा बदल्नुहोस्',
                            icon: const Icon(Icons.translate_rounded),
                            onPressed: () {
                              final lp = context.read<LocaleProvider?>();
                              if (lp != null) {
                                lp.toggleLocale();
                              }
                            },
                          ),
                          const SizedBox(width: 4),
                        ],
                        PopupMenuButton<String>(
                          tooltip: 'Account',
                          icon: CircleAvatar(
                            radius: 18,
                            backgroundColor: context.palette.primaryContainer,
                            child: Icon(
                              Icons.person_outline,
                              size: 21,
                              color: context.appAccent,
                            ),
                          ),
                          itemBuilder: (_) => [
                            PopupMenuItem(
                              enabled: false,
                              child: Text(auth.user?.email ?? 'Your account'),
                            ),
                            PopupMenuItem(
                              value: 'language',
                              child: Row(
                                children: [
                                  const Icon(Icons.translate_rounded, size: 18),
                                  const SizedBox(width: 10),
                                  Text(
                                    context.watch<LocaleProvider?>()?.isNepali ==
                                            true
                                        ? 'English'
                                        : 'नेपाली (Nepali)',
                                  ),
                                ],
                              ),
                            ),
                            const PopupMenuItem(
                              value: 'settings',
                              child: Text('Settings'),
                            ),
                            const PopupMenuItem(
                              value: 'logout',
                              child: Text('Sign out'),
                            ),
                          ],
                          onSelected: (val) async {
                            if (val == 'language') {
                              final lp = context.read<LocaleProvider?>();
                              if (lp != null) {
                                await lp.toggleLocale();
                              }
                              return;
                            }
                            if (val == 'settings') {
                              setState(() => page = 3);
                              return;
                            }
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
                                          'Account & Preferences.',
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
                                          'Manage calendar, currency, and data privacy options.',
                                        ][page],
                                        style: TextStyle(
                                          color: context.appMuted,
                                        ),
                                      ),
                                    ],
                                  ),
                                  if (page != 3) ...[
                                    FilledButton.icon(
                                      onPressed: () => edit(p, null, true),
                                      icon: const Icon(
                                        Icons.add_card_outlined,
                                        size: 19,
                                      ),
                                      label: const Text('Add money'),
                                    ),
                                    OutlinedButton.icon(
                                      onPressed: () => edit(p),
                                      icon: const Icon(Icons.add, size: 19),
                                      label: const Text('Add expense'),
                                    ),
                                  ],
                                ],
                              ),
                              if (page == 3) ...[
                                const SizedBox(height: 24),
                                SettingsScreen(expenseProvider: p),
                              ] else ...[
                                const SizedBox(height: 18),
                                SegmentedButton<bool>(
                                  showSelectedIcon: false,
                                  segments: const [
                                    ButtonSegment(
                                      value: true,
                                      label: Text('Nepali (BS)'),
                                    ),
                                    ButtonSegment(
                                      value: false,
                                      label: Text('English (AD)'),
                                    ),
                                  ],
                                  selected: {p.nepali},
                                  onSelectionChanged: (value) =>
                                      p.setCalendar(value.first),
                                ),
                                const SizedBox(height: 16),
                                Row(
                                  children: [
                                    Container(
                                      decoration: BoxDecoration(
                                        color: context.appSurface,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Row(
                                        children: [
                                          IconButton(
                                            tooltip: 'Previous month',
                                            onPressed: () => p.changeMonth(-1),
                                            icon: const Icon(
                                              Icons.chevron_left,
                                            ),
                                          ),
                                          Column(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Text(
                                                p.period.label,
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                              Text(
                                                p.nepali
                                                    ? '${DateFormat.yMMMM().format(p.period.anchor)} AD'
                                                    : '${NepaliDateFormat.yMMMM().format(toBs(p.period.anchor))} BS',
                                                style: TextStyle(
                                                  fontSize: 10,
                                                  color: context.appMuted,
                                                ),
                                              ),
                                            ],
                                          ),
                                          IconButton(
                                            tooltip: 'Next month',
                                            onPressed: () => p.changeMonth(1),
                                            icon: const Icon(
                                              Icons.chevron_right,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const Spacer(),
                                    if (wide)
                                      Text(
                                        'Currency: Nepalese Rupee (NPR)',
                                        style: TextStyle(
                                          color: context.appMuted,
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
                                      nepali: p.nepali,
                                    ),
                                    const SizedBox(height: 24),
                                  ],
                                  if (page == 0 || page == 2) ...[
                                    summary(p),
                                    const SizedBox(height: 12),
                                    Text(
                                      'Monthly net: ${money(p.monthlyNet)}  |  ${p.monthlyTransactions.length} transactions',
                                      style: TextStyle(color: context.appMuted),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Starting today? Add money with the Opening balance category for the funds you already have. This is a personal ledger, not a connected bank account.',
                                      style: TextStyle(
                                        color: context.appMuted,
                                        fontSize: 12,
                                      ),
                                    ),
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
                                                  Expanded(
                                                    flex: 3,
                                                    child: chart,
                                                  ),
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
                                          Text(
                                            'Comparisons use whole calendar months. A month still in progress may have a lower total.',
                                            style: TextStyle(
                                              color: context.appMuted,
                                            ),
                                          ),
                                        ],
                                      ),
                                    )
                                  else
                                    transactions(p),
                                ],
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
                    'Recorded balance',
                    style: TextStyle(color: Colors.white70),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  money(p.balance),
                  style: const TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'All recorded income minus expenses',
                style: TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ],
          ),
        ),
        metric(
          'Money in',
          money(p.income),
          'Income for selected month',
          Icons.south_west_rounded,
        ),
        metric(
          'Money out',
          money(p.total),
          'Expenses for selected month',
          Icons.north_east_rounded,
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
              Icon(icon, size: 20, color: context.appAccent),
              const SizedBox(width: 10),
              Flexible(
                child: Text(title, style: TextStyle(color: context.appMuted)),
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
          Text(
            subtitle,
            style: TextStyle(fontSize: 12, color: context.appMuted),
          ),
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
          style: TextStyle(color: context.appMuted, fontSize: 12),
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
                      '${bsDate(p.period.day(i + 1))} (${DateFormat.MMMd().format(p.period.day(i + 1))}): ${money(days[i])}',
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: Container(
                      height: maxValue == 0
                          ? 4
                          : math.max(4, days[i] / maxValue * 155),
                      decoration: BoxDecoration(
                        color: days[i] == 0
                            ? context.appPanel
                            : context.appAccent,
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
            Text('01', style: TextStyle(color: context.appMuted, fontSize: 11)),
            Text(
              'Day of month',
              style: TextStyle(color: context.appMuted, fontSize: 11),
            ),
            Text(
              '${days.length}',
              style: TextStyle(color: context.appMuted, fontSize: 11),
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
      return SizedBox(
        height: 230,
        child: Center(
          child: Text(
            'Your categories will appear here.',
            style: TextStyle(color: context.appMuted),
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
                        style: TextStyle(fontSize: 12, color: context.appMuted),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: p.categoryTotal(c) / p.total,
                    minHeight: 6,
                    borderRadius: BorderRadius.circular(6),
                    color: categoryColor(c),
                    backgroundColor: context.appPanel,
                  ),
                ],
              ),
            ),
          )
          .toList(),
    );
  }

  Widget transactions(ExpenseProvider p) {
    final items = page == 0
        ? p.monthlyTransactions.take(5).toList()
        : p.visible;
    return panel(
      page == 0 ? 'Recent transactions' : 'Transaction history',
      Column(
        children: [
          if (page == 1) ...[
            Wrap(
              spacing: 8,
              children: ['All', 'Income', 'Expenses']
                  .map(
                    (type) => ChoiceChip(
                      label: Text(type == 'All' ? 'All transactions' : type),
                      selected: p.transactionType == type,
                      onSelected: (_) => p.setType(type),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 14),
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
              children:
                  [
                        'All',
                        ...(p.transactionType == 'Income'
                            ? incomeCategories
                            : p.transactionType == 'Expenses'
                            ? categories
                            : [...categories, ...incomeCategories]),
                      ]
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
                    style: TextStyle(color: context.appMuted),
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
                  Icon(
                    Icons.receipt_long_outlined,
                    size: 42,
                    color: context.appMuted,
                  ),
                  const SizedBox(height: 14),
                  Text(
                    page == 1 && (p.search.isNotEmpty || p.category != 'All')
                        ? 'No matching transactions'
                        : 'A fresh start for this month',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Add money or an expense, or try another month or filter.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: context.appMuted),
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
                                  '${e.category} · ${formatBsAndAdDate(e.date)}',
                                  style: TextStyle(
                                    color: context.appMuted,
                                    fontSize: 12,
                                  ),
                                ),
                                if (e.note.isNotEmpty)
                                  Text(
                                    e.note,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: context.appMuted,
                                      fontSize: 12,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              '${e.isIncome ? '+' : '-'}${money(e.amountCents)}',
                              textAlign: TextAlign.right,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                              ),
                            ),
                          ),
                          PopupMenuButton<String>(
                            tooltip: 'Transaction actions',
                            onSelected: (v) =>
                                v == 'edit' ? edit(p, e) : remove(p, e),
                            itemBuilder: (_) => [
                              const PopupMenuItem(
                                value: 'edit',
                                child: Text('Edit transaction'),
                              ),
                              const PopupMenuItem(
                                value: 'delete',
                                child: Text('Delete transaction'),
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
