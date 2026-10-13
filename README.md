# BudgetMate

BudgetMate is an offline-first Flutter budget tracker for students and individuals. It uses a local SQLite database; no account, network connection, or Firebase configuration is required.

## Features

- First-run onboarding and local profile setup (USD, SOS, EUR, GBP, KES).
- Dashboard balance, income, expenses, monthly budget progress, recent activity, and category chart.
- Create, edit, inspect, search, sort, filter, and delete income/expense transactions.
- Category budgets with date windows and 80% / 100% warnings.
- Savings goals, contributions, and completion feedback.
- Period-based analytics, category pie chart, income-vs-expense bars, monthly spending line chart, and custom dates.
- Persistent light/dark/system themes and alert preference.
- CSV transaction import and share/export.
- Local SQLite storage that works offline.

## Project layout

```text
lib/
  main.dart
  data/
    database/app_database.dart
    models/models.dart
  providers/budget_provider.dart
  screens/
    app_screens.dart
    transaction_screens.dart
    budget_goal_screens.dart
    analytics_settings_screens.dart
  widgets/app_widgets.dart
test/
  budget_provider_test.dart
  widget_test.dart
```

## Run

Install the Flutter SDK and Android/iOS toolchains, then from the project root:

```sh
flutter pub get
flutter run
```

To choose a connected device, run `flutter devices` and then `flutter run -d <device-id>`.

## Build Android APK

```sh
flutter build apk --release
```

The release APK is written to `build/app/outputs/flutter-apk/app-release.apk`. A debug build can be produced with `flutter build apk --debug`.

## Build for iOS

iOS builds require macOS, Xcode, and CocoaPods. From a Mac with the iOS toolchain configured:

```sh
flutter build ios --release
```

## Tests and analysis

```sh
flutter test
flutter analyze
```

The test suite exercises SQLite-backed income/expense creation, edits, deletion, balance totals, category/date budget calculations, goal progress, transaction search/filtering, and onboarding page navigation.

## Local data

The app stores its SQLite database in the platform's application data directory as `budget_mate.db`. Use **Settings → Delete all data** to clear the profile, transactions, budgets, and goals. CSV import reads the exported BudgetMate column format; CSV export uses the system share sheet.

There is no sample financial data by default, so dashboard totals are computed only from records entered or imported by the user.
