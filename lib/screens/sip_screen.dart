import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/sip.dart';
import '../providers/expense_provider.dart';
import '../providers/sip_provider.dart';
import '../theme.dart';
import 'dashboard.dart';
import 'sip_editor.dart';

class SipScreen extends StatefulWidget {
  const SipScreen({super.key});

  @override
  State<SipScreen> createState() => _SipScreenState();
}

class _SipScreenState extends State<SipScreen> {
  // Calculator state
  double _calcMonthly = 5000.0;
  double _calcRate = 12.0;
  double _calcYears = 10.0;

  void _openEditor(BuildContext context, SipProvider provider, [Sip? sip]) {
    showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => SipEditor(provider: provider, sip: sip),
    );
  }

  Future<void> _recordInstallment(
    BuildContext context,
    Sip sip,
    SipProvider sipProvider,
    ExpenseProvider expenseProvider,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Record SIP Installment?'),
        content: Text(
          'Log installment for "${sip.name}" (${money(sip.monthlyAmountCents)}) as an expense in this month\'s ledger?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(c, true),
            child: const Text('Record Expense'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      try {
        await sipProvider.logInstallmentAsExpense(sip, expenseProvider);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Recorded ${sip.name} installment as expense!'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } catch (_) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Could not record installment. Try again.'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    }
  }

  Future<void> _deleteSip(BuildContext context, Sip sip, SipProvider p) async {
    final yes = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Delete SIP Scheme?'),
        content: Text(
          'Are you sure you want to delete "${sip.name}"? Past recorded expenses will remain intact.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: const Text('Keep'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(c, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (yes == true) {
      await p.delete(sip.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final sipProvider = context.watch<SipProvider?>();
    final expenseProvider = context.watch<ExpenseProvider>();

    if (sipProvider == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final sips = sipProvider.sips;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'SIP Investments',
                  style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  'Systematic wealth building & recurring mutual funds',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                ),
              ],
            ),
            FilledButton.icon(
              onPressed: () => _openEditor(context, sipProvider),
              icon: const Icon(Icons.add_rounded),
              label: const Text('New SIP'),
            ),
          ],
        ),
        const SizedBox(height: 20),

        // Portfolio Stats Cards
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: accent,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'TOTAL MONTHLY SIP COMMITMENT',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 11,
                  letterSpacing: 1.2,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                money(sipProvider.totalMonthlyCommitmentCents),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 16),
              const Divider(color: Colors.white24),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Total Invested to Date',
                          style: TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          money(sipProvider.totalInvestedAllSipsCents),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Estimated Value',
                          style: TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          money((sipProvider.totalCurrentCorpusEstimate * 100).toInt()),
                          style: const TextStyle(
                            color: Color(0xffb5f0d3),
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${sipProvider.activeSips.length} Active',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // List of SIPs
        if (sips.isEmpty)
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: Colors.grey.shade200),
            ),
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                children: [
                  Icon(Icons.savings_outlined, size: 56, color: Colors.grey.shade400),
                  const SizedBox(height: 16),
                  const Text(
                    'No SIP Schemes Tracked Yet',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Add your monthly mutual fund SIPs to track investments, project returns, and log installments with a single tap.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 20),
                  FilledButton.tonalIcon(
                    onPressed: () => _openEditor(context, sipProvider),
                    icon: const Icon(Icons.add),
                    label: const Text('Add Your First SIP'),
                  ),
                ],
              ),
            ),
          )
        else
          ...sips.map((sip) {
            final elapsed = sip.elapsedInstallments();
            final invested = sip.totalInvestedCents();
            final projected = sip.calculateCorpus();

            return Card(
              margin: const EdgeInsets.only(bottom: 14),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: Colors.grey.shade200),
              ),
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: sip.active
                              ? const Color(0xffe6f3ed)
                              : Colors.grey.shade100,
                          child: Icon(
                            Icons.trending_up_rounded,
                            color: sip.active ? accent : Colors.grey,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                sip.name,
                                style: const TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Deduction: ${sip.dayOfMonth}th of each month • ${sip.expectedReturnRate}% exp return',
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: sip.active ? const Color(0xffe6f3ed) : Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            sip.active ? 'Active' : 'Paused',
                            style: TextStyle(
                              color: sip.active ? accent : Colors.grey.shade700,
                              fontWeight: FontWeight.w600,
                              fontSize: 11,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Installment',
                              style: TextStyle(color: Colors.grey.shade600, fontSize: 11),
                            ),
                            Text(
                              money(sip.monthlyAmountCents),
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Paid to date',
                              style: TextStyle(color: Colors.grey.shade600, fontSize: 11),
                            ),
                            Text(
                              '$elapsed months (${money(invested)})',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              'Maturity Target',
                              style: TextStyle(color: Colors.grey.shade600, fontSize: 11),
                            ),
                            Text(
                              money((projected * 100).toInt()),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                                color: Color(0xff187765),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    const Divider(height: 1),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton.icon(
                          onPressed: () => _recordInstallment(
                            context,
                            sip,
                            sipProvider,
                            expenseProvider,
                          ),
                          icon: const Icon(Icons.bookmark_add_outlined, size: 18),
                          label: const Text('Record This Month'),
                        ),
                        IconButton(
                          tooltip: sip.active ? 'Pause SIP' : 'Resume SIP',
                          icon: Icon(
                            sip.active ? Icons.pause_circle_outline : Icons.play_circle_outline,
                          ),
                          onPressed: () => sipProvider.toggleActive(sip),
                        ),
                        IconButton(
                          tooltip: 'Edit SIP',
                          icon: const Icon(Icons.edit_outlined),
                          onPressed: () => _openEditor(context, sipProvider, sip),
                        ),
                        IconButton(
                          tooltip: 'Delete SIP',
                          icon: const Icon(Icons.delete_outline),
                          onPressed: () => _deleteSip(context, sip, sipProvider),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          }),

        const SizedBox(height: 32),

        // Interactive SIP Wealth Calculator
        Card(
          elevation: 0,
          color: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(color: Colors.grey.shade200),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.calculate_outlined, color: accent),
                    const SizedBox(width: 8),
                    const Text(
                      'SIP Wealth Growth Calculator',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'Estimate future compound growth for your monthly SIP investments.',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                ),
                const SizedBox(height: 20),

                // Monthly Investment Slider
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Monthly Investment'),
                    Text(
                      money((_calcMonthly * 100).toInt()),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                Slider(
                  value: _calcMonthly,
                  min: 500,
                  max: 50000,
                  divisions: 99,
                  label: 'NPR ${_calcMonthly.toInt()}',
                  onChanged: (v) => setState(() => _calcMonthly = v),
                ),

                // Return Rate Slider
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Expected Annual Return'),
                    Text(
                      '${_calcRate.toStringAsFixed(1)}% p.a.',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                Slider(
                  value: _calcRate,
                  min: 6,
                  max: 20,
                  divisions: 28,
                  label: '${_calcRate.toStringAsFixed(1)}%',
                  onChanged: (v) => setState(() => _calcRate = v),
                ),

                // Tenure Slider
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Time Horizon'),
                    Text(
                      '${_calcYears.toInt()} Years',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                Slider(
                  value: _calcYears,
                  min: 1,
                  max: 30,
                  divisions: 29,
                  label: '${_calcYears.toInt()} yrs',
                  onChanged: (v) => setState(() => _calcYears = v),
                ),

                const SizedBox(height: 16),
                _buildCalculatorResults(),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCalculatorResults() {
    final months = (_calcYears * 12).toInt();
    final r = (_calcRate / 100.0) / 12.0;
    final invested = _calcMonthly * months;
    final totalCorpus = _calcMonthly * ((math.pow(1 + r, months) - 1) / r) * (1 + r);
    final gains = totalCorpus - invested;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xfff5f7f8),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          Column(
            children: [
              Text(
                'Total Invested',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 11),
              ),
              const SizedBox(height: 4),
              Text(
                money((invested * 100).toInt()),
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
            ],
          ),
          Column(
            children: [
              Text(
                'Est. Wealth Gain',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 11),
              ),
              const SizedBox(height: 4),
              Text(
                money((gains * 100).toInt()),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: Color(0xff187765),
                ),
              ),
            ],
          ),
          Column(
            children: [
              Text(
                'Total Future Value',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 11),
              ),
              const SizedBox(height: 4),
              Text(
                money((totalCorpus * 100).toInt()),
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                  color: accent,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
