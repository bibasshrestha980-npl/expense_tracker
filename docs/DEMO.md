# Pocket walkthrough

A short route through the app for project reviewers. Use fictional transactions and your own Firebase project.

## 1. Sign in

Create an email/password account, open Firebase's verification email, then return to Pocket and select **I've verified my email**. Google and guest access require their providers to be enabled.

## 2. Record a sample month

Add income of **NPR 30,000** and two expenses: **NPR 450** for food and **NPR 120** for transport. Choose dates in the same month.

With only these records, expect:

| Income | Expenses | Balance |
| --- | --- | --- |
| NPR 30,000 | NPR 570 | NPR 29,430 |

Check Overview, then edit a record in Transactions and confirm that totals update.

## 3. Explore the calendar

Switch between BS and AD and inspect the same transactions. External event coverage is separate from your financial records.

## 4. Review insights and reports

Open Insights to compare categories. Copy the report or CSV and inspect its contents before sharing. The sample month should include both expense categories and the income record.

## 5. Try preferences

Switch between English and Nepali in Settings. Try Light, Dark, and Follow system appearance. Restart the app to check that device preferences persist.

## What this demonstrates

- Firebase Authentication and email verification.
- Provider state management and reactive summaries.
- Firestore transaction persistence.
- Integer-paisa calculations, BS/AD dates, localization, and themes.

This is a manual review guide, not a claim that every platform has passed end-to-end testing. See the [known limitations](../README.md#current-limitations).
