import 'package:flutter/gestures.dart' show PointerDeviceKind, PointerScrollEvent;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'nepali_picker.dart';

import '../models/calendar_period.dart';

import '../models/expense.dart';
import '../providers/expense_provider.dart';
import '../theme.dart';

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

  int _aiSuggestionIndex = 0;

  List<String> _getAiSuggestions(String category) =>
      aiCategorySuggestions[category] ?? [category];

  String _getAiPrimarySuggestion(String category) {
    if (category == 'Food') {
      final hour = DateTime.now().hour;
      if (hour >= 5 && hour < 11) return 'Breakfast & Tea';
      if (hour >= 11 && hour < 15) return 'Lunch / Khaja';
      if (hour >= 15 && hour < 19) return 'Momo & Chowmein';
      return 'Dinner & Groceries';
    }
    final list = _getAiSuggestions(category);
    return list.isNotEmpty ? list.first : category;
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
          _title.text = category;
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
        setState(
          () => _error = 'Could not save. Check your connection and try again.',
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !_busy,
    child: AlertDialog(
      title: Text(
        _income
            ? (widget.expense == null ? 'Add money' : 'Edit income')
            : (widget.expense == null ? 'Add expense' : 'Edit expense'),
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
                    'Keep the details clear. Your totals and insights update automatically.',
                    style: TextStyle(color: context.appMuted),
                  ),
                  const SizedBox(height: 24),
                  TextFormField(
                    controller: _title,
                    onChanged: (_) => setState(() => _titleEdited = true),
                    maxLength: 80,
                    decoration: InputDecoration(
                      labelText: _income
                          ? 'Where did the money come from?'
                          : 'What was it for?',
                      hintText: _income
                          ? 'e.g. October salary'
                          : 'e.g. Lunch at the cafe',
                      prefixIcon: const Icon(Icons.edit_note_rounded),
                      suffixIcon: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (_title.text.isNotEmpty)
                            IconButton(
                              icon: const Icon(Icons.clear_rounded, size: 18),
                              tooltip: 'Clear title',
                              onPressed: () {
                                setState(() {
                                  _title.clear();
                                  _titleEdited = true;
                                });
                              },
                            ),
                          Tooltip(
                            message: 'Auto-generate with AI',
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
                    validator: (v) =>
                        (v?.trim().isEmpty ?? true) ? 'Enter a title' : null,
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.auto_awesome, size: 13, color: accent),
                      const SizedBox(width: 5),
                      Expanded(
                        child: Tooltip(
                          message: 'Suggestions for $_category',
                          child: Text(
                            'AI suggestions:',
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
                        message: 'Scroll left',
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
                        message: 'Scroll right',
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
                        message: 'Auto-generate with AI',
                        child: InkWell(
                          borderRadius: BorderRadius.circular(4),
                          onTap: _cycleAiSuggestion,
                          child: const Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: 4,
                              vertical: 2,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.refresh_rounded,
                                  size: 13,
                                  color: accent,
                                ),
                                SizedBox(width: 4),
                                Text(
                                  'Auto',
                                  style: TextStyle(
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
                            final target =
                                (_chipsScrollController.offset + delta).clamp(
                              0.0,
                              _chipsScrollController.position.maxScrollExtent,
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
                                backgroundColor:
                                    isSelected ? const Color(0xffe6f3ed) : null,
                                side: isSelected
                                    ? const BorderSide(color: accent, width: 1.2)
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
                      labelText: 'Amount',
                      prefixText: 'NPR  ',
                      hintText: '0.00',
                      helperText: _income
                          ? 'Enter the amount you received'
                          : 'Enter the amount you paid',
                    ),
                    validator: (v) => parseAmount(v ?? '') == null
                        ? 'Enter a positive amount with up to 2 decimals'
                        : null,
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    isExpanded: true,
                    initialValue: _category,
                    decoration: const InputDecoration(labelText: 'Category'),
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
                                Text(c),
                              ],
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: _selectCategory,
                  ),
                  const SizedBox(height: 12),
                  SegmentedButton<bool>(
                    segments: const [
                      ButtonSegment(value: true, label: Text('BS')),
                      ButtonSegment(value: false, label: Text('AD')),
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
                            if (d != null && mounted) setState(() => _date = d);
                          },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _note,
                    maxLength: 300,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'Note (optional)',
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
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _busy ? null : _save,
          child: Text(
            _busy ? 'Saving…' : (_income ? 'Save income' : 'Save expense'),
          ),
        ),
      ],
    ),
  );
}
