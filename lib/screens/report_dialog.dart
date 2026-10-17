import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../l10n/generated/app_localizations.dart';
import '../models/calendar_period.dart';
import '../models/expense.dart';
import '../providers/expense_provider.dart';
import '../theme.dart';
import 'dashboard.dart';

class ReportDialog extends StatelessWidget {
  final ExpenseProvider expenseProvider;

  const ReportDialog({super.key, required this.expenseProvider});

  String _formatSummaryText() {
    final periodName = formatBsAndAdMonth(expenseProvider.period.anchor);

    final income = expenseProvider.income;
    final totalExpense = expenseProvider.total;
    final netSavings = expenseProvider.monthlyNet;
    final savingsRate = income > 0
        ? ((netSavings / income) * 100).toStringAsFixed(1)
        : '0.0';

    final buffer = StringBuffer();
    buffer.writeln('📊 Pocket Financial Report — $periodName');
    buffer.writeln('━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    buffer.writeln('💵 Total Income:   ${money(income)}');
    buffer.writeln('💳 Total Expenses: ${money(totalExpense)}');
    buffer.writeln(
      '📈 Net Savings:    ${money(netSavings)} ($savingsRate% savings rate)',
    );

    buffer.writeln('\n🏷️ Category Breakdown:');
    for (final cat in categories) {
      final spent = expenseProvider.categoryTotal(cat);
      if (spent > 0) {
        final pct = totalExpense > 0
            ? ((spent / totalExpense) * 100).toStringAsFixed(1)
            : '0';
        buffer.writeln('• $cat: ${money(spent)} ($pct%)');
      }
    }

    final topExpenses = List<Expense>.from(
      expenseProvider.monthlyTransactions.where((e) => !e.isIncome),
    )..sort((a, b) => b.amountCents.compareTo(a.amountCents));

    if (topExpenses.isNotEmpty) {
      buffer.writeln('\n🔝 Top Expenses:');
      for (final e in topExpenses.take(3)) {
        buffer.writeln('• ${e.title}: ${money(e.amountCents)} (${e.category})');
      }
    }

    buffer.writeln('━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    buffer.writeln('Generated with Pocket • Expense Tracker');
    return buffer.toString();
  }

  Future<void> _shareText(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    final text = _formatSummaryText();
    await Clipboard.setData(ClipboardData(text: text));
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            l10n?.reportSummaryCopied ??
                'Financial report summary copied! Ready to share or paste.',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _exportCsv(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    String quote(String val) => '"${val.replaceAll('"', '""')}"';
    final lines = [
      'Date,Type,Title,Category,Amount (NPR),Note',
      ...expenseProvider.monthlyTransactions.map(
        (e) =>
            '${DateFormat('yyyy-MM-dd').format(e.date)},${e.isIncome ? 'Income' : 'Expense'},${quote(e.title)},${quote(e.category)},${(e.amountCents / 100).toStringAsFixed(2)},${quote(e.note)}',
      ),
    ];
    await Clipboard.setData(ClipboardData(text: lines.join('\r\n')));
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            l10n?.reportCsvCopied ??
                'Monthly CSV transactions copied to clipboard!',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final periodName = formatBsAndAdMonth(expenseProvider.period.anchor);

    final income = expenseProvider.income;
    final totalExpense = expenseProvider.total;
    final netSavings = expenseProvider.monthlyNet;
    final savingsRate = income > 0
        ? ((netSavings / income) * 100).toStringAsFixed(1)
        : '0.0';

    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.summarize_outlined, color: context.appAccent),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              l10n?.monthlyFinancialReportTitle ?? 'Monthly Financial Report',
              style: const TextStyle(fontWeight: FontWeight.bold),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: 500,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: context.palette.primaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  periodName,
                  style: TextStyle(
                    color: context.appAccent,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Summary KPI cards
              Row(
                children: [
                  Expanded(
                    child: _metricBox(
                      context,
                      l10n?.reportIncome ?? 'Income',
                      money(income),
                      context.appAccent,
                      Icons.arrow_downward_rounded,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _metricBox(
                      context,
                      l10n?.reportExpenses ?? 'Expenses',
                      money(totalExpense),
                      context.palette.error,
                      Icons.arrow_upward_rounded,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _metricBox(
                      context,
                      l10n?.reportNetSavings ?? 'Net Savings',
                      money(netSavings),
                      context.appAccent,
                      Icons.savings_rounded,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: context.appPanel,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      l10n?.reportSavingsRate ?? 'Savings Rate',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    Text(
                      '$savingsRate%',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: context.appAccent,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Category Breakdown Table
              Text(
                l10n?.reportSpendingByCategory ?? 'Spending by Category',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
              const SizedBox(height: 8),
              ...categories
                  .where((c) => expenseProvider.categoryTotal(c) > 0)
                  .map((cat) {
                final spent = expenseProvider.categoryTotal(cat);
                final pct = totalExpense > 0 ? (spent / totalExpense) : 0.0;
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            localizedCategory(context, cat),
                            style: const TextStyle(fontSize: 13),
                          ),
                          Text(
                            '${money(spent)} (${(pct * 100).toStringAsFixed(1)}%)',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      LinearProgressIndicator(
                        value: pct.clamp(0.0, 1.0),
                        backgroundColor:
                            context.palette.surfaceContainerHighest,
                        color: context.appAccent,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n?.close ?? 'Close'),
        ),
        FilledButton.tonalIcon(
          onPressed: () => _exportCsv(context),
          icon: const Icon(Icons.table_chart_outlined, size: 18),
          label: Text(l10n?.exportCsv ?? 'Export CSV'),
        ),
        FilledButton.icon(
          onPressed: () => _shareText(context),
          icon: const Icon(Icons.share_outlined, size: 18),
          label: Text(l10n?.shareSummary ?? 'Share Summary'),
        ),
      ],
    );
  }

  Widget _metricBox(
    BuildContext context,
    String label,
    String value,
    Color color,
    IconData icon,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    color: color,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: color,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
