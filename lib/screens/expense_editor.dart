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

  void _selectCategory(String? category) {
    if (category == null) return;
    setState(() {
      _category = category;
      if (_income &&
          (_title.text.trim().isEmpty ||
              (widget.expense == null && !_titleEdited))) {
        _title.text = category;
        _titleEdited = false;
      }
    });
  }

  @override
  void dispose() {
    _title.dispose();
    _amount.dispose();
    _note.dispose();
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
                    onChanged: (_) => _titleEdited = true,
                    maxLength: 80,
                    decoration: InputDecoration(
                      labelText: _income
                          ? 'Where did the money come from?'
                          : 'What was it for?',
                      hintText: _income
                          ? 'e.g. October salary'
                          : 'e.g. Lunch at the cafe',
                      prefixIcon: const Icon(Icons.edit_note_rounded),
                    ),
                    validator: (v) =>
                        (v?.trim().isEmpty ?? true) ? 'Enter a title' : null,
                  ),
                  const SizedBox(height: 12),
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
