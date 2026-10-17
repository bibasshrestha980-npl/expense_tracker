# Contributing

Bug fixes, translations, tests, and documentation improvements are welcome. Follow the [README](README.md#run-locally) to run the app with your own Firebase project.

## Before opening an issue

Check existing issues first. For bugs, include the steps to reproduce, expected result, device/browser, and app version or commit. Use fictional transactions in examples and remove private information from logs and screenshots.

For a feature request, describe the problem it would solve and one example of how it should work.

## Sending a change

Create a branch from `main` and keep the change focused. Explain what changed and how you checked it in the pull request.

```sh
dart format lib test
flutter analyze
flutter test
```

If you change Firestore rules, run the emulator checks in the [security guide](docs/SECURITY.md). For documentation-only edits, check the links and preview the Markdown.

Keep monetary values in integer paisa, data access in repositories, and state in providers. UI changes should account for English/Nepali text and light/dark themes. Add tests where they help verify changed behavior.
