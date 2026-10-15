import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:nepali_utils/nepali_utils.dart';

import '../models/calendar_period.dart';
import 'calendar_details.dart';

Future<DateTime?> pickNepaliDate(BuildContext context, DateTime initial) =>
    showDialog<DateTime>(
      context: context,
      builder: (_) => _NepaliPicker(initial: initial),
    );

class _NepaliPicker extends StatefulWidget {
  final DateTime initial;
  const _NepaliPicker({required this.initial});
  @override
  State<_NepaliPicker> createState() => _NepaliPickerState();
}

class _NepaliPickerState extends State<_NepaliPicker> {
  late DateTime selected = DateUtils.dateOnly(widget.initial);
  late CalendarPeriod period = CalendarPeriod(selected, nepali: true);
  final first = DateTime(2000);
  final last = DateUtils.dateOnly(DateTime.now());
  bool allowed(DateTime date) => !date.isBefore(first) && !date.isAfter(last);
  @override
  Widget build(BuildContext context) {
    final bs = toBs(period.start);
    final offset = period.start.weekday % 7;
    return AlertDialog(
      title: const Text('Choose Nepali date'),
      content: SizedBox(
        width: 360,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                bsDate(selected),
                style: Theme.of(context).textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 2),
              Text(
                '${DateFormat.yMMMMd().format(selected)} AD',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: DropdownButton<int>(
                      isExpanded: true,
                      value: bs.year,
                      items:
                          List.generate(
                                toBs(last).year - toBs(first).year + 1,
                                (i) => toBs(first).year + i,
                              )
                              .map(
                                (year) => DropdownMenuItem(
                                  value: year,
                                  child: Text('$year BS'),
                                ),
                              )
                              .toList(),
                      onChanged: (year) => setState(
                        () => period = CalendarPeriod(
                          NepaliDateTime(year!, bs.month).toDateTime(),
                          nepali: true,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: DropdownButton<int>(
                      isExpanded: true,
                      value: bs.month,
                      items: List.generate(
                        12,
                        (i) => DropdownMenuItem(
                          value: i + 1,
                          child: Text(
                            NepaliDateFormat.MMMM().format(
                              NepaliDateTime(bs.year, i + 1),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ).toList(),
                      onChanged: (month) => setState(
                        () => period = CalendarPeriod(
                          NepaliDateTime(bs.year, month!).toDateTime(),
                          nepali: true,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    tooltip: 'Previous BS month',
                    onPressed: period.start.isAfter(first)
                        ? () => setState(
                            () => period = CalendarPeriod(
                              period.shifted(-1),
                              nepali: true,
                            ),
                          )
                        : null,
                    icon: const Icon(Icons.chevron_left),
                  ),
                  const Flexible(
                    child: Text('Bikram Sambat', textAlign: TextAlign.center),
                  ),
                  IconButton(
                    tooltip: 'Next BS month',
                    onPressed: period.end.isBefore(last)
                        ? () => setState(
                            () => period = CalendarPeriod(
                              period.shifted(1),
                              nepali: true,
                            ),
                          )
                        : null,
                    icon: const Icon(Icons.chevron_right),
                  ),
                ],
              ),
              Row(
                children: [
                  'S',
                  'M',
                  'T',
                  'W',
                  'T',
                  'F',
                  'S',
                ].map((d) => Expanded(child: Center(child: Text(d)))).toList(),
              ),
              const SizedBox(height: 8),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: offset + period.days,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 7,
                  mainAxisExtent: 38,
                ),
                itemBuilder: (_, index) {
                  if (index < offset) return const SizedBox();
                  final day = index - offset + 1;
                  final date = period.day(day);
                  return TextButton(
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      backgroundColor: date == selected
                          ? Theme.of(context).colorScheme.primaryContainer
                          : null,
                    ),
                    onPressed: allowed(date)
                        ? () => setState(() => selected = date)
                        : null,
                    child: Text('$day'),
                  );
                },
              ),
              CalendarDetails(
                year: toBs(selected).year,
                month: toBs(selected).month,
                day: toBs(selected).day,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: allowed(selected)
              ? () => Navigator.pop(context, selected)
              : null,
          child: const Text('Select date'),
        ),
      ],
    );
  }
}
