import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';

import '../l10n/l10n.dart';
import '../models/opencode_data.dart';
import '../models/opencode_session.dart';
import '../models/sync_config.dart';
import '../models/theme_preference.dart';
import '../services/app_logger.dart';
import '../services/notification_service.dart';
import '../services/opencode_api.dart';
import '../services/session_store.dart';
import '../services/webdav_sync.dart';

/// Go 套餐预警阈值（百分比），三个维度可独立设置。
class AlertThresholds {
  const AlertThresholds({
    this.rolling = 80,
    this.weekly = 80,
    this.monthly = 80,
  });

  final int rolling;
  final int weekly;
  final int monthly;

  AlertThresholds copyWith({int? rolling, int? weekly, int? monthly}) =>
      AlertThresholds(
        rolling: rolling ?? this.rolling,
        weekly: weekly ?? this.weekly,
        monthly: monthly ?? this.monthly,
      );

  int get forRolling => rolling;
  int get forWeekly => weekly;
  int get forMonthly => monthly;

  Map<String, dynamic> toJson() => {
    'rolling': rolling,
    'weekly': weekly,
    'monthly': monthly,
  };

  factory AlertThresholds.fromJson(Map<String, dynamic> json) =>
      AlertThresholds(
        rolling: (json['rolling'] as num?)?.toInt() ?? 80,
        weekly: (json['weekly'] as num?)?.toInt() ?? 80,
        monthly: (json['monthly'] as num?)?.toInt() ?? 80,
      );
}

/// 全局应用状态：opencode 登录会话 + 外观 + 预警 + 自动刷新。
class AppState extends ChangeNotifier {
  AppState({required SessionStore store, OpenCodeApi? api})
    : _store = store,
      api = api ?? OpenCodeApi() {
    AppLogger.init(store.directory);
  }

  final SessionStore _store;
  final OpenCodeApi api;

  OpenCodeSession? session;
  bool loaded = false;
  bool refreshing = false;
  String? globalError;

  AppThemePreference themePreference = AppThemePreference.system;
  AppLocale locale = AppLocale.zhHans;

  /// 自动刷新间隔（分钟），0 = 关闭。
  int autoRefreshMinutes = 0;

  /// 套餐额度预警阈值（百分比）。
  AlertThresholds alertThresholds = const AlertThresholds();

  /// 开发者模式（设置页连点 5 次版本号开启）。
  bool devMode = false;

  /// 最近一次拉取的 Go 套餐用量与使用历史（用量/历史/模型页共享）。
  OcLiteSubscription? liteSubscription;
  List<OcUsageRecord> usageRows = [];
  List<OcUsageRecord> allUsage = [];
  bool usageLoading = false;
  String? usageError;
  DateTime? usageLoadedAt;
  Map<String, OcCostData> costCache = {};

  /// WebDAV 同步配置。
  WebDavConfig syncConfig = const WebDavConfig();

  /// 是否正在同步。
  bool syncing = false;

  /// 同步状态消息（成功/失败原因）。
  bool syncSucceeded = false;
  String? syncError;

  final WebDavSync _webdav = WebDavSync();

  /// 已触发预警的级别（避免重复通知）。
  final Set<String> _notifiedLevels = {};

  Timer? _autoRefreshTimer;

  File get _settingsFile {
    final p = _store.directory.path;
    final sep = p.endsWith('\\') || p.endsWith('/')
        ? ''
        : Platform.pathSeparator;
    return File('$p${sep}settings.json');
  }

  File get _usageCacheFile =>
      File('${_store.directory.path}${Platform.pathSeparator}usage_cache.json');

  File get _costCacheFile =>
      File('${_store.directory.path}${Platform.pathSeparator}cost_cache.json');

  Future<void> load() async {
    try {
      session = await _store.load();
      final settings = await _loadSettings();
      themePreference = AppThemePreference.fromId(
        settings['themePreference'] as String?,
      );
      locale = AppLocale.fromId(settings['locale'] as String?);
      autoRefreshMinutes = settings['autoRefreshMinutes'] as int? ?? 0;
      devMode = settings['devMode'] as bool? ?? false;
      alertThresholds = AlertThresholds.fromJson(
        Map<String, dynamic>.from(
          (settings['alertThresholds'] as Map?) ?? const {},
        ),
      );
      syncConfig = WebDavConfig.fromJson(
        Map<String, dynamic>.from((settings['syncConfig'] as Map?) ?? const {}),
      );
      if (session != null) {
        await _loadUsageCache();
        await _loadCostCache();
      } else {
        _clearCachedData();
      }
      loaded = true;
      _restartAutoRefresh();
      // 配置了 WebDAV 时启动拉取远端（异步，不阻塞启动）。
      if (syncConfig.enabled && syncConfig.configured) {
        unawaited(syncNow(silent: true));
      }
    } catch (e) {
      globalError = '读取本地数据失败：$e';
      AppLogger.e('load failed: $e');
    }
    AppLogger.i('app loaded: session=${session != null}');
    notifyListeners();
  }

  /// 校验当前会话是否仍有效（可选；失败视为失效）。
  Future<bool> checkSession() async {
    final s = session;
    if (s == null) return false;
    try {
      final info = await api.checkSession(
        cookie: s.cookie,
        workspaceId: s.workspaceId,
      );
      return info != null;
    } catch (e) {
      AppLogger.w('session check failed: $e');
      return false;
    }
  }

  Future<void> setSession(OpenCodeSession session) async {
    this.session = session;
    await _store.save(session);
    globalError = null;
    _restartAutoRefresh();
    notifyListeners();
  }

  Future<void> clearSession() async {
    session = null;
    _clearCachedData();
    unawaited(_deleteCacheFiles());
    _autoRefreshTimer?.cancel();
    notifyListeners();
  }

  /// 拉取 Go 套餐用量 + 使用历史，供用量/历史/模型三个页面共享。
  ///
  /// 分页拉全量时会触发服务端 503 限流，页间保持 250ms 延时并退避重试。
  Future<void> loadUsageData({bool force = false}) async {
    final s = session;
    if (s == null || usageLoading) return;
    if (!force &&
        usageLoadedAt != null &&
        usageLoadedAt!.isAfter(
          DateTime.now().subtract(const Duration(minutes: 1)),
        )) {
      return;
    }
    usageLoading = true;
    usageError = null;
    notifyListeners();
    try {
      final lite = await api.getLiteSubscription(
        cookie: s.cookie,
        workspaceId: s.workspaceId,
      );
      final rows = await api.getUsageInfo(
        cookie: s.cookie,
        workspaceId: s.workspaceId,
        page: 0,
      );
      final all = await _fetchAllUsage(s);
      liteSubscription = lite;
      usageRows = rows;
      allUsage = all;
      usageLoadedAt = DateTime.now();
      await checkAlerts(lite);
      await _saveUsageCache();
      AppLogger.i('shared usage loaded: ${all.length} records');
    } catch (e) {
      usageError = e.toString();
      AppLogger.w('loadUsageData failed: $e');
    } finally {
      usageLoading = false;
      notifyListeners();
    }
  }

  /// 读取某月成本；无缓存或 force 时请求网络并写入缓存。
  Future<OcCostData> loadCostCached({
    required int year,
    required int month, // 1-based
    bool force = false,
  }) async {
    final s = session;
    if (s == null) {
      throw ApiException('not logged in');
    }
    final key = '$year-${month.toString().padLeft(2, '0')}';
    if (!force) {
      final cached = costCache[key];
      if (cached != null) return cached;
    }
    final data = await api.getCosts(
      cookie: s.cookie,
      workspaceId: s.workspaceId,
      year: year,
      month: month - 1,
      tzOffset: '+08:00',
    );
    costCache[key] = data;
    await _saveCostCache();
    return data;
  }

  static const _usagePageSize = 50;

  Future<List<OcUsageRecord>> _fetchAllUsage(OpenCodeSession session) async {
    const maxPages = 60; // 最多 3000 条
    final all = <OcUsageRecord>[];
    for (var page = 0; page < maxPages; page++) {
      final rows = await _fetchUsagePageWithRetry(session, page);
      all.addAll(rows);
      if (rows.length < _usagePageSize) break;
      await Future<void>.delayed(const Duration(milliseconds: 250));
    }
    return all;
  }

  Future<List<OcUsageRecord>> _fetchUsagePageWithRetry(
    OpenCodeSession session,
    int page,
  ) async {
    for (var attempt = 0; attempt < 3; attempt++) {
      try {
        return await api.getUsageInfo(
          cookie: session.cookie,
          workspaceId: session.workspaceId,
          page: page,
        );
      } catch (e) {
        if (attempt < 2 && e.toString().contains('503')) {
          AppLogger.w(
            'usage page $page 503, retry ${attempt + 1} '
            'after ${500 * (attempt + 1)}ms',
          );
          await Future<void>.delayed(
            Duration(milliseconds: 500 * (attempt + 1)),
          );
          continue;
        }
        rethrow;
      }
    }
    throw ApiException('usage page $page failed after retries');
  }

  Future<void> setLocale(AppLocale locale) async {
    this.locale = locale;
    await _saveSettings();
    notifyListeners();
  }

  Future<void> setThemePreference(AppThemePreference pref) async {
    themePreference = pref;
    await _saveSettings();
    notifyListeners();
  }

  /// 自动刷新间隔（分钟）。
  Future<void> setAutoRefreshMinutes(int minutes) async {
    autoRefreshMinutes = minutes;
    _restartAutoRefresh();
    await _saveSettings();
    notifyListeners();
  }

  /// 预警阈值。
  Future<void> setAlertThresholds(AlertThresholds thresholds) async {
    alertThresholds = thresholds;
    _notifiedLevels.clear(); // 阈值变化后重新评估
    await _saveSettings();
    notifyListeners();
  }

  /// 开发者模式开关。
  Future<void> setDevMode(bool enabled) async {
    devMode = enabled;
    await _saveSettings();
    notifyListeners();
  }

  /// 设置 WebDAV 同步配置。
  Future<void> setSyncConfig(WebDavConfig config) async {
    syncConfig = config;
    await _saveSettings();
    notifyListeners();
    if (config.enabled && config.configured) {
      await syncNow();
    }
  }

  /// 执行 WebDAV 同步：先拉取远端（若远端较新则合并），再上传本地。
  Future<void> syncNow({bool silent = false}) async {
    if (syncing) return;
    if (!syncConfig.enabled || !syncConfig.configured) return;
    syncing = true;
    if (!silent) notifyListeners();
    try {
      final files = SyncFiles(_store.directory);
      // 1) 拉取远端 settings + session
      final remoteSettings = await _webdav.getFile(syncConfig, 'settings.json');
      final remoteSession = await _webdav.getFile(syncConfig, 'session.json');
      // 2) 合并设置（远端有则覆盖本地，以远端为准 —— 简单策略）
      if (remoteSettings != null) {
        await _applyRemoteSettings(remoteSettings);
      }
      if (remoteSession != null) {
        final s = OpenCodeSession.fromJson(remoteSession);
        if (s.isValid) {
          session = s;
          await _store.save(s);
          _restartAutoRefresh();
        }
      }
      // 3) 上传本地
      final localSettings =
          await files.readJson(files.settingsFile) ?? _currentSettingsJson();
      await _webdav.putFile(syncConfig, 'settings.json', localSettings);
      final localSession = await files.readJson(files.sessionFile);
      if (localSession != null) {
        await _webdav.putFile(syncConfig, 'session.json', localSession);
      }
      syncConfig = syncConfig.copyWith(lastSyncAt: DateTime.now());
      await _saveSettings();
      syncSucceeded = true;
      syncError = null;
      AppLogger.i('webdav sync done');
    } catch (e) {
      syncSucceeded = false;
      syncError = e.toString();
      AppLogger.w('webdav sync failed: $e');
    } finally {
      syncing = false;
      if (!silent) notifyListeners();
    }
  }

  Map<String, dynamic> _currentSettingsJson() => {
    'themePreference': themePreference.name,
    'locale': locale.name,
    'autoRefreshMinutes': autoRefreshMinutes,
    'devMode': devMode,
    'alertThresholds': alertThresholds.toJson(),
  };

  Future<void> _applyRemoteSettings(Map<String, dynamic> remote) async {
    autoRefreshMinutes = remote['autoRefreshMinutes'] as int? ?? 0;
    devMode = remote['devMode'] as bool? ?? false;
    alertThresholds = AlertThresholds.fromJson(
      Map<String, dynamic>.from(
        (remote['alertThresholds'] as Map?) ?? const {},
      ),
    );
    // syncConfig 只在远端有有效配置时应用（避免远端空/旧配置
    // 覆盖掉本地的 WebDAV 设置 —— 重装/远端异常时本地配置不丢）。
    final remoteSync = remote['syncConfig'];
    if (remoteSync is Map &&
        (remoteSync['url']?.toString().isNotEmpty ?? false)) {
      syncConfig = WebDavConfig.fromJson(Map<String, dynamic>.from(remoteSync));
    }
    _restartAutoRefresh();
    notifyListeners();
  }

  /// 定时自动刷新回调（由 dashboard 注册）。
  VoidCallback? onAutoRefresh;

  void _restartAutoRefresh() {
    _autoRefreshTimer?.cancel();
    _autoRefreshTimer = null;
    if (session == null || autoRefreshMinutes <= 0) return;
    _autoRefreshTimer = Timer.periodic(Duration(minutes: autoRefreshMinutes), (
      _,
    ) {
      AppLogger.i('auto refresh (every ${autoRefreshMinutes}m)');
      onAutoRefresh?.call();
    });
  }

  /// 检查 Go 套餐用量预警，触发系统通知（每个阈值级别只通知一次）。
  Future<void> checkAlerts(OcLiteSubscription? lite) async {
    if (lite == null) return;
    final l = L10n(locale);
    final checks = <String, OcLiteUsage?>{
      'rolling': lite.rollingUsage,
      'weekly': lite.weeklyUsage,
      'monthly': lite.monthlyUsage,
    };
    final thresholds = <String, int>{
      'rolling': alertThresholds.rolling,
      'weekly': alertThresholds.weekly,
      'monthly': alertThresholds.monthly,
    };
    for (final entry in checks.entries) {
      final usage = entry.value;
      if (usage == null) continue;
      final threshold = thresholds[entry.key] ?? 80;
      if (usage.usagePercent >= threshold &&
          !_notifiedLevels.contains(entry.key)) {
        _notifiedLevels.add(entry.key);
        AppLogger.i(
          'alert triggered: ${entry.key} ${usage.usagePercent}% >= $threshold%',
        );
        await NotificationService.instance.show(
          title: '${l.appTitle} · ${l.alertTitle}',
          body: switch (entry.key) {
            'rolling' =>
              '${l.goRollingUsage} ${usage.usagePercent}% / ${l.alertPercent(threshold)}',
            'weekly' =>
              '${l.goWeeklyUsage} ${usage.usagePercent}% / ${l.alertPercent(threshold)}',
            _ =>
              '${l.goMonthlyUsage} ${usage.usagePercent}% / ${l.alertPercent(threshold)}',
          },
          urgency: usage.rateLimited ? 'critical' : null,
        );
      }
    }
  }

  /// 发送测试通知（开发者选项）。
  Future<void> sendTestNotification() async {
    final l = L10n(locale);
    await NotificationService.instance.show(
      title: '${l.appTitle} · ${l.devTestNotification}',
      body: l.devTestNotificationDesc,
    );
  }

  Future<void> _loadUsageCache() async {
    try {
      if (!await _usageCacheFile.exists()) return;
      final raw = await _usageCacheFile.readAsString();
      final v = jsonDecode(raw);
      if (v is! Map) return;
      final map = Map<String, dynamic>.from(v);
      final lite = map['lite'];
      liteSubscription = lite is Map
          ? OcLiteSubscription.fromJson(Map<String, dynamic>.from(lite))
          : null;
      usageRows = _recordsFrom(map['usageRows']);
      allUsage = _recordsFrom(map['allUsage']);
      usageLoadedAt = DateTime.tryParse(map['loadedAt']?.toString() ?? '');
      usageError = null;
      AppLogger.i('usage cache loaded: ${usageRows.length}/${allUsage.length}');
    } catch (e) {
      AppLogger.w('load usage cache failed: $e');
    }
  }

  Future<void> _saveUsageCache() async {
    try {
      await _usageCacheFile.writeAsString(
        jsonEncode({
          'lite': liteSubscription?.toJson(),
          'usageRows': usageRows.map((e) => e.toJson()).toList(),
          'allUsage': allUsage.map((e) => e.toJson()).toList(),
          'loadedAt': usageLoadedAt?.toIso8601String(),
        }),
        flush: true,
      );
    } catch (e) {
      AppLogger.w('save usage cache failed: $e');
    }
  }

  Future<void> _loadCostCache() async {
    try {
      if (!await _costCacheFile.exists()) return;
      final raw = await _costCacheFile.readAsString();
      final v = jsonDecode(raw);
      if (v is! Map) return;
      costCache = {
        for (final entry in v.entries)
          if (entry.value is Map)
            entry.key.toString(): OcCostData.fromJson(
              Map<String, dynamic>.from(entry.value as Map),
            ),
      };
      AppLogger.i('cost cache loaded: ${costCache.length} months');
    } catch (e) {
      AppLogger.w('load cost cache failed: $e');
    }
  }

  Future<void> _saveCostCache() async {
    try {
      await _costCacheFile.writeAsString(
        jsonEncode({
          for (final entry in costCache.entries)
            entry.key: entry.value.toJson(),
        }),
        flush: true,
      );
    } catch (e) {
      AppLogger.w('save cost cache failed: $e');
    }
  }

  void _clearCachedData() {
    liteSubscription = null;
    usageRows = [];
    allUsage = [];
    usageError = null;
    usageLoadedAt = null;
    costCache = {};
  }

  Future<void> _deleteCacheFiles() async {
    for (final file in [_usageCacheFile, _costCacheFile]) {
      try {
        if (await file.exists()) await file.delete();
      } catch (_) {}
    }
  }

  static List<OcUsageRecord> _recordsFrom(Object? value) {
    if (value is! List) return [];
    return value
        .whereType<Map>()
        .map((e) => OcUsageRecord.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<Map<String, dynamic>> _loadSettings() async {
    try {
      if (!await _settingsFile.exists()) return {};
      final raw = await _settingsFile.readAsString();
      final v = jsonDecode(raw);
      return v is Map ? Map<String, dynamic>.from(v) : {};
    } catch (e) {
      AppLogger.w('load settings failed: $e');
      return {};
    }
  }

  Future<void> _saveSettings() async {
    try {
      await _settingsFile.writeAsString(
        jsonEncode({
          'themePreference': themePreference.name,
          'locale': locale.name,
          'autoRefreshMinutes': autoRefreshMinutes,
          'devMode': devMode,
          'alertThresholds': alertThresholds.toJson(),
          'syncConfig': syncConfig.toJson(),
        }),
        flush: true,
      );
    } catch (e) {
      AppLogger.w('save settings failed: $e');
    }
  }
}
