import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'data/database/app_database.dart';
import 'providers/budget_provider.dart';
import 'screens/app_screens.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    ChangeNotifierProvider(
      create: (_) => BudgetProvider(AppDatabase.instance)..load(),
      child: const BudgetMateApp(),
    ),
  );
}

class BudgetMateApp extends StatelessWidget {
  const BudgetMateApp({super.key});

  @override
  Widget build(BuildContext context) => Consumer<BudgetProvider>(
    builder: (context, state, _) {
      final light = ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF168C72)),
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF6F8F7),
        cardTheme: const CardThemeData(elevation: 0, margin: EdgeInsets.zero),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
        ),
      );
      final dark = ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF168C72),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
        cardTheme: const CardThemeData(elevation: 0, margin: EdgeInsets.zero),
      );
      return MaterialApp(
        title: 'BudgetMate',
        debugShowCheckedModeBanner: false,
        theme: light,
        darkTheme: dark,
        themeMode: state.themeMode,
        home: const AppGate(),
      );
    },
  );
}
