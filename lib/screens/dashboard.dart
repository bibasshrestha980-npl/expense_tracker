import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:nepali_utils/nepali_utils.dart';
import 'package:provider/provider.dart';

import '../l10n/generated/app_localizations.dart';
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

String localizedCategory(BuildContext context, String cat) {
  final l10n = AppLocalizations.of(context);
  if (l10n == null) return cat;
  switch (cat) {
    case 'Food':
      return l10n.catFood;
    case 'Transport':
      return l10n.catTransport;
    case 'Shopping':
      return l10n.catShopping;
    case 'Bills':
      return l10n.catBills;
    case 'Health':
      return l10n.catHealth;
    case 'Education':
      return l10n.catEducation;
    case 'Other':
      return l10n.catOther;
    case 'Salary':
      return l10n.catSalary;
    case 'Freelance':
      return l10n.catFreelance;
    case 'Allowance':
      return l10n.catAllowance;
    case 'Gift':
      return l10n.catGift;
    case 'Refund':
      return l10n.catRefund;
    case 'Opening balance':
      return l10n.catOpeningBalance;
    case 'Other income':
      return l10n.catOtherIncome;
    case 'All':
      return l10n.catAll;
    default:
      return cat;
  }
}

class Dashboard extends StatefulWidget {
  const Dashboard({super.key});
  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  int page = 0;
  final search = TextEditingController();

  List<String> getTitles(AppLocalizations? l10n) => [
    l10n?.navOverview ?? 'Overview',
    l10n?.navTransactions ?? 'Transactions',
    l10n?.navInsights ?? 'Insights',
    l10n?.navSettings ?? 'Settings',
  ];

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
    if (saved == true && mounted) {
      final l10n = AppLocalizations.of(context);
      message(
        l10n?.transactionSavedSuccess ?? 'Transaction saved successfully.',
      );
    }
  }

  void message(String text) => ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(text), behavior: SnackBarBehavior.floating),
  );

  Future<void> remove(ExpenseProvider p, Expense e) async {
    final l10n = AppLocalizations.of(context);
    final yes = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text(
          l10n?.deleteTransactionDialogTitle ?? 'Delete this transaction?',
        ),
        content: Text(
          '${e.title}\n${money(e.amountCents)}\n\n${l10n?.actionCannotBeUndone ?? 'This action cannot be undone.'}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: Text(l10n?.keepExpense ?? 'Keep expense'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(c, true),
            child: Text(l10n?.delete ?? 'Delete'),
          ),
        ],
      ),
    );
    if (yes != true) return;
    try {
      await p.delete(e.id);
      if (mounted) {
        message(l10n?.transactionDeletedSuccess ?? 'Transaction deleted.');
      }
    } catch (_) {
      if (mounted) {
        message(
          l10n?.couldNotDeleteError ?? 'Could not delete. Please try again.',
        );
      }
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
    final l10n = AppLocalizations.of(context);
    final localeProvider = context.watch<LocaleProvider?>();
    final isNepali = localeProvider?.isNepali ?? false;
    final titles = getTitles(l10n);
    final p = context.watch<ExpenseProvider>();
    final auth = context.watch<AuthProvider>();
    final wide = MediaQuery.sizeOf(context).width >= 950;

    final heroTitles = [
      l10n?.heroOverviewTitle ?? 'A little clarity. A lot of control.',
      l10n?.heroTransactionsTitle ?? 'Every expense, in one place.',
      l10n?.heroInsightsTitle ?? 'Understand your spending.',
      l10n?.heroSettingsTitle ?? 'Account & Preferences.',
    ];
    final heroSubtitles = [
      l10n?.heroOverviewSubtitle ?? 'Here is how your month is shaping up.',
      l10n?.heroTransactionsSubtitle ??
          'Search, review and organize your daily spending.',
      l10n?.heroInsightsSubtitle ??
          'Turn your everyday expenses into useful insights.',
      l10n?.heroSettingsSubtitle ??
          'Manage calendar, currency, and data privacy options.',
    ];

    return Scaffold(
      bottomNavigationBar: wide
          ? null
          : NavigationBar(
              selectedIndex: page,
              onDestinationSelected: (i) => setState(() => page = i),
              destinations: [
                NavigationDestination(
                  icon: const Icon(Icons.space_dashboard_outlined),
                  label: titles[0],
                ),
                NavigationDestination(
                  icon: const Icon(Icons.receipt_long_outlined),
                  label: titles[1],
                ),
                NavigationDestination(
                  icon: const Icon(Icons.bar_chart_rounded),
                  label: titles[2],
                ),
                NavigationDestination(
                  icon: const Icon(Icons.settings_outlined),
                  label: titles[3],
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
                      l10n?.sidebarSlogan ?? 'YOUR MONEY, MADE CLEAR',
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
                          Text(
                            l10n?.sidebarCardTitle ?? 'Make every rupee count',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            l10n?.sidebarCardDesc ??
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
                      l10n?.sidebarFooter ?? 'Personal expense tracker',
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
                            label: Text(l10n?.shareReport ?? 'Share Report'),
                          ),
                          const SizedBox(width: 14),
                        ] else ...[
                          IconButton(
                            tooltip: l10n?.shareReport ?? 'Share Report',
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
                            l10n?.personalAccount ?? 'Personal account',
                            style: TextStyle(
                              color: context.appMuted,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(width: 10),
                        ],
                        if (wide) ...[
                          IconButton(
                            tooltip: isNepali
                                ? (l10n?.switchToEnglish ??
                                    'Switch to English')
                                : (l10n?.switchToNepali ??
                                    'नेपालीमा बदल्नुहोस्'),
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
                              child: Text(
                                auth.user?.email ??
                                    (auth.user?.isAnonymous == true
                                        ? (l10n?.guestSession ??
                                            'Guest Session')
                                        : (l10n?.yourAccount ??
                                            'Your account')),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            PopupMenuItem(
                              value: 'language',
                              child: Row(
                                children: [
                                  const Icon(Icons.translate_rounded, size: 18),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      isNepali
                                          ? (l10n?.languageEnglish ?? 'English')
                                          : (l10n?.languageNepali ??
                                              'नेपाली (Nepali)'),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            PopupMenuItem(
                              value: 'settings',
                              child: Text(l10n?.settings ?? 'Settings'),
                            ),
                            PopupMenuItem(
                              value: 'logout',
                              child: Text(l10n?.signOut ?? 'Sign out'),
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
                                message(
                                  l10n?.signOutFailed ??
                                      'Sign out failed. Please try again.',
                                );
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
                                        heroTitles[page],
                                        style: Theme.of(context)
                                            .textTheme
                                            .headlineSmall,
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        heroSubtitles[page],
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
                                      label: Text(
                                        l10n?.addMoney ?? 'Add money',
                                      ),
                                    ),
                                    OutlinedButton.icon(
                                      onPressed: () => edit(p),
                                      icon: const Icon(Icons.add, size: 19),
                                      label: Text(
                                        l10n?.addExpense ?? 'Add expense',
                                      ),
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
                                  segments: [
                                    ButtonSegment(
                                      value: true,
                                      label: Text(
                                        l10n?.calendarNepaliBs ?? 'Nepali (BS)',
                                      ),
                                    ),
                                    ButtonSegment(
                                      value: false,
                                      label: Text(
                                        l10n?.calendarEnglishAd ??
                                            'English (AD)',
                                      ),
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
                                            tooltip:
                                                l10n?.previousMonth ??
                                                'Previous month',
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
                                            tooltip:
                                                l10n?.nextMonth ?? 'Next month',
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
                                        l10n?.currencyNpr ??
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
                                    l10n?.unableToLoadExpenses ??
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
                                    summary(p, l10n),
                                    const SizedBox(height: 12),
                                    Text(
                                      '${l10n?.monthlyNet ?? 'Monthly net'}: ${money(p.monthlyNet)}  |  ${l10n?.transactionsCount(p.monthlyTransactions.length) ?? '${p.monthlyTransactions.length} transactions'}',
                                      style: TextStyle(color: context.appMuted),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      l10n?.onboardingTip ??
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
                                          l10n?.dailySpending ??
                                              'Daily spending',
                                          dailyChart(p, l10n),
                                        );
                                        final breakdown = panel(
                                          l10n?.spendingByCategory ??
                                              'Spending by category',
                                          categoryBreakdown(p, l10n),
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
                                      l10n?.monthlyPerspective ??
                                          'Your monthly perspective',
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            p.previousTotal == 0
                                                ? (l10n?.noSpendingLastMonth ??
                                                    'No spending recorded last month to compare yet.')
                                                : (p.total > p.previousTotal
                                                    ? (l10n?.moreThanLastMonth(
                                                            money(
                                                              (p.total -
                                                                      p.previousTotal)
                                                                  .abs(),
                                                            )) ??
                                                        '${money((p.total - p.previousTotal).abs())} more than last month.')
                                                    : (l10n?.lessThanLastMonth(
                                                            money(
                                                              (p.total -
                                                                      p.previousTotal)
                                                                  .abs(),
                                                            )) ??
                                                        '${money((p.total - p.previousTotal).abs())} less than last month.')),
                                            style: const TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          const SizedBox(height: 10),
                                          Text(
                                            l10n?.monthlyComparisonNotice ??
                                                'Comparisons use whole calendar months. A month still in progress may have a lower total.',
                                            style: TextStyle(
                                              color: context.appMuted,
                                            ),
                                          ),
                                        ],
                                      ),
                                    )
                                  else
                                    transactions(p, l10n),
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

  Widget summary(ExpenseProvider p, AppLocalizations? l10n) => LayoutBuilder(
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
              Row(
                children: [
                  const Icon(
                    Icons.account_balance_wallet_outlined,
                    color: Colors.white70,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    l10n?.recordedBalance ?? 'Recorded balance',
                    style: const TextStyle(color: Colors.white70),
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
              Text(
                l10n?.recordedBalanceSubtitle ??
                    'All recorded income minus expenses',
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ],
          ),
        ),
        metric(
          l10n?.moneyIn ?? 'Money in',
          money(p.income),
          l10n?.moneyInSubtitle ?? 'Income for selected month',
          Icons.south_west_rounded,
        ),
        metric(
          l10n?.moneyOut ?? 'Money out',
          money(p.total),
          l10n?.moneyOutSubtitle ?? 'Expenses for selected month',
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

  Widget dailyChart(ExpenseProvider p, AppLocalizations? l10n) {
    final days = p.dailyTotals;
    final maxValue = days.fold<int>(0, math.max);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          maxValue == 0
              ? (l10n?.addExpenseToStartTimeline ??
                  'Add an expense to start your spending timeline.')
              : (l10n?.highestDay(money(maxValue)) ??
                  'Highest day: ${money(maxValue)}'),
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
              l10n?.dayOfMonth ?? 'Day of month',
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

  Widget categoryBreakdown(ExpenseProvider p, AppLocalizations? l10n) {
    final ranked = categories.where((c) => p.categoryTotal(c) > 0).toList()
      ..sort((a, b) => p.categoryTotal(b).compareTo(p.categoryTotal(a)));
    if (ranked.isEmpty) {
      return SizedBox(
        height: 230,
        child: Center(
          child: Text(
            l10n?.categoriesEmpty ?? 'Your categories will appear here.',
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
                      Expanded(child: Text(localizedCategory(context, c))),
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

  Widget transactions(ExpenseProvider p, AppLocalizations? l10n) {
    final items = page == 0
        ? p.monthlyTransactions.take(5).toList()
        : p.visible;

    String sortLabel(String v) => switch (v) {
      'Newest first' => l10n?.sortNewestFirst ?? 'Newest first',
      'Oldest first' => l10n?.sortOldestFirst ?? 'Oldest first',
      'Highest amount' => l10n?.sortHighestAmount ?? 'Highest amount',
      'Lowest amount' => l10n?.sortLowestAmount ?? 'Lowest amount',
      _ => v,
    };

    return panel(
      page == 0
          ? (l10n?.recentTransactions ?? 'Recent transactions')
          : (l10n?.transactionHistory ?? 'Transaction history'),
      Column(
        children: [
          if (page == 1) ...[
            Wrap(
              spacing: 8,
              children: ['All', 'Income', 'Expenses']
                  .map(
                    (type) => ChoiceChip(
                      label: Text(
                        type == 'All'
                            ? (l10n?.filterAllTransactions ??
                                'All transactions')
                            : (type == 'Income'
                                ? (l10n?.filterIncome ?? 'Income')
                                : (l10n?.filterExpenses ?? 'Expenses')),
                      ),
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
                hintText: l10n?.searchHint ?? 'Search title or note',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: IconButton(
                  tooltip: l10n?.clearSearchTooltip ?? 'Clear search',
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
                          label: Text(
                            c == 'All'
                                ? (l10n?.catAll ?? 'All')
                                : localizedCategory(context, c),
                          ),
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
                    l10n?.resultsCount(items.length) ?? '${items.length} results',
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
                                sortLabel(v),
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
                        ? (l10n?.noMatchingTransactions ??
                            'No matching transactions')
                        : (l10n?.freshStartThisMonth ??
                            'A fresh start for this month'),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n?.emptyTransactionsPrompt ??
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
                                  '${localizedCategory(context, e.category)} · ${formatBsAndAdDate(e.date)}',
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
                            tooltip: l10n?.editTransaction ?? 'Transaction actions',
                            onSelected: (v) =>
                                v == 'edit' ? edit(p, e) : remove(p, e),
                            itemBuilder: (_) => [
                              PopupMenuItem(
                                value: 'edit',
                                child: Text(
                                  l10n?.editTransaction ?? 'Edit transaction',
                                ),
                              ),
                              PopupMenuItem(
                                value: 'delete',
                                child: Text(
                                  l10n?.deleteTransaction ??
                                      'Delete transaction',
                                ),
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
              child: Text(l10n?.viewAll ?? 'View all'),
            )
          : IconButton(
              tooltip:
                  l10n?.copyCsvTooltip ?? 'Copy filtered transactions as CSV',
              onPressed: p.visible.isEmpty ? null : () => export(p),
              icon: const Icon(Icons.copy_all_outlined),
            ),
    );
  }
}
