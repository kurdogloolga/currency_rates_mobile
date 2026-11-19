import 'package:flutter/material.dart';

import '../domain/statistics.dart';

/// Фирменные цвета: глубокий сапфир + тёплое золото.
abstract final class Brand {
  static const sapphire = Color(0xFF1C3D8C);
  static const sapphireDeep = Color(0xFF0F2459);
  static const indigo = Color(0xFF3F51D9);
  static const gold = Color(0xFFF2B705);
}

/// Дополнительные цвета приложения, зависящие от темы.
@immutable
class AppColors extends ThemeExtension<AppColors> {
  const AppColors({
    required this.headerGradient,
    required this.chartLine,
    required this.trendUp,
    required this.trendDown,
    required this.trendFlat,
    required this.warningBg,
    required this.warningFg,
    required this.pageBg,
  });

  final List<Color> headerGradient;
  final Color chartLine;
  final Color trendUp;
  final Color trendDown;
  final Color trendFlat;
  final Color warningBg;
  final Color warningFg;
  final Color pageBg;

  Color trend(Trend t) => switch (t) {
        Trend.up => trendUp,
        Trend.down => trendDown,
        Trend.flat => trendFlat,
      };

  static const light = AppColors(
    headerGradient: [Brand.sapphireDeep, Brand.sapphire, Brand.indigo],
    chartLine: Color(0xFF2A78D6),
    trendUp: Color(0xFF15803D),
    trendDown: Color(0xFFC62828),
    trendFlat: Color(0xFF5F6472),
    warningBg: Color(0xFFFFF4D6),
    warningFg: Color(0xFF7A4B00),
    pageBg: Color(0xFFF3F5FA),
  );

  static const dark = AppColors(
    headerGradient: [Color(0xFF0A1433), Color(0xFF14296A), Color(0xFF2B3AA8)],
    chartLine: Color(0xFF5B9DF0),
    trendUp: Color(0xFF4ADE80),
    trendDown: Color(0xFFFF6B6B),
    trendFlat: Color(0xFFA4A9B8),
    warningBg: Color(0xFF3A2E10),
    warningFg: Color(0xFFFFD873),
    pageBg: Color(0xFF0D111C),
  );

  @override
  AppColors copyWith() => this;

  @override
  AppColors lerp(AppColors? other, double t) => t < 0.5 ? this : (other ?? this);
}

extension AppColorsX on BuildContext {
  AppColors get colors => Theme.of(this).extension<AppColors>()!;
}

ThemeData buildTheme(Brightness brightness) {
  final isDark = brightness == Brightness.dark;
  final app = isDark ? AppColors.dark : AppColors.light;
  final scheme = ColorScheme.fromSeed(
    seedColor: Brand.sapphire,
    brightness: brightness,
  ).copyWith(
    primary: isDark ? const Color(0xFF9DB4FF) : Brand.sapphire,
    secondary: Brand.gold,
    onSecondary: const Color(0xFF2B1F00),
    surface: isDark ? const Color(0xFF161C2B) : Colors.white,
    surfaceContainerHighest: isDark ? const Color(0xFF232B3F) : const Color(0xFFE9EDF7),
    surfaceContainerHigh: isDark ? const Color(0xFF1D2436) : const Color(0xFFF0F3FA),
  );

  final base = ThemeData(useMaterial3: true, colorScheme: scheme, brightness: brightness);
  final text = base.textTheme;

  return base.copyWith(
    scaffoldBackgroundColor: app.pageBg,
    extensions: [app],
    textTheme: text.copyWith(
      headlineMedium: text.headlineMedium?.copyWith(fontWeight: FontWeight.w700, letterSpacing: -0.5),
      headlineSmall: text.headlineSmall?.copyWith(fontWeight: FontWeight.w700, letterSpacing: -0.3),
      titleLarge: text.titleLarge?.copyWith(fontWeight: FontWeight.w700),
      titleMedium: text.titleMedium?.copyWith(fontWeight: FontWeight.w600),
      labelLarge: text.labelLarge?.copyWith(fontWeight: FontWeight.w600),
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      margin: EdgeInsets.zero,
      color: scheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(color: scheme.outlineVariant.withValues(alpha: isDark ? 0.25 : 0.45)),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: scheme.surfaceContainerHigh,
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: BorderSide.none),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: BorderSide.none),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide(color: scheme.primary, width: 1.6),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide(color: scheme.error, width: 1.2),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide(color: scheme.error, width: 1.6),
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      height: 72,
      elevation: 0,
      backgroundColor: scheme.surface,
      indicatorColor: Brand.gold.withValues(alpha: isDark ? 0.28 : 0.30),
      labelTextStyle: WidgetStateProperty.resolveWith((states) => TextStyle(
            fontSize: 12,
            fontWeight: states.contains(WidgetState.selected) ? FontWeight.w700 : FontWeight.w500,
            color: states.contains(WidgetState.selected) ? scheme.onSurface : scheme.onSurfaceVariant,
          )),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      showDragHandle: true,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
    ),
  );
}
