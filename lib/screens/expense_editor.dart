import 'package:flutter/gestures.dart' show PointerDeviceKind, PointerScrollEvent;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import 'nepali_picker.dart';

import '../l10n/generated/app_localizations.dart';
import '../models/calendar_period.dart';
import '../models/expense.dart';
import '../providers/expense_provider.dart';
import '../services/sms_wallet_parser.dart';
import '../theme.dart';
import 'dashboard.dart' show localizedCategory;

class ExpenseEditor extends StatefulWidget {
  final ExpenseProvider provider;
  final Expense? expense;
  final bool income;
  const ExpenseEditor({
    super.key,
    required this.provider,
    this.expense,
    this.income = false,
  });
  @override
  State<ExpenseEditor> createState() => _ExpenseEditorState();
}

class _ExpenseEditorState extends State<ExpenseEditor> {
  final _form = GlobalKey<FormState>();
  late final TextEditingController _title, _amount, _note;
  final _chipsScrollController = ScrollController();
  late DateTime _date;
  late String _category;
  bool _busy = false;
  bool _nepali = false;
  bool _titleEdited = false;
  bool get _income => widget.expense?.isIncome ?? widget.income;
  String? _error;
  @override
  void initState() {
    super.initState();
    final e = widget.expense;
    _nepali = widget.provider.nepali;
    _title = TextEditingController(text: e?.title);
    _amount = TextEditingController(
      text: e == null ? '' : (e.amountCents / 100).toStringAsFixed(2),
    );
    _note = TextEditingController(text: e?.note);
    _date = e?.date ?? DateTime.now();
    _category =
        e?.category ?? (_income ? incomeCategories.first : categories.first);
    if (e == null && _income) _title.text = _category;
  }

  bool get _isNepaliLocale =>
      Localizations.maybeLocaleOf(context)?.languageCode == 'ne';

  int _aiSuggestionIndex = 0;

  List<String> _getAiSuggestions(String category) {
    if (_isNepaliLocale) {
      return aiCategorySuggestionsNe[category] ??
          aiCategorySuggestions[category] ??
          [category];
    }
    return aiCategorySuggestions[category] ?? [category];
  }

  String _getAiPrimarySuggestion(String category) {
    if (category == 'Food') {
      final hour = DateTime.now().hour;
      if (_isNepaliLocale) {
        if (hour >= 5 && hour < 11) return 'बिहानी चिया नास्ता';
        if (hour >= 11 && hour < 15) return 'दिउँसोको खाजा / खाना';
        if (hour >= 15 && hour < 19) return 'मोमो र चाउमिन';
        return 'बेलुकीको खाना';
      }
      if (hour >= 5 && hour < 11) return 'Breakfast & Tea';
      if (hour >= 11 && hour < 15) return 'Lunch / Khaja';
      if (hour >= 15 && hour < 19) return 'Momo & Chowmein';
      return 'Dinner & Groceries';
    }
    final list = _getAiSuggestions(category);
    return list.isNotEmpty
        ? list.first
        : (_isNepaliLocale ? localizedCategory(context, category) : category);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (widget.expense == null && !_titleEdited) {
      if (_income) {
        _title.text = _isNepaliLocale
            ? localizedCategory(context, _category)
            : _category;
      } else if (_title.text.isEmpty) {
        _title.text = _getAiPrimarySuggestion(_category);
      }
    }
  }

  void _cycleAiSuggestion() {
    final list = _getAiSuggestions(_category);
    if (list.isEmpty) return;
    _aiSuggestionIndex = (_aiSuggestionIndex + 1) % list.length;
    final next = list[_aiSuggestionIndex];
    setState(() {
      _title.text = next;
      _titleEdited = true;
    });
    if (_chipsScrollController.hasClients) {
      final target = (_aiSuggestionIndex * 110.0).clamp(
        0.0,
        _chipsScrollController.position.maxScrollExtent,
      );
      _chipsScrollController.animateTo(
        target,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
      );
    }
  }

  void _scrollChips(double offset) {
    if (_chipsScrollController.hasClients) {
      final target = (_chipsScrollController.offset + offset).clamp(
        0.0,
        _chipsScrollController.position.maxScrollExtent,
      );
      _chipsScrollController.animateTo(
        target,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
      );
    }
  }

  void _selectCategory(String? category) {
    if (category == null) return;
    setState(() {
      _category = category;
      _aiSuggestionIndex = 0;
      if (_income) {
        if (_title.text.trim().isEmpty ||
            (widget.expense == null && !_titleEdited)) {
          _title.text = _isNepaliLocale
              ? localizedCategory(context, category)
              : category;
          _titleEdited = false;
        }
      } else {
        // Auto-generate title by AI when a category (e.g. Food) is selected
        if (_title.text.trim().isEmpty ||
            (widget.expense == null && !_titleEdited)) {
          _title.text = _getAiPrimarySuggestion(category);
          _titleEdited = false;
        }
      }
    });
    if (_chipsScrollController.hasClients) {
      _chipsScrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  void dispose() {
    _title.dispose();
    _amount.dispose();
    _note.dispose();
    _chipsScrollController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await widget.provider.save(
        Expense(
          id: widget.expense?.id ?? '',
          title: _title.text.trim(),
          category: _category,
          amountCents: parseAmount(_amount.text)!,
          date: _date,
          note: _note.text.trim(),
          isIncome: _income,
        ),
      );
      if (mounted) Navigator.pop(context, true);
    } catch (_) {
      if (mounted) {
        final l10n = AppLocalizations.of(context);
        setState(
          () =>
              _error =
                  l10n?.couldNotSaveError ??
                  'Could not save. Check your connection and try again.',
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _openSmsParserDialog() async {
    await showDialog<void>(
      context: context,
      builder: (ctx) => _SmsParserDialog(
        isNepali: _isNepaliLocale,
        isIncome: _income,
        onApply: (parsed) {
          setState(() {
            _amount.text = parsed.amount.toStringAsFixed(2);
            _title.text = parsed.title;
            _titleEdited = true;
            if (categories.contains(parsed.category) ||
                incomeCategories.contains(parsed.category)) {
              _category = parsed.category;
            }
            if (parsed.referenceId != null && _note.text.isEmpty) {
              _note.text = 'Ref: ${parsed.referenceId}';
            }
          });
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return PopScope(
      canPop: !_busy,
      child: AlertDialog(
        title: Text(
          _income
              ? (widget.expense == null
                  ? (l10n?.addMoneyTitle ?? 'Add money')
                  : (l10n?.editIncomeTitle ?? 'Edit income'))
              : (widget.expense == null
                  ? (l10n?.addExpenseTitle ?? 'Add expense')
                  : (l10n?.editExpenseTitle ?? 'Edit expense')),
        ),
        content: SizedBox(
          width: 440,
          child: SingleChildScrollView(
            child: AbsorbPointer(
              absorbing: _busy,
              child: Form(
                key: _form,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      l10n?.expenseEditorSubtitle ??
                          'Keep the details clear. Your totals and insights update automatically.',
                      style: TextStyle(color: context.appMuted),
                    ),
                    if (widget.expense == null) ...[
                      const SizedBox(height: 12),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: OutlinedButton.icon(
                          onPressed: _openSmsParserDialog,
                          icon: const Icon(Icons.auto_awesome, size: 17),
                          label: Text(
                            _isNepaliLocale
                                ? 'SMS / वालेटबाट स्वतः भर्नुहोस्'
                                : 'Auto-fill from SMS / Wallet',
                            style: const TextStyle(fontSize: 13),
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _title,
                      onChanged: (_) => setState(() => _titleEdited = true),
                      maxLength: 80,
                      decoration: InputDecoration(
                        labelText: _income
                            ? (l10n?.whereFromLabel ??
                                'Where did the money come from?')
                            : (l10n?.whatForLabel ?? 'What was it for?'),
                        hintText: _income
                            ? (l10n?.octoberSalaryHint ?? 'e.g. October salary')
                            : (l10n?.lunchCafeHint ?? 'e.g. Lunch at the cafe'),
                        prefixIcon: const Icon(Icons.edit_note_rounded),
                        suffixIcon: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (_title.text.isNotEmpty)
                              IconButton(
                                icon: const Icon(Icons.clear_rounded, size: 18),
                                tooltip:
                                    l10n?.clearTitleTooltip ?? 'Clear title',
                                onPressed: () {
                                  setState(() {
                                    _title.clear();
                                    _titleEdited = true;
                                  });
                                },
                              ),
                            Tooltip(
                              message:
                                  l10n?.autoGenerateAiTooltip ??
                                  'Auto-generate with AI',
                              child: IconButton(
                                icon: const Icon(
                                  Icons.auto_awesome,
                                  color: accent,
                                  size: 20,
                                ),
                                onPressed: _cycleAiSuggestion,
                              ),
                            ),
                          ],
                        ),
                      ),
                      validator: (v) => (v?.trim().isEmpty ?? true)
                          ? (l10n?.enterTitleError ?? 'Enter a title')
                          : null,
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.auto_awesome, size: 13, color: accent),
                        const SizedBox(width: 5),
                        Expanded(
                          child: Tooltip(
                            message:
                                l10n?.aiSuggestionsForCategory(_category) ??
                                'Suggestions for $_category',
                            child: Text(
                              l10n?.aiSuggestionsLabel ?? 'AI suggestions:',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: context.appMuted,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                        Tooltip(
                          message: l10n?.scrollLeftTooltip ?? 'Scroll left',
                          child: InkWell(
                            borderRadius: BorderRadius.circular(4),
                            onTap: () => _scrollChips(-120),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 2,
                                vertical: 2,
                              ),
                              child: Icon(
                                Icons.chevron_left_rounded,
                                size: 18,
                                color: context.appMuted,
                              ),
                            ),
                          ),
                        ),
                        Tooltip(
                          message: l10n?.scrollRightTooltip ?? 'Scroll right',
                          child: InkWell(
                            borderRadius: BorderRadius.circular(4),
                            onTap: () => _scrollChips(120),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 2,
                                vertical: 2,
                              ),
                              child: Icon(
                                Icons.chevron_right_rounded,
                                size: 18,
                                color: context.appMuted,
                              ),
                            ),
                          ),
                        ),
                        Tooltip(
                          message:
                              l10n?.autoGenerateAiTooltip ??
                              'Auto-generate with AI',
                          child: InkWell(
                            borderRadius: BorderRadius.circular(4),
                            onTap: _cycleAiSuggestion,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 4,
                                vertical: 2,
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.refresh_rounded,
                                    size: 13,
                                    color: accent,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    l10n?.autoGenerate ?? 'Auto',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: accent,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ScrollConfiguration(
                      behavior: ScrollConfiguration.of(context).copyWith(
                        dragDevices: {
                          PointerDeviceKind.touch,
                          PointerDeviceKind.mouse,
                          PointerDeviceKind.trackpad,
                          PointerDeviceKind.stylus,
                        },
                      ),
                      child: Listener(
                        onPointerSignal: (pointerSignal) {
                          if (pointerSignal is PointerScrollEvent &&
                              _chipsScrollController.hasClients) {
                            final delta = pointerSignal.scrollDelta.dy != 0
                                ? pointerSignal.scrollDelta.dy
                                : pointerSignal.scrollDelta.dx;
                            if (delta != 0) {
                              final target = (_chipsScrollController.offset +
                                      delta)
                                  .clamp(
                                    0.0,
                                    _chipsScrollController
                                        .position.maxScrollExtent,
                                  );
                              _chipsScrollController.jumpTo(target);
                            }
                          }
                        },
                        child: SingleChildScrollView(
                          controller: _chipsScrollController,
                          scrollDirection: Axis.horizontal,
                          physics: const BouncingScrollPhysics(
                            parent: AlwaysScrollableScrollPhysics(),
                          ),
                          child: Row(
                            children: _getAiSuggestions(_category).map((s) {
                              final isSelected =
                                  _title.text.trim().toLowerCase() ==
                                  s.toLowerCase();
                              return Padding(
                                padding: const EdgeInsets.only(right: 6),
                                child: ActionChip(
                                  visualDensity: VisualDensity.compact,
                                  labelPadding: const EdgeInsets.symmetric(
                                    horizontal: 4,
                                  ),
                                  backgroundColor: isSelected
                                      ? const Color(0xffe6f3ed)
                                      : null,
                                  side: isSelected
                                      ? const BorderSide(
                                          color: accent,
                                          width: 1.2,
                                        )
                                      : null,
                                  avatar: isSelected
                                      ? const Icon(
                                          Icons.check_circle_rounded,
                                          size: 14,
                                          color: accent,
                                        )
                                      : const Icon(
                                          Icons.auto_awesome,
                                          size: 12,
                                          color: accent,
                                        ),
                                  label: Text(
                                    s,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: isSelected
                                          ? FontWeight.w600
                                          : FontWeight.w500,
                                      color: isSelected ? accent : null,
                                    ),
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _title.text = s;
                                      _titleEdited = true;
                                    });
                                  },
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: _amount,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                      ),
                      decoration: InputDecoration(
                        labelText: l10n?.amountLabel ?? 'Amount',
                        prefixText: 'NPR  ',
                        hintText: '0.00',
                        helperText: _income
                            ? (l10n?.amountReceivedHelper ??
                                'Enter the amount you received')
                            : (l10n?.amountPaidHelper ??
                                'Enter the amount you paid'),
                      ),
                      validator: (v) => parseAmount(v ?? '') == null
                          ? (l10n?.invalidAmountError ??
                              'Enter a positive amount with up to 2 decimals')
                          : null,
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      isExpanded: true,
                      initialValue: _category,
                      decoration: InputDecoration(
                        labelText: l10n?.categoryLabel ?? 'Category',
                      ),
                      items: (_income ? incomeCategories : categories)
                          .map(
                            (c) => DropdownMenuItem(
                              value: c,
                              child: Row(
                                children: [
                                  Icon(
                                    categoryIcon(c),
                                    size: 18,
                                    color: categoryColor(c),
                                  ),
                                  const SizedBox(width: 10),
                                  Text(localizedCategory(context, c)),
                                ],
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: _selectCategory,
                    ),
                    const SizedBox(height: 12),
                    SegmentedButton<bool>(
                      segments: [
                        ButtonSegment(
                          value: true,
                          label: Text(_isNepaliLocale ? 'वि.सं.' : 'BS'),
                        ),
                        ButtonSegment(
                          value: false,
                          label: Text(_isNepaliLocale ? 'ई.सं.' : 'AD'),
                        ),
                      ],
                      selected: {_nepali},
                      onSelectionChanged: (value) =>
                          setState(() => _nepali = value.first),
                    ),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.calendar_today_outlined),
                      title: Text(
                        _nepali
                            ? bsDate(_date)
                            : '${DateFormat.yMMMd().format(_date)} AD',
                      ),
                      subtitle: Text(
                        _nepali
                            ? '${DateFormat.yMMMd().format(_date)} AD'
                            : bsDate(_date),
                      ),
                      trailing: const Icon(Icons.edit_outlined),
                      onTap: _busy
                          ? null
                          : () async {
                              if (_nepali) {
                                final selected = await pickNepaliDate(
                                  context,
                                  _date,
                                );
                                if (selected != null && mounted) {
                                  setState(() => _date = selected);
                                }
                                return;
                              }
                              final d = await showDatePicker(
                                context: context,
                                initialDate: _date,
                                firstDate: DateTime(2000),
                                lastDate: DateTime.now(),
                              );
                              if (d != null && mounted) {
                                setState(() => _date = d);
                              }
                            },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _note,
                      maxLength: 300,
                      maxLines: 2,
                      decoration: InputDecoration(
                        labelText: l10n?.noteOptionalLabel ?? 'Note (optional)',
                      ),
                    ),
                    if (_error != null)
                      Text(
                        _error!,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: _busy ? null : () => Navigator.pop(context),
            child: Text(l10n?.cancel ?? 'Cancel'),
          ),
          FilledButton(
            onPressed: _busy ? null : _save,
            child: Text(
              _busy
                  ? (l10n?.savingButton ?? 'Saving…')
                  : (_income
                      ? (l10n?.saveIncomeButton ?? 'Save income')
                      : (l10n?.saveExpenseButton ?? 'Save expense')),
            ),
          ),
        ],
      ),
    );
  }
}

class _SmsParserDialog extends StatefulWidget {
  final bool isNepali;
  final bool isIncome;
  final ValueChanged<ParsedTransaction> onApply;

  const _SmsParserDialog({
    required this.isNepali,
    this.isIncome = false,
    required this.onApply,
  });

  @override
  State<_SmsParserDialog> createState() => _SmsParserDialogState();
}

class _SmsParserDialogState extends State<_SmsParserDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
    _controller.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final parsed = SmsWalletParser.parse(
      _controller.text,
      defaultIsIncome: widget.isIncome,
    );
    final theme = Theme.of(context);

    return AlertDialog(
      title: Row(
        children: [
          Icon(
            Icons.auto_awesome,
            color: theme.colorScheme.primary,
            size: 22,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              widget.isNepali
                  ? 'SMS / वालेट विवरण स्वतः भर्नुहोस्'
                  : 'Auto-fill from SMS / Wallet',
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: 440,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.isNepali
                    ? 'eSewa, Khalti, Fonepay वा बैंक SMS यहाँ पेस्ट गर्नुहोस्। विवरण स्वतः फाराममा भरिनेछ।'
                    : 'Paste transaction alerts from eSewa, Khalti, Fonepay, or your bank. Details will be extracted automatically.',
                style: TextStyle(
                  color: theme.colorScheme.outline,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                key: const Key('sms_input_field'),
                controller: _controller,
                maxLines: 3,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: widget.isNepali
                      ? 'उदा: Paid Rs. 450 to Himalayan Java via eSewa...'
                      : 'e.g., Paid Rs. 450 to Himalayan Java via eSewa...',
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    tooltip: 'Paste',
                    icon: const Icon(Icons.content_paste),
                    onPressed: () async {
                      final clip = await Clipboard.getData(Clipboard.kTextPlain);
                      if (clip?.text != null && mounted) {
                        _controller.text = clip!.text!.trim();
                      }
                    },
                  ),
                ),
              ),
              const SizedBox(height: 14),
              if (parsed != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: theme.colorScheme.primary.withValues(alpha: 0.4),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            parsed.isIncome ? Icons.arrow_downward : Icons.arrow_upward,
                            size: 16,
                            color: parsed.isIncome ? Colors.green : Colors.red,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '${parsed.isIncome ? (widget.isNepali ? "आम्दानी" : "Income") : (widget.isNepali ? "खर्च" : "Expense")}: Rs. ${parsed.amount.toStringAsFixed(2)}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${widget.isNepali ? "शीर्षक" : "Title"}: ${parsed.title}',
                        style: const TextStyle(fontSize: 13),
                      ),
                      Text(
                        '${widget.isNepali ? "श्रेणी" : "Category"}: ${parsed.category}',
                        style: const TextStyle(fontSize: 13),
                      ),
                      if (parsed.referenceId != null)
                        Text(
                          'Ref ID: ${parsed.referenceId}',
                          style: TextStyle(
                            fontSize: 12,
                            color: theme.colorScheme.outline,
                          ),
                        ),
                    ],
                  ),
                ),
              ] else if (_controller.text.isNotEmpty) ...[
                Text(
                  widget.isNepali
                      ? 'कुनै मान्य रकम फेला परेन। कृपया SMS वा सन्देश जाँच गर्नुहोस्।'
                      : 'No valid amount found. Please check the SMS or text.',
                  style: TextStyle(
                    color: theme.colorScheme.error,
                    fontSize: 12,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(widget.isNepali ? 'रद्द' : 'Cancel'),
        ),
        FilledButton.icon(
          icon: const Icon(Icons.check, size: 18),
          onPressed: parsed == null
              ? null
              : () {
                  widget.onApply(parsed);
                  Navigator.pop(context);
                },
          label: Text(
            widget.isNepali ? 'लागू गर्नुहोस्' : 'Apply Details',
          ),
        ),
      ],
    );
  }
}

