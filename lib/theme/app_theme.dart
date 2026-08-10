import 'package:flutter/material.dart';

/// opencode 网页风格主题（Apple 系配色，明暗两套）。
///
/// 配色取自 opencode.ai console 的 CSS 变量：
/// light:  bg #ffffff surface #f5f5f7 text #1d1d1f text-secondary #424245
///         text-muted #6e6e73 accent #007aff border #d2d2d7 border-muted #e5e5ea
/// dark:   bg #0c0c0e surface #161618 elevated #1c1c1f text #ffffff
///         text-secondary #c7c7cc text-muted #a1a1a6 accent #007aff
///         border #38383a border-muted #2c2c2e
class OcTheme {
  OcTheme._();

  static const lightBg = Color(0xFFFFFFFF);
  static const lightSurface = Color(0xFFF5F5F7);
  static const lightElevated = Color(0xFFFFFFFF);
  static const lightText = Color(0xFF1D1D1F);
  static const lightTextSecondary = Color(0xFF424245);
  static const lightTextMuted = Color(0xFF6E6E73);
  static const lightBorder = Color(0xFFD2D2D7);
  static const lightBorderMuted = Color(0xFFE5E5EA);
  static const accent = Color(0xFF007AFF);
  static const accentHover = Color(0xFF0056B3);

  static const darkBg = Color(0xFF0C0C0E);
  static const darkSurface = Color(0xFF161618);
  static const darkElevated = Color(0xFF1C1C1F);
  static const darkText = Color(0xFFFFFFFF);
  static const darkTextSecondary = Color(0xFFC7C7CC);
  static const darkTextMuted = Color(0xFFA1A1A6);
  static const darkBorder = Color(0xFF38383A);
  static const darkBorderMuted = Color(0xFF2C2C2E);

  static ThemeData light() => _build(Brightness.light);

  static ThemeData dark() => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final bg = isDark ? darkBg : lightBg;
    final surface = isDark ? darkSurface : lightSurface;
    final elevated = isDark ? darkElevated : lightElevated;
    final text = isDark ? darkText : lightText;
    final textSecondary = isDark ? darkTextSecondary : lightTextSecondary;
    final textMuted = isDark ? darkTextMuted : lightTextMuted;
    final border = isDark ? darkBorder : lightBorder;
    final borderMuted = isDark ? darkBorderMuted : lightBorderMuted;

    final scheme = ColorScheme.fromSeed(
      seedColor: accent,
      brightness: brightness,
      surface: bg,
    ).copyWith(
      primary: accent,
      onPrimary: Colors.white,
      surface: bg,
      onSurface: text,
      onSurfaceVariant: textSecondary,
      outline: border,
      outlineVariant: borderMuted,
      surfaceContainer: surface,
      surfaceContainerHighest: elevated,
      secondaryContainer: isDark ? const Color(0xFF1C1C1F) : lightSurface,
      onSecondaryContainer: textSecondary,
    );

    final base = ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: bg,
      fontFamily: null,
    );

    return base.copyWith(
      textTheme: base.textTheme.copyWith(
        headlineMedium: TextStyle(
          color: text,
          fontSize: 30,
          fontWeight: FontWeight.w600,
          height: 1.2,
        ),
        titleMedium: TextStyle(color: text, fontSize: 16, fontWeight: FontWeight.w600),
        bodyMedium: TextStyle(color: textSecondary, fontSize: 14),
        bodySmall: TextStyle(color: textMuted, fontSize: 13),
        labelLarge: TextStyle(color: text, fontSize: 14, fontWeight: FontWeight.w500),
      ),
      dividerColor: border,
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: surface,
        indicatorColor: isDark ? const Color(0xFF2C2C2E) : const Color(0xFFE5E5EA),
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            color: states.contains(WidgetState.selected) ? accent : textMuted,
          ),
        ),
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => TextStyle(
            color: states.contains(WidgetState.selected) ? text : textMuted,
            fontSize: 12,
            fontWeight: states.contains(WidgetState.selected)
                ? FontWeight.w600
                : FontWeight.w400,
          ),
        ),
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: surface,
        indicatorColor: isDark ? const Color(0xFF2C2C2E) : const Color(0xFFE5E5EA),
        selectedIconTheme: IconThemeData(color: accent),
        unselectedIconTheme: IconThemeData(color: textMuted),
        selectedLabelTextStyle: TextStyle(
          color: text,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelTextStyle: TextStyle(color: textMuted, fontSize: 12),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: bg,
        foregroundColor: text,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      cardTheme: CardThemeData(
        color: surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: borderMuted),
        ),
        margin: EdgeInsets.zero,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: accent,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: text,
          side: BorderSide(color: border),
          backgroundColor: bg,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          textStyle: TextStyle(fontSize: 14, color: text),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: accent),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: bg,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: accent, width: 1.5),
        ),
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: elevated,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: border),
        ),
        textStyle: TextStyle(color: textSecondary, fontSize: 12),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: elevated,
        contentTextStyle: TextStyle(color: textSecondary),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: borderMuted),
        ),
      ),
    );
  }
}

/// 图表内模型颜色：opencode 网页固定色表 + 哈希兜底色。
class ModelColors {
  ModelColors._();

  static const _fixed = <String, int>{
    'claude-sonnet-4-5': 0xFFD4745C,
    'claude-sonnet-4': 0xFFE8B4A4,
    'claude-opus-4': 0xFFC8A098,
    'claude-haiku-4-5': 0xFFF0D8D0,
    'claude-3-5-haiku': 0xFFF8E8E0,
    'gpt-5.1': 0xFF4A90E2,
    'gpt-5.1-codex': 0xFF6BA8F0,
    'gpt-5': 0xFF7DB8F8,
    'gpt-5-codex': 0xFF9FCAFF,
    'gpt-5-nano': 0xFFB8D8FF,
    'grok-code': 0xFF8B5CF6,
    'big-pickle': 0xFF10B981,
    'kimi-k2': 0xFFF59E0B,
    'qwen3-coder': 0xFFEC4899,
    'glm-4.6': 0xFF14B8A6,
  };

  /// 与网页 `getModelColor` 一致：固定表优先，否则 hash → hsl(h, 50%, 65%)。
  static Color forModel(String model) {
    final fixed = _fixed[model];
    if (fixed != null) return Color(fixed);
    final hash = model
        .split('')
        .fold<int>(0, (acc, ch) => ch.codeUnitAt(0) + ((acc << 5) - acc));
    final hue = hash.abs() % 360;
    return HSLColor.fromAHSL(1, hue.toDouble(), 0.5, 0.65).toColor();
  }

  /// 网页 addOpacityToColor：hex 色转带透明度。
  static Color withOpacity(Color color, double opacity) =>
      color.withValues(alpha: opacity);
}
