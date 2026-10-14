import 'package:flutter/material.dart';

import '../models/calendar_period.dart';
import '../models/expense.dart';
import '../models/sip.dart';
import '../providers/sip_provider.dart';

class SipEditor extends StatefulWidget {
  final SipProvider provider;
  final Sip? sip;

  const SipEditor({super.key, required this.provider, this.sip});

  @override
  State<SipEditor> createState() => _SipEditorState();
}

class _SipEditorState extends State<SipEditor> {
  final _form = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _amount;
  late final TextEditingController _day;
  late final TextEditingController _targetMonths;
  late final TextEditingController _returnRate;
  late final TextEditingController _folio;
  late DateTime _startDate;
  late bool _active;
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final s = widget.sip;
    _name = TextEditingController(text: s?.name ?? '');
    _amount = TextEditingController(
      text: s == null ? '' : (s.monthlyAmountCents / 100).toStringAsFixed(2),
    );
    _day = TextEditingController(text: s == null ? '15' : '${s.dayOfMonth}');
    _targetMonths = TextEditingController(
      text: s == null ? '60' : '${s.targetMonths}',
    );
    _returnRate = TextEditingController(
      text: s == null ? '12.0' : s.expectedReturnRate.toStringAsFixed(1),
    );
    _folio = TextEditingController(text: s?.folioNumber ?? '');
    _startDate = s?.startDate ?? DateTime.now();
    _active = s?.active ?? true;
  }

  @override
  void dispose() {
    _name.dispose();
    _amount.dispose();
    _day.dispose();
    _targetMonths.dispose();
    _returnRate.dispose();
    _folio.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _error = null;
    });

    try {
      final amountCents = parseAmount(_amount.text);
      if (amountCents == null) {
        setState(() => _error = 'Enter a valid monthly investment amount.');
        return;
      }

      final day = int.tryParse(_day.text.trim()) ?? 15;
      final targetMonths = int.tryParse(_targetMonths.text.trim()) ?? 60;
      final rate = double.tryParse(_returnRate.text.trim()) ?? 12.0;

      await widget.provider.save(
        Sip(
          id: widget.sip?.id ?? '',
          name: _name.text.trim(),
          monthlyAmountCents: amountCents,
          dayOfMonth: day.clamp(1, 31),
          startDate: _startDate,
          targetMonths: targetMonths > 0 ? targetMonths : 60,
          expectedReturnRate: rate > 0 ? rate : 12.0,
          folioNumber: _folio.text.trim(),
          active: _active,
        ),
      );

      if (mounted) Navigator.pop(context, true);
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'Could not save SIP. Check connection.');
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.sip == null ? 'New SIP Investment' : 'Edit SIP Investment'),
      content: SizedBox(
        width: 440,
        child: SingleChildScrollView(
          child: Form(
            key: _form,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextFormField(
                  controller: _name,
                  maxLength: 80,
                  decoration: const InputDecoration(
                    labelText: 'Mutual Fund / Scheme Name',
                    hintText: 'e.g. NIBL Sahabhagita Fund',
                    prefixIcon: Icon(Icons.account_balance_rounded),
                  ),
                  validator: (v) =>
                      (v?.trim().isEmpty ?? true) ? 'Enter scheme name' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _amount,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Monthly Installment (NPR)',
                    hintText: 'e.g. 2000.00',
                    prefixIcon: Icon(Icons.payments_outlined),
                  ),
                  validator: (v) => parseAmount(v ?? '') == null
                      ? 'Enter a positive amount'
                      : null,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _day,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Debit Day of Month',
                          hintText: '1 - 31',
                          prefixIcon: Icon(Icons.calendar_today_outlined),
                        ),
                        validator: (v) {
                          final n = int.tryParse(v ?? '');
                          if (n == null || n < 1 || n > 31) {
                            return 'Day 1-31';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _targetMonths,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Tenure (Months)',
                          hintText: 'e.g. 60 (5 yrs)',
                          prefixIcon: Icon(Icons.timelapse_rounded),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _returnRate,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(
                          labelText: 'Expected Return % p.a.',
                          hintText: 'e.g. 12.0',
                          prefixIcon: Icon(Icons.trending_up_rounded),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _folio,
                        decoration: const InputDecoration(
                          labelText: 'Folio / Demat No. (Opt)',
                          hintText: 'Optional',
                          prefixIcon: Icon(Icons.numbers_outlined),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.event_outlined),
                  title: Text('Start Date: ${formatBsAndAdDate(_startDate)}'),
                  trailing: const Icon(Icons.edit_outlined),
                  onTap: _busy
                      ? null
                      : () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: _startDate,
                            firstDate: DateTime(2000),
                            lastDate: DateTime(2100),
                          );
                          if (picked != null && mounted) {
                            setState(() => _startDate = picked);
                          }
                        },
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('SIP Status'),
                  subtitle: Text(_active ? 'Active & recurring' : 'Paused'),
                  value: _active,
                  onChanged: (v) => setState(() => _active = v),
                ),
                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      _error!,
                      style: TextStyle(color: Theme.of(context).colorScheme.error),
                    ),
                  ),
              ],
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
          child: Text(_busy ? 'Saving…' : 'Save SIP'),
        ),
      ],
    );
  }
}
