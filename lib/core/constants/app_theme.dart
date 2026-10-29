import 'package:flutter/material.dart';

import '../widgets/centered_page_transitions.dart';
import 'app_colors.dart';
import 'app_typography.dart';

class AppTheme {
  AppTheme._();

  static ThemeData get light {
    final colorScheme =
        ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          surface: AppColors.white,
        ).copyWith(
          primary: AppColors.primary,
          onPrimary: AppColors.white,
          secondary: AppColors.secondary,
          onSecondary: AppColors.textPrimary,
          onSurface: AppColors.textPrimary,
        );

    return ThemeData(
      useMaterial3: true,
      fontFamily: AppTypography.fontFamily,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.background,
      // 画面の切り替えの動きは、標準のまま(Flutterの版で名前が変わるので、標準の一覧を取り出して包む)。
      // 広い画面(パソコン)だけ、あとから開く画面を中央の列に収める。
      pageTransitionsTheme: PageTransitionsTheme(
        builders: {
          for (final entry in const PageTransitionsTheme().builders.entries)
            entry.key: CenteredPageTransitionsBuilder(entry.value),
        },
      ),
      textTheme: ThemeData.light().textTheme
          .copyWith(
            headlineSmall: AppTypography.title,
            titleLarge: AppTypography.title,
            titleMedium: AppTypography.section,
            bodyLarge: AppTypography.body,
            bodyMedium: AppTypography.body,
            bodySmall: AppTypography.caption,
            labelLarge: AppTypography.button,
          )
          .apply(
            fontFamily: AppTypography.fontFamily,
            bodyColor: AppColors.textPrimary,
            displayColor: AppColors.textPrimary,
          ),
      iconTheme: const IconThemeData(size: 24, color: AppColors.textPrimary),
      cardTheme: CardThemeData(
        color: AppColors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.white,
        contentPadding: const EdgeInsets.all(16),
        // 入力欄の下の案内・エラーは、既定だと1行で「…」に省略され、読めない。
        // 長い文でも折り返して全部見えるようにする(文字拡大でも欠けない)。
        helperMaxLines: 4,
        errorMaxLines: 4,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.divider),
        ),
        // 入力中の枠と文字は、プライマリ(コーラル)にしない。赤みの強い色だと
        // エラーに見えるため、ココア色にする。エラーは従来どおり赤。
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.textPrimary, width: 2),
        ),
        floatingLabelStyle: WidgetStateTextStyle.resolveWith(
          (states) => TextStyle(
            color: states.contains(WidgetState.error)
                ? colorScheme.error
                : AppColors.textPrimary,
          ),
        ),
      ),
      textSelectionTheme: const TextSelectionThemeData(
        cursorColor: AppColors.textPrimary,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          textStyle: AppTypography.button.copyWith(
            fontFamily: AppTypography.fontFamily,
          ),
          minimumSize: const Size(48, 48),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: const StadiumBorder(),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.textPrimary,
          textStyle: AppTypography.button.copyWith(
            fontFamily: AppTypography.fontFamily,
          ),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.white,
        surfaceTintColor: Colors.transparent,
        indicatorColor: Colors.transparent,
        elevation: 0,
        height: 72,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return TextStyle(
            fontFamily: AppTypography.fontFamily,
            fontSize: 11,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
            color: selected ? AppColors.primary : AppColors.textSecondary,
          );
        }),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        titleTextStyle: TextStyle(
          fontFamily: AppTypography.fontFamily,
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
        ),
      ),
      dividerColor: AppColors.divider,
    );
  }
}
