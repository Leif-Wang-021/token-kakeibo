import 'package:flutter/material.dart';

/// 支持的语言：简体中文（默认）、繁體中文、日本語、English。
enum AppLocale {
  zhHans,
  zhHant,
  ja,
  en;

  static AppLocale fromId(String? id) => AppLocale.values.firstWhere(
    (l) => l.name == id,
    orElse: () => AppLocale.zhHans,
  );

  String get label => switch (this) {
    AppLocale.zhHans => '简体中文',
    AppLocale.zhHant => '繁體中文',
    AppLocale.ja => '日本語',
    AppLocale.en => 'English',
  };

  Locale get locale => switch (this) {
    AppLocale.zhHans => const Locale('zh', 'CN'),
    AppLocale.zhHant => const Locale('zh', 'TW'),
    AppLocale.ja => const Locale('ja'),
    AppLocale.en => const Locale('en'),
  };
}

/// 轻量 i18n：四套文案表 + 取值方法。
class L10n {
  const L10n(this.locale);

  final AppLocale locale;

  static const _zhHans = <String, String>{
    'appTitle': 'Token家计薄',
    'appTagline': '「Token家计薄」 — 安静，笃定。',
    'navUsage': '使用量',
    'navSettings': '设置',
    'navHistory': '历史',
    'navModels': '模型',
    'searchModels': '搜索模型',

    // 登录
    'loginTitle': '登录 OpenCode',
    'loginSubtitle': '登录后即可查看 Go 套餐多模型用量与成本',
    'loginOpenBrowser': '打开登录页',
    'loginWaiting': '正在等待登录…',
    'loginSuccess': '登录成功',
    'loginFailed': '登录失败，请重试',
    'loginSessionExpired': '会话已失效，请重新登录',
    'loginWorkspaceIdLabel': 'Workspace ID',
    'loginWorkspaceIdHint': '登录成功后自动识别；如失败可手动填写（wrk_ 开头）',
    'loginUrlLabel': '登录地址',
    'loginWelcome': '已登录',
    'loginWorkspace': 'Workspace',

    // Cost 柱状图
    'costTitle': '成本',
    'costSubtitle': '按模型细分的用量成本',
    'costAllModels': '所有模型',
    'costAllKeys': '所有密钥',
    'costDeletedSuffix': '（已删除）',
    'costSubscriptionShort': '订阅',
    'costEmpty': '本月暂无用量数据',
    'costGoSuffix': '（Go）',

    // Usage 表格
    'usageTitle': '使用历史',
    'usageSubtitle': '近期 API 使用情况和成本',
    'usageEmpty': '暂无使用记录',
    'usageDate': '日期',
    'usageModel': '模型',
    'usageInput': '输入',
    'usageOutput': '输出',
    'usageCost': '成本',
    'usageSession': '会话',
    'breakdownInput': '输入',
    'breakdownCacheRead': '缓存读取',
    'breakdownCacheWrite': '缓存写入',
    'breakdownOutput': '输出',
    'breakdownReasoning': '推理',
    'planBlack': 'Black（\$amount）',
    'planLite': 'Go（\$amount）',
    'planByok': 'BYOK（\$amount）',

    // 设置
    'settingsTitle': '设置',
    'settingsLanguage': '语言',
    'settingsTheme': '主题',
    'themeSystem': '跟随系统',
    'themeLight': '和纸',
    'themeDark': '墨色',
    'settingsAccount': '账户',
    'logout': '退出登录',
    'logoutConfirm': '确定要退出登录吗？',
    'logoutDone': '已退出登录',
    'version': '版本',

    // 通用
    'loading': '加载中…',
    'refresh': '刷新',
    'retry': '重试',
    'error': '错误',
    'empty': '暂无数据',
    'close': '关闭',
    'cancel': '取消',
    'confirm': '确定',
    'logViewerTitle': '日志',
    'noLogs': '暂无日志',
    'copyLogs': '复制日志',
    'logsCopied': '已复制到剪贴板',
    'openLogDir': '打开日志目录',

    // Go 用量
    'goUsageTitle': 'Go 用量',
    'goUsageSubtitle': '订阅套餐的用量限制与重置时间',
    'goRollingUsage': '滚动用量（5 小时）',
    'goWeeklyUsage': '每周用量',
    'goMonthlyUsage': '每月用量',
    'goResetsIn': '重置于',
    'goRateLimited': '已达用量上限',

    // 模型消耗
    'modelConsumptionTitle': '模型消耗',
    'modelConsumptionSubtitle': '按模型汇总的 token 使用量',
    'mcThisMonth': '本月',
    'mcAll': '全部',
    'mcInput': '输入',
    'mcOutput': '输出',
    'mcCache': '缓存',
    // 设置分组与分类
    'settingsGroupGeneral': '通用',
    'settingsGroupAccount': '账户',
    'settingsGroupUsage': '用量',
    'settingsGroupDev': '开发者',
    'settingsGroupAbout': '其他',
    'settingsAppearance': '外观',
    'settingsAppearanceDesc': '语言与主题',
    'settingsAutoRefresh': '自动刷新',
    'settingsAutoRefreshDesc': '定期刷新用量数据',
    'settingsAccountInfo': '账户信息',
    'settingsAccountInfoDesc': '登录状态与退出登录',
    'settingsAlert': '额度预警',
    'settingsAlertDesc': '用量达到阈值时通知',
    'settingsDevOptions': '开发者选项',
    'settingsDevOptionsDesc': '测试通知等调试工具',
    'settingsAboutDesc': '版本与开源信息',
    // 自动刷新
    'refreshOff': '关闭',
    'refreshMinutes': '每 {n} 分钟',
    'refreshDesc': '自动刷新间隔；关闭则手动刷新',
    // 额度预警
    'alertTitle': '额度预警',
    'alertSubtitle': '设置用量阈值，达到后发送系统通知',
    'alertRolling': '滚动用量（5 小时）阈值',
    'alertWeekly': '每周用量阈值',
    'alertMonthly': '每月用量阈值',
    'alertPercent': '{n}%',
    'alertSaved': '预警设置已保存',
    // 开发者
    'devTitle': '开发者选项',
    'devTestNotification': '发送测试通知',
    'devTestNotificationDesc': '验证系统通知是否正常工作',
    'devModeLabel': '开发者模式',
    'devModeDesc': '已通过连续点击版本号开启',
    'devEnabled': '开发者模式已开启',
    // 关于
    'aboutTitle': '关于',
    'aboutDesc': 'Token家计薄 · 专注 opencode Go 套餐用量',
    'settingsAbout': '关于',
    'aboutTapHint': '连续点击当前版本 5 次开启开发者模式',
    'aboutDevOpened': '开发者模式已开启',
    'settingsSync': '多端同步',
    'settingsSyncDesc': '通过 WebDAV 同步设置与登录态',
    'syncTitle': '多端同步',
    'syncSubtitle': '把设置与登录态同步到你的 WebDAV 网盘，多设备保持一致',
    'syncEnabled': '启用同步',
    'syncUrl': 'WebDAV 地址',
    'syncUrlHint': 'https://webdav.example.com/dav/',
    'syncUsername': '用户名',
    'syncPassword': '密码',
    'syncSave': '保存并同步',
    'syncNow': '立即同步',
    'syncSaved': '同步配置已保存',
    'syncLastAt': '上次同步',
    'syncNever': '从未同步',
    'syncStatus': '同步状态',
    'syncDone': '同步成功',
    'syncFail': '同步失败',
    'aboutProject': '项目',
    'aboutExternal': '外部链接',
    'aboutData': '数据与日志',
    'aboutOpenSource': '开源',
    'aboutDevSection': '开发者',
    'aboutDataDir': '数据目录',
    'aboutDataDirDesc': '账户、设置、日志存储在这里',
    'aboutOpenUsage': 'OpenCode 用量页',
    'aboutOpenUsageDesc': '在浏览器中查看官方用量',
    'aboutSourceCode': 'OpenCode 官网',
    'aboutSourceCodeDesc': 'OpenCode 官方产品与文档',
    'aboutLicense': '开源许可证',
    'aboutLicenseDesc': '字体与依赖许可信息',
    'aboutLogs': '错误日志',
    'aboutLogsDesc': '查看最近的应用日志',
    'aboutOpenDir': '打开数据目录',
    'aboutProjectHome': '项目主页',
    'aboutProjectHomeDesc': '项目源码与 Release 地址',
    'aboutUpdate': '应用更新',
    'aboutCurrentVersion': '当前版本',
    'updateCheck': '检查更新',
    'updateCheckDesc': '从 GitHub Releases 检查新版本',
    'updateChecking': '检查中…',
    'updateAvailable': '发现新版本',
    'updateNoUpdate': '当前已是最新版本',
    'updateCurrent': '当前版本',
    'updateLatest': '最新版本',
    'updateReleaseNotes': '更新内容',
    'updateOpenRelease': '打开 Release',
    'updateFailed': '检查更新失败，请稍后重试',
    'devDisable': '关闭开发者模式',
    'devDisableDesc': '退出开发者模式并隐藏开发者选项',
  };

  static const _zhHant = <String, String>{
    'appTitle': 'Token家計薄',
    'appTagline': '「Token家計薄」 — 安靜，篤定。',
    'navUsage': '使用量',
    'navSettings': '設定',
    'navHistory': '歷史',
    'navModels': '模型',
    'searchModels': '搜尋模型',

    'loginTitle': '登入 OpenCode',
    'loginSubtitle': '登入後即可查看 Go 方案多模型用量與成本',
    'loginOpenBrowser': '開啟登入頁',
    'loginWaiting': '正在等待登入…',
    'loginSuccess': '登入成功',
    'loginFailed': '登入失敗，請重試',
    'loginSessionExpired': '工作階段已失效，請重新登入',
    'loginWorkspaceIdLabel': 'Workspace ID',
    'loginWorkspaceIdHint': '登入成功後自動辨識；如失敗可手動填寫（wrk_ 開頭）',
    'loginUrlLabel': '登入網址',
    'loginWelcome': '已登入',
    'loginWorkspace': 'Workspace',

    'costTitle': '成本',
    'costSubtitle': '依模型細分的用量成本',
    'costAllModels': '所有模型',
    'costAllKeys': '所有金鑰',
    'costDeletedSuffix': '（已刪除）',
    'costSubscriptionShort': '訂閱',
    'costEmpty': '本月暫無用量資料',
    'costGoSuffix': '（Go）',

    'usageTitle': '使用歷史',
    'usageSubtitle': '近期 API 使用情況和成本',
    'usageEmpty': '暫無使用記錄',
    'usageDate': '日期',
    'usageModel': '模型',
    'usageInput': '輸入',
    'usageOutput': '輸出',
    'usageCost': '成本',
    'usageSession': '工作階段',
    'breakdownInput': '輸入',
    'breakdownCacheRead': '快取讀取',
    'breakdownCacheWrite': '快取寫入',
    'breakdownOutput': '輸出',
    'breakdownReasoning': '推理',
    'planBlack': 'Black（\$amount）',
    'planLite': 'Go（\$amount）',
    'planByok': 'BYOK（\$amount）',

    'settingsTitle': '設定',
    'settingsLanguage': '語言',
    'settingsTheme': '主題',
    'themeSystem': '跟隨系統',
    'themeLight': '和紙',
    'themeDark': '墨色',
    'settingsAccount': '帳戶',
    'logout': '登出',
    'logoutConfirm': '確定要登出嗎？',
    'logoutDone': '已登出',
    'version': '版本',

    'loading': '載入中…',
    'refresh': '重新整理',
    'retry': '重試',
    'error': '錯誤',
    'empty': '暫無資料',
    'close': '關閉',
    'cancel': '取消',
    'confirm': '確定',
    'logViewerTitle': '日誌',
    'noLogs': '暫無日誌',
    'copyLogs': '複製日誌',
    'logsCopied': '已複製到剪貼簿',
    'openLogDir': '開啟日誌目錄',

    'goUsageTitle': 'Go 用量',
    'goUsageSubtitle': '訂閱方案的用量限制與重置時間',
    'goRollingUsage': '滾動用量（5 小時）',
    'goWeeklyUsage': '每週用量',
    'goMonthlyUsage': '每月用量',
    'goResetsIn': '重設於',
    'goRateLimited': '已達用量上限',
    'modelConsumptionTitle': '模型消耗',
    'modelConsumptionSubtitle': '按模型彙總的 token 使用量',
    'mcThisMonth': '本月',
    'mcAll': '全部',
    'mcInput': '輸入',
    'mcOutput': '輸出',
    'mcCache': '快取',
    'settingsGroupGeneral': '通用',
    'settingsGroupAccount': '帳戶',
    'settingsGroupUsage': '用量',
    'settingsGroupDev': '開發者',
    'settingsGroupAbout': '其他',
    'settingsAppearance': '外觀',
    'settingsAppearanceDesc': '語言與主題',
    'settingsAutoRefresh': '自動重新整理',
    'settingsAutoRefreshDesc': '定期更新用量資料',
    'settingsAccountInfo': '帳戶資訊',
    'settingsAccountInfoDesc': '登入狀態與登出',
    'settingsAlert': '額度預警',
    'settingsAlertDesc': '用量達到閾值時通知',
    'settingsDevOptions': '開發者選項',
    'settingsDevOptionsDesc': '測試通知等除錯工具',
    'settingsAboutDesc': '版本與開源資訊',
    'refreshOff': '關閉',
    'refreshMinutes': '每 {n} 分鐘',
    'refreshDesc': '自動更新間隔；關閉則手動更新',
    'alertTitle': '額度預警',
    'alertSubtitle': '設定用量閾值，達到後發送系統通知',
    'alertRolling': '滾動用量（5 小時）閾值',
    'alertWeekly': '每週用量閾值',
    'alertMonthly': '每月用量閾值',
    'alertPercent': '{n}%',
    'alertSaved': '預警設定已儲存',
    'devTitle': '開發者選項',
    'devTestNotification': '發送測試通知',
    'devTestNotificationDesc': '驗證系統通知是否正常運作',
    'devModeLabel': '開發者模式',
    'devModeDesc': '已透過連續點擊版本號開啟',
    'devEnabled': '開發者模式已開啟',
    'aboutTitle': '關於',
    'aboutDesc': 'Token家計薄 · 專注 opencode Go 方案用量',
    'settingsAbout': '關於',
    'aboutTapHint': '連續點擊目前版本 5 次開啟開發者模式',
    'aboutDevOpened': '開發者模式已開啟',
    'settingsSync': '多端同步',
    'settingsSyncDesc': '透過 WebDAV 同步設定與登入狀態',
    'syncTitle': '多端同步',
    'syncSubtitle': '把設定與登入狀態同步到你的 WebDAV 網盤，多裝置保持一致',
    'syncEnabled': '啟用同步',
    'syncUrl': 'WebDAV 位址',
    'syncUrlHint': 'https://webdav.example.com/dav/',
    'syncUsername': '使用者名稱',
    'syncPassword': '密碼',
    'syncSave': '儲存並同步',
    'syncNow': '立即同步',
    'syncSaved': '同步設定已儲存',
    'syncLastAt': '上次同步',
    'syncNever': '從未同步',
    'syncStatus': '同步狀態',
    'syncDone': '同步成功',
    'syncFail': '同步失敗',
    'aboutProject': '專案',
    'aboutExternal': '外部連結',
    'aboutData': '資料與日誌',
    'aboutOpenSource': '開源',
    'aboutDevSection': '開發者',
    'aboutDataDir': '資料目錄',
    'aboutDataDirDesc': '帳戶、設定、日誌存放在這裡',
    'aboutOpenUsage': 'OpenCode 用量頁',
    'aboutOpenUsageDesc': '在瀏覽器中查看官方用量',
    'aboutSourceCode': 'OpenCode 官網',
    'aboutSourceCodeDesc': 'OpenCode 官方產品與文件',
    'aboutLicense': '開源授權',
    'aboutLicenseDesc': '字型與依賴授權資訊',
    'aboutLogs': '錯誤日誌',
    'aboutLogsDesc': '查看最近的應用日誌',
    'aboutOpenDir': '開啟資料目錄',
    'aboutProjectHome': '專案首頁',
    'aboutProjectHomeDesc': '專案原始碼與 Release 位址',
    'aboutUpdate': '應用程式更新',
    'aboutCurrentVersion': '目前版本',
    'updateCheck': '檢查更新',
    'updateCheckDesc': '從 GitHub Releases 檢查新版本',
    'updateChecking': '檢查中…',
    'updateAvailable': '發現新版本',
    'updateNoUpdate': '目前已是最新版本',
    'updateCurrent': '目前版本',
    'updateLatest': '最新版本',
    'updateReleaseNotes': '更新內容',
    'updateOpenRelease': '開啟 Release',
    'updateFailed': '檢查更新失敗，請稍後重試',
    'devDisable': '關閉開發者模式',
    'devDisableDesc': '退出開發者模式並隱藏開發者選項',
  };

  static const _ja = <String, String>{
    'appTitle': 'Token家計簿',
    'appTagline': '「Token家計簿」 — 静かで、確か。',
    'navUsage': '使用量',
    'navSettings': '設定',
    'navHistory': '履歴',
    'navModels': 'モデル',
    'searchModels': 'モデルを検索',

    'loginTitle': 'OpenCode にログイン',
    'loginSubtitle': 'ログインすると Go プランのモデル別使用量・コストを確認できます',
    'loginOpenBrowser': 'ログインページを開く',
    'loginWaiting': 'ログイン待機中…',
    'loginSuccess': 'ログイン成功',
    'loginFailed': 'ログインに失敗しました',
    'loginSessionExpired': 'セッションが無効です。再ログインしてください',
    'loginWorkspaceIdLabel': 'Workspace ID',
    'loginWorkspaceIdHint': 'ログイン後に自動認識。失敗時は手動入力（wrk_ で始まる）',
    'loginUrlLabel': 'ログイン URL',
    'loginWelcome': 'ログイン済み',
    'loginWorkspace': 'Workspace',

    'costTitle': 'コスト',
    'costSubtitle': 'モデル別の使用コスト',
    'costAllModels': 'すべてのモデル',
    'costAllKeys': 'すべてのキー',
    'costDeletedSuffix': '（削除済み）',
    'costSubscriptionShort': 'サブスク',
    'costEmpty': '今月の使用量はありません',
    'costGoSuffix': '（Go）',

    'usageTitle': '利用履歴',
    'usageSubtitle': '最近の API 利用状況とコスト',
    'usageEmpty': '利用記録がありません',
    'usageDate': '日付',
    'usageModel': 'モデル',
    'usageInput': '入力',
    'usageOutput': '出力',
    'usageCost': 'コスト',
    'usageSession': 'セッション',
    'breakdownInput': '入力',
    'breakdownCacheRead': 'キャッシュ読み込み',
    'breakdownCacheWrite': 'キャッシュ書き込み',
    'breakdownOutput': '出力',
    'breakdownReasoning': '推論',
    'planBlack': 'Black（\$amount）',
    'planLite': 'Go（\$amount）',
    'planByok': 'BYOK（\$amount）',

    'settingsTitle': '設定',
    'settingsLanguage': '言語',
    'settingsTheme': 'テーマ',
    'themeSystem': 'システムに従う',
    'themeLight': '和紙',
    'themeDark': '墨色',
    'settingsAccount': 'アカウント',
    'logout': 'ログアウト',
    'logoutConfirm': 'ログアウトしますか？',
    'logoutDone': 'ログアウトしました',
    'version': 'バージョン',

    'loading': '読み込み中…',
    'refresh': '更新',
    'retry': '再試行',
    'error': 'エラー',
    'empty': 'データがありません',
    'close': '閉じる',
    'cancel': 'キャンセル',
    'confirm': '確定',
    'logViewerTitle': 'ログ',
    'noLogs': 'ログがありません',
    'copyLogs': 'ログをコピー',
    'logsCopied': 'クリップボードにコピーしました',
    'openLogDir': 'ログフォルダを開く',

    'goUsageTitle': 'Go 使用量',
    'goUsageSubtitle': 'サブスクリプションの使用量制限とリセット時間',
    'goRollingUsage': 'ローリング使用量（5時間）',
    'goWeeklyUsage': '週間使用量',
    'goMonthlyUsage': '月間使用量',
    'goResetsIn': 'リセット',
    'goRateLimited': '使用量上限に達しました',
    'modelConsumptionTitle': 'モデル消費',
    'modelConsumptionSubtitle': 'モデル別トークン使用量',
    'mcThisMonth': '今月',
    'mcAll': 'すべて',
    'mcInput': '入力',
    'mcOutput': '出力',
    'mcCache': 'キャッシュ',
    'settingsGroupGeneral': '一般',
    'settingsGroupAccount': 'アカウント',
    'settingsGroupUsage': '使用量',
    'settingsGroupDev': '開発者',
    'settingsGroupAbout': 'その他',
    'settingsAppearance': '外観',
    'settingsAppearanceDesc': '言語とテーマ',
    'settingsAutoRefresh': '自動更新',
    'settingsAutoRefreshDesc': '使用量データを定期的に更新',
    'settingsAccountInfo': 'アカウント情報',
    'settingsAccountInfoDesc': 'ログイン状態とログアウト',
    'settingsAlert': '使用量アラート',
    'settingsAlertDesc': '使用量がしきい値に達したら通知',
    'settingsDevOptions': '開発者オプション',
    'settingsDevOptionsDesc': '通知テストなどのデバッグツール',
    'settingsAboutDesc': 'バージョンとオープンソース情報',
    'refreshOff': 'オフ',
    'refreshMinutes': '{n}分ごと',
    'refreshDesc': '自動更新間隔。オフの場合は手動更新',
    'alertTitle': '使用量アラート',
    'alertSubtitle': '使用量しきい値を設定し、到達時に通知',
    'alertRolling': 'ローリング使用量（5時間）しきい値',
    'alertWeekly': '週間使用量しきい値',
    'alertMonthly': '月間使用量しきい値',
    'alertPercent': '{n}%',
    'alertSaved': 'アラート設定を保存しました',
    'devTitle': '開発者オプション',
    'devTestNotification': 'テスト通知を送信',
    'devTestNotificationDesc': 'システム通知が動作するか確認',
    'devModeLabel': '開発者モード',
    'devModeDesc': 'バージョンを5回タップして有効化',
    'devEnabled': '開発者モードを有効にしました',
    'aboutTitle': 'このアプリについて',
    'aboutDesc': 'Token家計簿 · opencode Go プラン使用量向け',
    'settingsAbout': 'このアプリについて',
    'aboutTapHint': '現在のバージョンを5回タップで開発者モード',
    'aboutDevOpened': '開発者モードを有効にしました',
    'settingsSync': '多端末同期',
    'settingsSyncDesc': 'WebDAV で設定とログイン状態を同期',
    'syncTitle': '多端末同期',
    'syncSubtitle': 'WebDAV クラウドに設定とログイン状態を同期',
    'syncEnabled': '同期を有効化',
    'syncUrl': 'WebDAV URL',
    'syncUrlHint': 'https://webdav.example.com/dav/',
    'syncUsername': 'ユーザー名',
    'syncPassword': 'パスワード',
    'syncSave': '保存して同期',
    'syncNow': '今すぐ同期',
    'syncSaved': '同期設定を保存しました',
    'syncLastAt': '最終同期',
    'syncNever': '同期なし',
    'syncStatus': '同期状態',
    'syncDone': '同期成功',
    'syncFail': '同期失敗',
    'aboutProject': 'プロジェクト',
    'aboutExternal': '外部リンク',
    'aboutData': 'データとログ',
    'aboutOpenSource': 'オープンソース',
    'aboutDevSection': '開発者',
    'aboutDataDir': 'データディレクトリ',
    'aboutDataDirDesc': 'アカウント・設定・ログの保存先',
    'aboutOpenUsage': 'OpenCode 利用量ページ',
    'aboutOpenUsageDesc': 'ブラウザで公式の利用量を確認',
    'aboutSourceCode': 'OpenCode 公式サイト',
    'aboutSourceCodeDesc': 'OpenCode 公式プロダクトとドキュメント',
    'aboutLicense': 'オープンソースライセンス',
    'aboutLicenseDesc': 'フォントと依存ライセンス情報',
    'aboutLogs': 'エラーログ',
    'aboutLogsDesc': '最近のアプリログを表示',
    'aboutOpenDir': 'データディレクトリを開く',
    'aboutProjectHome': 'プロジェクトホーム',
    'aboutProjectHomeDesc': 'ソースコードと Release の URL',
    'aboutUpdate': 'アプリ更新',
    'aboutCurrentVersion': '現在のバージョン',
    'updateCheck': '更新を確認',
    'updateCheckDesc': 'GitHub Releases から新しいバージョンを確認',
    'updateChecking': '確認中…',
    'updateAvailable': '新しいバージョンがあります',
    'updateNoUpdate': '現在は最新バージョンです',
    'updateCurrent': '現在のバージョン',
    'updateLatest': '最新バージョン',
    'updateReleaseNotes': '更新内容',
    'updateOpenRelease': 'Release を開く',
    'updateFailed': '更新確認に失敗しました。後でもう一度お試しください',
    'devDisable': '開発者モードをオフ',
    'devDisableDesc': '開発者モードを終了し、開発者オプションを隠す',
  };

  static const _en = <String, String>{
    'appTitle': 'Token Kakeibo',
    'appTagline': '「Token Kakeibo」 — quiet, steady.',
    'navUsage': 'Usage',
    'navSettings': 'Settings',
    'navHistory': 'History',
    'navModels': 'Models',
    'searchModels': 'Search models',

    'loginTitle': 'Sign in to OpenCode',
    'loginSubtitle': 'Sign in to view Go plan usage and costs by model',
    'loginOpenBrowser': 'Open sign-in page',
    'loginWaiting': 'Waiting for sign-in…',
    'loginSuccess': 'Signed in',
    'loginFailed': 'Sign-in failed, please retry',
    'loginSessionExpired': 'Session expired, please sign in again',
    'loginWorkspaceIdLabel': 'Workspace ID',
    'loginWorkspaceIdHint':
        'Detected automatically after sign-in; fill manually if needed (starts with wrk_)',
    'loginUrlLabel': 'Sign-in URL',
    'loginWelcome': 'Signed in',
    'loginWorkspace': 'Workspace',

    'costTitle': 'Cost',
    'costSubtitle': 'Usage costs broken down by model.',
    'costAllModels': 'All Models',
    'costAllKeys': 'All Keys',
    'costDeletedSuffix': '(deleted)',
    'costSubscriptionShort': 'sub',
    'costEmpty': 'No usage data for this month',
    'costGoSuffix': ' (go)',

    'usageTitle': 'Usage History',
    'usageSubtitle': 'Recent API usage and costs.',
    'usageEmpty': 'No usage records yet',
    'usageDate': 'Date',
    'usageModel': 'Model',
    'usageInput': 'Input',
    'usageOutput': 'Output',
    'usageCost': 'Cost',
    'usageSession': 'Session',
    'breakdownInput': 'Input',
    'breakdownCacheRead': 'Cache Read',
    'breakdownCacheWrite': 'Cache Write',
    'breakdownOutput': 'Output',
    'breakdownReasoning': 'Reasoning',
    'planBlack': 'Black (\$amount)',
    'planLite': 'Go (\$amount)',
    'planByok': 'BYOK (\$amount)',

    'settingsTitle': 'Settings',
    'settingsLanguage': 'Language',
    'settingsTheme': 'Theme',
    'themeSystem': 'System',
    'themeLight': 'Washi',
    'themeDark': 'Sumi',
    'settingsAccount': 'Account',
    'logout': 'Sign out',
    'logoutConfirm': 'Sign out?',
    'logoutDone': 'Signed out',
    'version': 'Version',

    'loading': 'Loading…',
    'refresh': 'Refresh',
    'retry': 'Retry',
    'error': 'Error',
    'empty': 'No data',
    'close': 'Close',
    'cancel': 'Cancel',
    'confirm': 'OK',
    'logViewerTitle': 'Logs',
    'noLogs': 'No logs yet',
    'copyLogs': 'Copy logs',
    'logsCopied': 'Copied to clipboard',
    'openLogDir': 'Open log folder',

    'goUsageTitle': 'Go Usage',
    'goUsageSubtitle': 'Subscription usage limits and reset times',
    'goRollingUsage': 'Rolling Usage (5 hours)',
    'goWeeklyUsage': 'Weekly Usage',
    'goMonthlyUsage': 'Monthly Usage',
    'goResetsIn': 'Resets in',
    'goRateLimited': 'Usage limit reached',
    'modelConsumptionTitle': 'Model Consumption',
    'modelConsumptionSubtitle': 'Token usage by model',
    'mcThisMonth': 'This Month',
    'mcAll': 'All',
    'mcInput': 'Input',
    'mcOutput': 'Output',
    'mcCache': 'Cache',
    'settingsGroupGeneral': 'General',
    'settingsGroupAccount': 'Account',
    'settingsGroupUsage': 'Usage',
    'settingsGroupDev': 'Developer',
    'settingsGroupAbout': 'Other',
    'settingsAppearance': 'Appearance',
    'settingsAppearanceDesc': 'Language & theme',
    'settingsAutoRefresh': 'Auto Refresh',
    'settingsAutoRefreshDesc': 'Refresh usage data periodically',
    'settingsAccountInfo': 'Account',
    'settingsAccountInfoDesc': 'Sign-in status & sign out',
    'settingsAlert': 'Usage Alerts',
    'settingsAlertDesc': 'Notify when usage reaches thresholds',
    'settingsDevOptions': 'Developer Options',
    'settingsDevOptionsDesc': 'Test notifications & debug tools',
    'settingsAboutDesc': 'Version & open-source info',
    'refreshOff': 'Off',
    'refreshMinutes': 'Every {n} min',
    'refreshDesc': 'Auto-refresh interval; off = manual only',
    'alertTitle': 'Usage Alerts',
    'alertSubtitle': 'Set usage thresholds to get system notifications',
    'alertRolling': 'Rolling Usage (5h) threshold',
    'alertWeekly': 'Weekly Usage threshold',
    'alertMonthly': 'Monthly Usage threshold',
    'alertPercent': '{n}%',
    'alertSaved': 'Alert settings saved',
    'devTitle': 'Developer Options',
    'devTestNotification': 'Send Test Notification',
    'devTestNotificationDesc': 'Verify system notifications work',
    'devModeLabel': 'Developer Mode',
    'devModeDesc': 'Enabled by tapping the version 5 times',
    'devEnabled': 'Developer mode enabled',
    'aboutTitle': 'About',
    'aboutDesc': 'Token Kakeibo · focused on OpenCode Go usage',
    'settingsAbout': 'About',
    'aboutTapHint': 'Tap the current version 5 times to enable developer mode',
    'aboutDevOpened': 'Developer mode enabled',
    'settingsSync': 'Multi-device Sync',
    'settingsSyncDesc': 'Sync settings & sign-in via WebDAV',
    'syncTitle': 'Multi-device Sync',
    'syncSubtitle': 'Sync settings and sign-in state to your WebDAV drive',
    'syncEnabled': 'Enable sync',
    'syncUrl': 'WebDAV URL',
    'syncUrlHint': 'https://webdav.example.com/dav/',
    'syncUsername': 'Username',
    'syncPassword': 'Password',
    'syncSave': 'Save & Sync',
    'syncNow': 'Sync Now',
    'syncSaved': 'Sync settings saved',
    'syncLastAt': 'Last synced',
    'syncNever': 'Never',
    'syncStatus': 'Sync status',
    'syncDone': 'Sync succeeded',
    'syncFail': 'Sync failed',
    'aboutProject': 'Project',
    'aboutExternal': 'External links',
    'aboutData': 'Data & logs',
    'aboutOpenSource': 'Open source',
    'aboutDevSection': 'Developer',
    'aboutDataDir': 'Data directory',
    'aboutDataDirDesc': 'Accounts, settings and logs are stored here',
    'aboutOpenUsage': 'OpenCode usage page',
    'aboutOpenUsageDesc': 'Open the official usage page in a browser',
    'aboutSourceCode': 'OpenCode website',
    'aboutSourceCodeDesc': 'Official product and documentation',
    'aboutLicense': 'Open source licenses',
    'aboutLicenseDesc': 'Font and dependency licenses',
    'aboutLogs': 'Error logs',
    'aboutLogsDesc': 'View recent application logs',
    'aboutOpenDir': 'Open data directory',
    'aboutProjectHome': 'Project home',
    'aboutProjectHomeDesc': 'Source code and Release URL',
    'aboutUpdate': 'App updates',
    'aboutCurrentVersion': 'Current version',
    'updateCheck': 'Check for Updates',
    'updateCheckDesc': 'Check GitHub Releases for a new version',
    'updateChecking': 'Checking…',
    'updateAvailable': 'Update Available',
    'updateNoUpdate': 'You are up to date',
    'updateCurrent': 'Current version',
    'updateLatest': 'Latest version',
    'updateReleaseNotes': 'Release notes',
    'updateOpenRelease': 'Open Release',
    'updateFailed': 'Could not check for updates. Please try again later',
    'devDisable': 'Disable developer mode',
    'devDisableDesc': 'Exit developer mode and hide developer options',
  };

  Map<String, String> get _strings => switch (locale) {
    AppLocale.zhHans => _zhHans,
    AppLocale.zhHant => _zhHant,
    AppLocale.ja => _ja,
    AppLocale.en => _en,
  };

  String t(String key) => _strings[key] ?? key;

  String get appTitle => t('appTitle');
  String get appTagline => t('appTagline');
  String get navUsage => t('navUsage');
  String get navSettings => t('navSettings');
  String get navHistory => t('navHistory');
  String get navModels => t('navModels');
  String get searchModels => t('searchModels');

  String get loginTitle => t('loginTitle');
  String get loginSubtitle => t('loginSubtitle');
  String get loginOpenBrowser => t('loginOpenBrowser');
  String get loginWaiting => t('loginWaiting');
  String get loginSuccess => t('loginSuccess');
  String get loginFailed => t('loginFailed');
  String get loginSessionExpired => t('loginSessionExpired');
  String get loginWorkspaceIdLabel => t('loginWorkspaceIdLabel');
  String get loginWorkspaceIdHint => t('loginWorkspaceIdHint');
  String get loginUrlLabel => t('loginUrlLabel');
  String get loginWelcome => t('loginWelcome');
  String get loginWorkspace => t('loginWorkspace');

  String get costTitle => t('costTitle');
  String get costSubtitle => t('costSubtitle');
  String get costAllModels => t('costAllModels');
  String get costAllKeys => t('costAllKeys');
  String get costDeletedSuffix => t('costDeletedSuffix');
  String get costSubscriptionShort => t('costSubscriptionShort');
  String get costEmpty => t('costEmpty');
  String get costGoSuffix => t('costGoSuffix');

  String get usageTitle => t('usageTitle');
  String get usageSubtitle => t('usageSubtitle');
  String get usageEmpty => t('usageEmpty');
  String get usageDate => t('usageDate');
  String get usageModel => t('usageModel');
  String get usageInput => t('usageInput');
  String get usageOutput => t('usageOutput');
  String get usageCost => t('usageCost');
  String get usageSession => t('usageSession');
  String get breakdownInput => t('breakdownInput');
  String get breakdownCacheRead => t('breakdownCacheRead');
  String get breakdownCacheWrite => t('breakdownCacheWrite');
  String get breakdownOutput => t('breakdownOutput');
  String get breakdownReasoning => t('breakdownReasoning');

  /// plan 成本展示：Black/Go/BYOK（$金额）。
  String planLabel(String plan, double usd) => switch (plan) {
    'sub' => t('planBlack').replaceFirst('\$amount', usd.toStringAsFixed(4)),
    'lite' => t('planLite').replaceFirst('\$amount', usd.toStringAsFixed(4)),
    _ => t('planByok').replaceFirst('\$amount', usd.toStringAsFixed(4)),
  };

  String get settingsTitle => t('settingsTitle');
  String get settingsLanguage => t('settingsLanguage');
  String get settingsTheme => t('settingsTheme');
  String get themeSystem => t('themeSystem');
  String get themeLight => t('themeLight');
  String get themeDark => t('themeDark');
  String get settingsAccount => t('settingsAccount');
  String get logout => t('logout');
  String get logoutConfirm => t('logoutConfirm');
  String get logoutDone => t('logoutDone');
  String get settingsAbout => t('settingsAbout');
  String get settingsLogs => t('settingsLogs');
  String get version => t('version');

  String get loading => t('loading');
  String get refresh => t('refresh');
  String get retry => t('retry');
  String get error => t('error');
  String get empty => t('empty');
  String get close => t('close');
  String get cancel => t('cancel');
  String get confirm => t('confirm');
  String get logViewerTitle => t('logViewerTitle');
  String get noLogs => t('noLogs');
  String get copyLogs => t('copyLogs');
  String get logsCopied => t('logsCopied');
  String get openLogDir => t('openLogDir');
  String get goUsageTitle => t('goUsageTitle');
  String get goUsageSubtitle => t('goUsageSubtitle');
  String get goRollingUsage => t('goRollingUsage');
  String get goWeeklyUsage => t('goWeeklyUsage');
  String get goMonthlyUsage => t('goMonthlyUsage');
  String get goResetsIn => t('goResetsIn');
  String get goRateLimited => t('goRateLimited');
  String get modelConsumptionTitle => t('modelConsumptionTitle');
  String get modelConsumptionSubtitle => t('modelConsumptionSubtitle');
  String get mcThisMonth => t('mcThisMonth');
  String get mcAll => t('mcAll');
  String get mcInput => t('mcInput');
  String get mcOutput => t('mcOutput');
  String get mcCache => t('mcCache');

  // 设置分组与分类
  String get settingsGroupGeneral => t('settingsGroupGeneral');
  String get settingsGroupAccount => t('settingsGroupAccount');
  String get settingsGroupUsage => t('settingsGroupUsage');
  String get settingsGroupDev => t('settingsGroupDev');
  String get settingsGroupAbout => t('settingsGroupAbout');
  String get settingsSync => t('settingsSync');
  String get settingsSyncDesc => t('settingsSyncDesc');
  String get syncTitle => t('syncTitle');
  String get syncSubtitle => t('syncSubtitle');
  String get syncEnabled => t('syncEnabled');
  String get syncUrl => t('syncUrl');
  String get syncUrlHint => t('syncUrlHint');
  String get syncUsername => t('syncUsername');
  String get syncPassword => t('syncPassword');
  String get syncSave => t('syncSave');
  String get syncNow => t('syncNow');
  String get syncSaved => t('syncSaved');
  String get syncLastAt => t('syncLastAt');
  String get syncNever => t('syncNever');
  String get syncStatus => t('syncStatus');
  String get syncDone => t('syncDone');
  String get syncFail => t('syncFail');
  String get settingsAppearance => t('settingsAppearance');
  String get settingsAppearanceDesc => t('settingsAppearanceDesc');
  String get settingsAutoRefresh => t('settingsAutoRefresh');
  String get settingsAutoRefreshDesc => t('settingsAutoRefreshDesc');
  String get settingsAccountInfo => t('settingsAccountInfo');
  String get settingsAccountInfoDesc => t('settingsAccountInfoDesc');
  String get settingsAlert => t('settingsAlert');
  String get settingsAlertDesc => t('settingsAlertDesc');
  String get settingsDevOptions => t('settingsDevOptions');
  String get settingsDevOptionsDesc => t('settingsDevOptionsDesc');
  String get settingsAboutDesc => t('settingsAboutDesc');

  // 自动刷新
  String get refreshOff => t('refreshOff');
  String refreshMinutes(int n) => t('refreshMinutes').replaceFirst('{n}', '$n');
  String get refreshDesc => t('refreshDesc');

  // 额度预警
  String get alertTitle => t('alertTitle');
  String get alertSubtitle => t('alertSubtitle');
  String get alertRolling => t('alertRolling');
  String get alertWeekly => t('alertWeekly');
  String get alertMonthly => t('alertMonthly');
  String alertPercent(int n) => t('alertPercent').replaceFirst('{n}', '$n');
  String get alertSaved => t('alertSaved');

  // 开发者
  String get devTitle => t('devTitle');
  String get devTestNotification => t('devTestNotification');
  String get devTestNotificationDesc => t('devTestNotificationDesc');
  String get devModeLabel => t('devModeLabel');
  String get devModeDesc => t('devModeDesc');
  String get devEnabled => t('devEnabled');

  // 关于
  String get aboutTitle => t('aboutTitle');
  String get aboutDesc => t('aboutDesc');
  String get aboutTapHint => t('aboutTapHint');
  String get aboutDevOpened => t('aboutDevOpened');
  String get aboutProject => t('aboutProject');
  String get aboutExternal => t('aboutExternal');
  String get aboutData => t('aboutData');
  String get aboutOpenSource => t('aboutOpenSource');
  String get aboutDevSection => t('aboutDevSection');
  String get aboutDataDir => t('aboutDataDir');
  String get aboutDataDirDesc => t('aboutDataDirDesc');
  String get aboutOpenUsage => t('aboutOpenUsage');
  String get aboutOpenUsageDesc => t('aboutOpenUsageDesc');
  String get aboutSourceCode => t('aboutSourceCode');
  String get aboutSourceCodeDesc => t('aboutSourceCodeDesc');
  String get aboutLicense => t('aboutLicense');
  String get aboutLicenseDesc => t('aboutLicenseDesc');
  String get aboutLogs => t('aboutLogs');
  String get aboutLogsDesc => t('aboutLogsDesc');
  String get aboutOpenDir => t('aboutOpenDir');
  String get aboutProjectHome => t('aboutProjectHome');
  String get aboutProjectHomeDesc => t('aboutProjectHomeDesc');
  String get aboutUpdate => t('aboutUpdate');
  String get aboutCurrentVersion => t('aboutCurrentVersion');
  String get updateCheck => t('updateCheck');
  String get updateCheckDesc => t('updateCheckDesc');
  String get updateChecking => t('updateChecking');
  String get updateAvailable => t('updateAvailable');
  String get updateNoUpdate => t('updateNoUpdate');
  String get updateCurrent => t('updateCurrent');
  String get updateLatest => t('updateLatest');
  String get updateReleaseNotes => t('updateReleaseNotes');
  String get updateOpenRelease => t('updateOpenRelease');
  String get updateFailed => t('updateFailed');
  String get devDisable => t('devDisable');
  String get devDisableDesc => t('devDisableDesc');

  /// 用量重置时间："重置于 3小时12分" / "Resets in 3h 12m"。
  String resetTime(int seconds) {
    final h = seconds ~/ 3600;
    final m = (seconds % 3600) ~/ 60;
    if (h > 0) {
      return locale == AppLocale.en ? '${h}h ${m}m' : '$h小时$m分';
    }
    return locale == AppLocale.en ? '${m}m' : '$m分';
  }

  /// 月份选择器标签：2026年8月 / August 2026。
  String monthLabel(int year, int month) {
    const zh = ['1', '2', '3', '4', '5', '6', '7', '8', '9', '10', '11', '12'];
    const enShort = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return switch (locale) {
      AppLocale.zhHans || AppLocale.zhHant => '$year年${zh[month - 1]}月',
      AppLocale.ja => '$year年$month月',
      AppLocale.en => '${enShort[month - 1]} $year',
    };
  }

  /// 表格日期列：本地化 "8月9日 14:31" / "Aug 9, 2:31 PM"。
  String tableDate(DateTime d) {
    final local = d.toLocal();
    final h = local.hour;
    final m = local.minute.toString().padLeft(2, '0');
    switch (locale) {
      case AppLocale.zhHans || AppLocale.zhHant:
        return '${local.month}月${local.day}日 $h:$m';
      case AppLocale.ja:
        return '${local.month}月${local.day}日 $h:$m';
      case AppLocale.en:
        final ampm = h >= 12 ? 'PM' : 'AM';
        final h12 = h % 12 == 0 ? 12 : h % 12;
        return '${_enMonthsShort[local.month - 1]} ${local.day}, $h12:$m $ampm';
    }
  }

  /// 图表 x 轴标签：紧凑 "8/9"（避免与相邻标签重叠拥挤）。
  String chartDayLabel(DateTime d) {
    switch (locale) {
      case AppLocale.zhHans || AppLocale.zhHant || AppLocale.ja:
        return '${d.month}/${d.day}';
      case AppLocale.en:
        return '${_enMonthsShort[d.month - 1]} ${d.day.toString().padLeft(2, '0')}';
    }
  }

  /// 图表 y 轴刻度：$1.2k / $5 / $0.5（小数去尾零，避免 $0 $1 重复）。
  static String chartYTick(double v) {
    if (v >= 1000) {
      return '\$${(v / 1000).toStringAsFixed(1)}k';
    }
    if (v == v.roundToDouble()) {
      return '\$${v.toStringAsFixed(0)}';
    }
    final s = v.toStringAsFixed(2);
    return '\$${s.replaceFirst(RegExp(r'\.?0+$'), '')}';
  }

  /// 图表 tooltip 值：$0.02。
  static String chartTooltip(double v) => '\$${v.toStringAsFixed(2)}';

  static const _enMonthsShort = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
}
