import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/calendar_provider.dart';
import '../theme.dart';

class CalendarDetails extends StatelessWidget {
  final int year, month;
  final int? day;
  const CalendarDetails({
    super.key,
    required this.year,
    required this.month,
    this.day,
  });
  @override
  Widget build(BuildContext context) => ChangeNotifierProvider(
    key: ValueKey('$year/$month'),
    create: (_) => CalendarProvider(year, month),
    child: _Details(day),
  );
}

class _Details extends StatelessWidget {
  final int? day;
  const _Details(this.day);
  @override
  Widget build(BuildContext context) {
    final state = context.watch<CalendarProvider>();
    final info = state.data?.days[day];
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.appPanel,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Nepali calendar details',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          if (state.loading)
            const LinearProgressIndicator()
          else if (state.error != null) ...[
            Text(state.error!, style: TextStyle(color: context.appMuted)),
            TextButton(onPressed: state.reload, child: const Text('Retry')),
          ] else if (state.data == null) ...[
            Text(
              'The calendar sources have no published data for ${state.year}/${state.month}. Expense tracking and date selection still work.',
              style: TextStyle(color: context.appMuted, fontSize: 12),
            ),
            TextButton(
              onPressed: state.reload,
              child: const Text('Check again'),
            ),
          ] else ...[
            if (day == null)
              Text(
                'Select a calendar day to see its tithi, events and holiday information.',
                style: TextStyle(color: context.appMuted),
              )
            else if (info == null)
              Text(
                'No details were published for this day.',
                style: TextStyle(color: context.appMuted),
              )
            else ...[
              Text(
                info.tithi.isEmpty
                    ? 'Tithi not provided'
                    : 'Tithi: ${info.tithi}',
              ),
              if (info.event.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(info.event),
                ),
              if (info.holiday)
                const Padding(
                  padding: EdgeInsets.only(top: 8),
                  child: Chip(
                    avatar: Icon(Icons.celebration_outlined, size: 18),
                    label: Text('Holiday in source'),
                  ),
                ),
              if (info.event.isEmpty && !info.holiday)
                Text(
                  'No event or holiday listed.',
                  style: TextStyle(color: context.appMuted, fontSize: 12),
                ),
            ],
            const SizedBox(height: 10),
            Text(
              'Source: ${state.data!.source}',
              style: TextStyle(color: context.appMuted, fontSize: 10),
            ),
          ],
        ],
      ),
    );
  }
}
