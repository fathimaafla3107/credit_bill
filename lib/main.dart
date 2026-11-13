import 'package:flutter/material.dart';

import 'app_theme.dart';
import 'login_page.dart';

void main() {
  runApp(const CreditBillApp());
}

class CreditBillApp extends StatelessWidget {
  const CreditBillApp({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = ColorScheme.fromSeed(seedColor: AppColors.primary)
        .copyWith(
          primary: AppColors.primary,
          onPrimary: Colors.white,
          secondary: AppColors.primaryLight,
          surface: AppColors.surface,
          onSurface: AppColors.ink,
        );

    return MaterialApp(
      title: 'Credit Bill System',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: colorScheme,
        scaffoldBackgroundColor: AppColors.surface,
        textTheme: Typography.blackMountainView.apply(
          bodyColor: AppColors.ink,
          displayColor: AppColors.ink,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.surface,
          foregroundColor: AppColors.ink,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
        ),
        snackBarTheme: const SnackBarThemeData(
          behavior: SnackBarBehavior.floating,
        ),
      ),
      home: const LoginPage(),
    );
  }
}
