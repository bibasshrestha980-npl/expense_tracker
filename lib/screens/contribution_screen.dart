import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../l10n/generated/app_localizations.dart';
import '../models/contribution.dart';
import '../services/repositories/contribution_repository.dart';

class ContributionScreen extends StatefulWidget {
  final ContributionRepository repository;

  const ContributionScreen({super.key, required this.repository});

  @override
  State<ContributionScreen> createState() => _ContributionScreenState();
}

class _ContributionScreenState extends State<ContributionScreen> {
  AppLocalizations? get _l10n => AppLocalizations.of(context);

  void _message(String value) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(value), behavior: SnackBarBehavior.floating),
    );
  }

  Future<void> _addContribution() async {
    final l10n = _l10n;
    if (widget.repository.uid.isEmpty) {
      _message(
        l10n?.contributionSignInRequired ?? 'Sign in to save contributions.',
      );
      return;
    }

    final contribution = await showDialog<Contribution>(
      context: context,
      builder: (_) => const ContributionEditorDialog(),
    );
    if (contribution == null || !mounted) return;

    try {
      await widget.repository.saveContribution(contribution);
      if (mounted) {
        _message(_l10n?.contributionSaved ?? 'Contribution counted.');
      }
    } catch (_) {
      if (mounted) {
        _message(
          _l10n?.contributionSaveError ?? 'Could not save contribution. Check your connection and try again.',
        );
      }
    }
  }

  Future<void> _deleteContribution(Contribution contribution) async {
    final l10n = _l10n;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n?.deleteContribution ?? 'Delete contribution?'),
        content: Text(
          l10n?.deleteContributionConfirm ??
              'This contribution will be removed from your count.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(l10n?.cancel ?? 'Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(l10n?.delete ?? 'Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await widget.repository.deleteContribution(contribution.id);
      if (mounted) {
        _message(_l10n?.contributionDeleted ?? 'Contribution removed.');
      }
    } catch (_) {
      if (mounted) {
        _message(
          _l10n?.contributionDeleteError ?? 'Could not delete contribution. Check your connection and try again.',
        );
      }
    }
  }

  String _typeLabel(String type, AppLocalizations? l10n) => switch (type) {
    'Commit' => l10n?.contributionCommit ?? 'Commit',
    'Pull request' => l10n?.contributionPullRequest ?? 'Pull request',
    'Issue' => l10n?.contributionIssue ?? 'Issue',
    'Code review' => l10n?.contributionCodeReview ?? 'Code review',
    'Discussion' => l10n?.contributionDiscussion ?? 'Discussion',
    'Sponsorship' => l10n?.contributionSponsorship ?? 'Sponsorship',
    _ => l10n?.contributionOther ?? 'Other',
  };

  @override
  Widget build(BuildContext context) {
    final l10n = _l10n;
    return StreamBuilder<List<Contribution>>(
      stream: widget.repository.watchContributions(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                l10n?.contributionLoadError ?? 'Could not load contributions. Check your connection and try again.',
                textAlign: TextAlign.center,
              ),
            ),
          );
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final contributions = snapshot.data!;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Row(
                  children: [
                    const Icon(Icons.code_rounded, size: 36),
                    const SizedBox(width: 18),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n?.contributionCountLabel ??
                                'All-time contribution count',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            l10n?.contributionCountSubtitle ?? 'Each saved activity counts once, across every repository.',
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      '${contributions.length}',
                      style: Theme.of(context).textTheme.headlineMedium
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: Text(
                    l10n?.contributionCount(contributions.length) ??
                        '${contributions.length} contributions',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                FilledButton.icon(
                  onPressed: _addContribution,
                  icon: const Icon(Icons.add),
                  label: Text(l10n?.addContribution ?? 'Add contribution'),
                ),
              ],
            ),
            const SizedBox(height: 10),
            if (contributions.isEmpty)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    l10n?.contributionNone ??
                        'No contributions yet. Add one to start your count.',
                    textAlign: TextAlign.center,
                  ),
                ),
              )
            else
              ...contributions.map(
                (contribution) => Card(
                  child: ListTile(
                    leading: const CircleAvatar(
                      child: Icon(Icons.code_rounded),
                    ),
                    title: Text(contribution.title),
                    subtitle: Text(
                      [
                        _typeLabel(contribution.type, l10n),
                        if (contribution.repository.isNotEmpty)
                          contribution.repository,
                        DateFormat.yMMMd(
                          Localizations.localeOf(context).toLanguageTag(),
                        ).format(contribution.date),
                        if (contribution.note.isNotEmpty) contribution.note,
                      ].join(' • '),
                    ),
                    isThreeLine: true,
                    trailing: IconButton(
                      tooltip:
                          l10n?.deleteContribution ?? 'Delete contribution?',
                      onPressed: () => _deleteContribution(contribution),
                      icon: const Icon(Icons.delete_outline),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class ContributionEditorDialog extends StatefulWidget {
  const ContributionEditorDialog({super.key});

  @override
  State<ContributionEditorDialog> createState() =>
      _ContributionEditorDialogState();
}

class _ContributionEditorDialogState extends State<ContributionEditorDialog> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _repository = TextEditingController();
  final _note = TextEditingController();
  String _type = contributionTypes.first;
  DateTime _date = DateTime.now();

  AppLocalizations? get _l10n => AppLocalizations.of(context);

  @override
  void dispose() {
    _title.dispose();
    _repository.dispose();
    _note.dispose();
    super.dispose();
  }

  String _typeLabel(String type, AppLocalizations? l10n) => switch (type) {
    'Commit' => l10n?.contributionCommit ?? 'Commit',
    'Pull request' => l10n?.contributionPullRequest ?? 'Pull request',
    'Issue' => l10n?.contributionIssue ?? 'Issue',
    'Code review' => l10n?.contributionCodeReview ?? 'Code review',
    'Discussion' => l10n?.contributionDiscussion ?? 'Discussion',
    'Sponsorship' => l10n?.contributionSponsorship ?? 'Sponsorship',
    _ => l10n?.contributionOther ?? 'Other',
  };

  Future<void> _chooseDate() async {
    final selected = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (selected != null) setState(() => _date = selected);
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.pop(
      context,
      Contribution(
        id: '',
        title: _title.text.trim(),
        repository: _repository.text.trim(),
        type: _type,
        date: _date,
        note: _note.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = _l10n;
    return AlertDialog(
      title: Text(l10n?.addContribution ?? 'Add contribution'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                initialValue: _type,
                decoration: InputDecoration(
                  labelText: l10n?.contributionActivityType ?? 'Activity type',
                ),
                items: contributionTypes
                    .map(
                      (type) => DropdownMenuItem(
                        value: type,
                        child: Text(_typeLabel(type, l10n)),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value != null) setState(() => _type = value);
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _title,
                maxLength: 120,
                decoration: InputDecoration(
                  labelText: l10n?.contributionTitleField ?? 'Title',
                ),
                validator: (value) =>
                    value == null || value.trim().isEmpty ? '' : null,
              ),
              TextField(
                controller: _repository,
                maxLength: 100,
                decoration: InputDecoration(
                  labelText:
                      l10n?.contributionRepository ?? 'Repository (optional)',
                ),
              ),
              TextField(
                controller: _note,
                maxLength: 300,
                maxLines: 2,
                decoration: InputDecoration(
                  labelText: l10n?.contributionNote ?? 'Note (optional)',
                ),
              ),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: _chooseDate,
                  icon: const Icon(Icons.calendar_today_outlined),
                  label: Text(
                    '${l10n?.contributionDate ?? 'Date'}: ${DateFormat.yMMMd(Localizations.localeOf(context).toLanguageTag()).format(_date)}',
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n?.cancel ?? 'Cancel'),
        ),
        FilledButton(
          onPressed: _save,
          child: Text(l10n?.contributionSaveButton ?? 'Save'),
        ),
      ],
    );
  }
}
