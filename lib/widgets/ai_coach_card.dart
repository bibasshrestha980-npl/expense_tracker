import 'package:flutter/material.dart';
import '../providers/expense_provider.dart';
import '../services/ai_service.dart';
import '../theme.dart';

class AiCoachCard extends StatefulWidget {
  final ExpenseProvider provider;
  final bool isNepali;

  const AiCoachCard({
    super.key,
    required this.provider,
    required this.isNepali,
  });

  @override
  State<AiCoachCard> createState() => _AiCoachCardState();
}

class _AiCoachCardState extends State<AiCoachCard> {
  final AiService _aiService = const AiService();
  String? _insight;
  bool _loading = false;
  String? _lastSummaryKey;

  (String, int) _findTopCategory() {
    final Map<String, int> catTotals = {};
    for (final e in widget.provider.monthly) {
      catTotals[e.category] = (catTotals[e.category] ?? 0) + e.amountCents;
    }
    String topCat = '';
    int maxCents = 0;
    catTotals.forEach((cat, amt) {
      if (amt > maxCents) {
        topCat = cat;
        maxCents = amt;
      }
    });
    return (topCat, maxCents);
  }

  String get _currentSummaryKey {
    final (top, _) = _findTopCategory();
    return '${widget.provider.total}_${widget.provider.income}_${top}_${widget.isNepali}';
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && widget.provider.monthly.isNotEmpty) {
        _fetchInsight();
      }
    });
  }

  @override
  void didUpdateWidget(covariant AiCoachCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_lastSummaryKey != _currentSummaryKey && widget.provider.monthly.isNotEmpty) {
      _fetchInsight();
    }
  }

  Future<void> _fetchInsight({bool force = false}) async {
    if (!AiService.isConfigured) return;
    if (_loading) return;

    final p = widget.provider;
    if (p.monthly.isEmpty && p.income == 0) return;

    final (topCat, topCents) = _findTopCategory();

    _lastSummaryKey = _currentSummaryKey;
    setState(() => _loading = true);

    try {
      final insight = await _aiService.getFinancialCoachInsight(
        totalExpensesCents: p.total,
        totalIncomeCents: p.income,
        topCategory: topCat.isEmpty ? (widget.isNepali ? 'सामान्य' : 'General') : topCat,
        topCategoryCents: topCents,
        nepali: widget.isNepali,
      );

      if (mounted && insight != null && insight.isNotEmpty) {
        setState(() {
          _insight = insight;
          _loading = false;
        });
        return;
      }
    } catch (_) {}

    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    if (!AiService.isConfigured) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xff1e2824) : const Color(0xfff0f8f4),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: accent.withValues(alpha: 0.35),
          width: 1.2,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.auto_awesome, color: accent, size: 18),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.isNepali
                            ? '✨ Pocket AI वित्तीय सल्लाहकार'
                            : '✨ Pocket AI Financial Coach',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        widget.isNepali
                            ? 'Gemini AI द्वारा संचालित विश्लेषण'
                            : 'Powered by Gemini AI',
                        style: TextStyle(
                          fontSize: 11,
                          color: context.appMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  iconSize: 18,
                  tooltip: widget.isNepali ? 'पुनः विश्लेषण गर्नुहोस्' : 'Refresh AI insight',
                  onPressed: _loading ? null : () => _fetchInsight(force: true),
                  icon: _loading
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2, color: accent),
                        )
                      : const Icon(Icons.refresh_rounded, color: accent),
                ),
              ],
            ),
            const SizedBox(height: 10),
            if (_loading && _insight == null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2, color: accent),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      widget.isNepali
                          ? 'तपाईंको खर्च विश्लेषण गर्दैछ...'
                          : 'Analyzing your spending with AI...',
                      style: TextStyle(
                        fontSize: 13,
                        color: context.appMuted,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              )
            else if (_insight != null)
              Text(
                _insight!,
                style: const TextStyle(
                  fontSize: 13.5,
                  height: 1.45,
                  fontWeight: FontWeight.w500,
                ),
              )
            else
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      widget.isNepali
                          ? 'खर्च रेकर्ड भएपछि AI ले सल्लाह दिनेछ'
                          : 'AI will advise as you record transactions',
                      style: TextStyle(fontSize: 12.5, color: context.appMuted),
                    ),
                  ),
                  const SizedBox(width: 8),
                  TextButton.icon(
                    style: TextButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                      foregroundColor: accent,
                    ),
                    onPressed: () => _fetchInsight(force: true),
                    icon: const Icon(Icons.bolt_rounded, size: 16),
                    label: Text(
                      widget.isNepali ? 'सल्लाह लिनुहोस्' : 'Get advice',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
