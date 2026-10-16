# Contributing to Pocket Expense Tracker

Contributions to Pocket are welcome, including bug fixes, documentation improvements, translations, and tests. Follow the [README setup guide](README.md#getting-started) to run the project with your own Firebase configuration.

## Code of Conduct

Please be respectful, collaborative, and constructive when opening issues or submitting pull requests.

## How Can I Contribute?

### Reporting Bugs

- Check the [Issues tab](https://github.com/bibasshrestha980-npl/expense_tracker/issues) to ensure the bug hasn't already been reported.
- Open a new issue with a clear summary, steps to reproduce, expected vs actual behavior, and platform information.
- Remove personal financial records, credentials, and tokens from screenshots and logs.

### Suggesting Enhancements

- Open a feature request issue describing the rationale, proposed solution, and potential alternatives.

### Pull Requests

1. Fork the repository and create your branch from `main`:
   ```bash
   git checkout -b feature/your-feature-name
   ```
2. Keep changes focused on one problem and follow the existing project structure.
3. Ensure formatting, analyzer checks, and tests all pass:
   ```bash
   dart format .
   flutter analyze
   flutter test
   ```
4. Update documentation and add or adjust tests when behavior changes. For documentation-only changes, check wording, links, and Markdown rendering.
5. Commit with a descriptive message, push your branch, and open a pull request explaining the problem, the change, and how you validated it.

## Coding Standards

- Follow the lint rules in `analysis_options.yaml` and use `dart format`.
- Store monetary amounts as integer paisa, consistent with the existing transaction model.
- Keep data access in repositories and state management in providers.
- Update the English and Nepali localization resources when adding localized text.
- Cover changed behavior with appropriate unit or widget tests.
