import 'package:flutter/material.dart';

/// 和风配色（侘寂 / 大和绘）。
///
/// 以朱色为主色调的“红色和风”主题：
/// - 背景：和纸（暖米白）
/// - 主色：朱（和风红）
/// - 文字：墨 / 空蝉（深灰）
/// - 强调：金 / 苔 / 蓝 / 鼠
class WafuColors {
  WafuColors._();

  /// 和纸（浅色背景）
  static const washi = Color(0xFFF7F3EE);
  static const washiDeep = Color(0xFFEFE9E1);

  /// 墨（深色背景 / 主文字）
  static const sumi = Color(0xFF2B2726);
  static const sumiSoft = Color(0xFF4A4441);

  /// 朱（主色，和风红）
  static const shu = Color(0xFFC9402F);
  static const shuSoft = Color(0xFFE0705F);
  static const shuDeep = Color(0xFF9E2F21);

  /// 空蝉（次级文字）
  static const utsusemi = Color(0xFF6E6560);

  /// 苔（绿）
  static const koke = Color(0xFF5C7A4A);

  /// 蓝（indigo）
  static const ai = Color(0xFF4C5B8C);

  /// 金（黄）
  static const kin = Color(0xFFC9A227);

  /// 鼠（灰）
  static const nezumi = Color(0xFF8C837C);

  /// 空（天蓝）
  static const sora = Color(0xFF6E9BC4);

  /// 藤（紫）
  static const fuji = Color(0xFF8A6FA8);

  /// 深色模式背景（kazumi oled 纯黑风格）。
  static const sumiBg = Color(0xFF000000);
  static const sumiSurface = Color(0xFF141414);
  static const sumiSurfaceHigh = Color(0xFF1E1E1E);
  static const sumiBorder = Color(0xFF2A2A2A);
  static const sumiText = Color(0xFFF2F2F2);

  /// 明暗两套 ColorScheme。
  static ColorScheme scheme(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    return ColorScheme(
      brightness: brightness,
      primary: isDark ? shuSoft : shu,
      onPrimary: Colors.white,
      primaryContainer: isDark ? shuDeep : const Color(0xFFF5DCD7),
      onPrimaryContainer: isDark ? const Color(0xFFF5DCD7) : shuDeep,
      secondary: isDark ? shuSoft : const Color(0xFFB04A3A),
      onSecondary: Colors.white,
      secondaryContainer: isDark ? const Color(0xFF3A201C) : const Color(0xFFF3D8D1),
      onSecondaryContainer: isDark ? const Color(0xFFF5DCD7) : const Color(0xFF7E2A1F),
      tertiary: isDark ? kin : const Color(0xFF9E7B1E),
      onTertiary: Colors.white,
      error: isDark ? const Color(0xFFFF6B5E) : const Color(0xFFB3261E),
      onError: Colors.white,
      surface: isDark ? sumiBg : washi,
      onSurface: isDark ? sumiText : sumi,
      onSurfaceVariant: isDark ? const Color(0xFF9A9A9A) : utsusemi,
      outline: isDark ? sumiBorder : const Color(0xFFD8CFC5),
      outlineVariant: isDark ? const Color(0xFF2A2A2A) : const Color(0xFFE7E0D7),
      shadow: Colors.black26,
      scrim: Colors.black54,
      inverseSurface: isDark ? sumiText : sumi,
      onInverseSurface: isDark ? sumiBg : Colors.white,
      inversePrimary: isDark ? shu : shuSoft,
      surfaceContainer: isDark ? sumiSurface : washiDeep,
      surfaceContainerHighest: isDark ? sumiSurfaceHigh : const Color(0xFFEFE9E1),
      surfaceContainerHigh: isDark ? const Color(0xFF1A1A1A) : const Color(0xFFF1EBE3),
      surfaceContainerLow: isDark ? const Color(0xFF0D0D0D) : const Color(0xFFF5F1EB),
      surfaceContainerLowest: isDark ? const Color(0xFF000000) : const Color(0xFFFFFFFF),
      surfaceTint: isDark ? shuSoft : shu,
    );
  }
}
