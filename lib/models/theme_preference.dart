/// 主题偏好：跟随系统 / 浅色（和纸）/ 深色（墨色）。
enum AppThemePreference {
  system,
  light,
  dark;

  static AppThemePreference fromId(String? id) => AppThemePreference.values
      .firstWhere((t) => t.name == id, orElse: () => AppThemePreference.system);

  String get id => name;
}
