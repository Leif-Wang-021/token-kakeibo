# Token家计薄 — 完整开发日志（供 AI 接手参考）

> 项目：`F:\Codex Project\Token display\token_kakeibo`
> 类型：Flutter 多端应用（单 opencode 账户多模型用量查看器，Windows / Android / macOS）
> 最后更新：2026-08-11
> 本日志从零开始记录全部开发过程、逆向工程成果、架构决策与已知坑，供后续 AI 或开发者无缝接手。

## 开发方式：Vibe Coding

本项目由 **Vibe Coding** 方式开发：人类负责产品方向、需求、验收与发布，AI 负责代码生成、调试和持续迭代。
所有代码均由 AI 辅助编写，人类在每一轮给出业务判断和视觉反馈；界面大量借鉴 Kazumi 的 Material 3
结构与交互，配色、字体和文案做了独立设计。详见 `README.md` 与 `THIRD_PARTY_NOTICES.md`。

## 0. 2026-08-11 发布前整理（项目主页 / 更新检查 / 清理归档）

### 0.1 功能新增
- **项目主页可填写**：关于页“项目主页”显示当前 GitHub 地址，点击可编辑；保存到本地设置，默认指向
  `https://github.com/Leif-Wang-021/token-kakeibo`。
- **GitHub Release 检查更新**：设置 → 关于 → 应用更新 → 检查更新，从 GitHub Releases API 获取最新版本，
  比较版本号后提示“已是最新”或展示 Release 更新内容并打开 Release 页面。
- **统一二级菜单标题**：所有二级页 AppBar 标题统一走 `WafuTheme.appBarTheme.titleTextStyle`
  （headlineMedium + w700 + titleSpacing 24），移除各页面散落的 20px / 默认样式覆盖。
- **跨平台打开链接**：新增 `url_launcher`，关于页和更新页在 Windows / Android / macOS 上都能打开外部链接。

### 0.2 代码清理
- 删除 `settings_subpages.dart` 中从未使用的旧 `AboutPage` 副本，设置页改用独立 `about_page.dart`。
- 移走仓库内不再使用的 ZenMaruGothic / ZenOldMincho 字体、旧 OFL 文件、第三方插件备份和截图。
- `dart analyze` 达到 **No issues found**：顺手清掉第三方插件里的 unused import、print、deprecated Color.value 等。
- `flutter test`：16/16 通过。

### 0.3 目录归位与鸿蒙留档
- `F:\Codex` 下的旧构建副本和 `F:\token_kakeibo_build` 旧项目已移动到
  `F:\Codex Project\Token display\_moved_old_builds\`，工作区外不再散落本项目内容。
- HarmonyOS / OpenHarmony 相关文件统一归档到
  `F:\Codex Project\Token display\archive\harmonyos\`，并写 `README.md` 注明“已暂停，仅留档”。
- 主项目只保留 Windows、Android、macOS 三个目标。

### 0.4 文档与发布
- `README.md` 重写为详细版：功能介绍、Vibe Coding 说明、Kazumi 借鉴声明、目录结构、构建方法、
  数据目录、许可证和免责声明。
- 根据用户要求，README 截图已移除，截图文件归档在工作区 `archive/unused_assets/screenshots/`。
- 完成后推送 GitHub，并发布 Windows / Android / 源码 Release。

### 0.5 用户反馈修正（等待推送）
- 设置-关于-项目主页改为点击直接打开 GitHub 仓库，不再允许填写自定义地址。
- 关于页与其他设置二级页统一使用 `SettingsDetailScaffold`，修复“关于”标题大小不一致。
- 模型页窄屏改为紧凑卡片布局：模型名、token 数、进度条、百分比分层展示，避免右侧截断和底部重叠。
- 新增 `refresh_rate`，在支持 120Hz / ProMotion 的设备上自动解锁最高刷新率。

### 0.6 2026-08-11 v1.2.1 发布
- 版本号统一升级为 `1.2.1`。
- Windows 安装包、Android APK、macOS 源码包已重新构建并放入 `dist/`。
- 用户确认后提交、推送 GitHub，并创建 `v1.2.1` Release。

---

## 0. 2026-08-10 UI 重构（Kazumi 风格 + 和风字体）

### 0.1 完成的改动
- **主题**：`wafu_theme.dart` 改为 Kazumi 布局 + 和风朱红主题：和纸米白浅色、墨黑 OLED 深色、朱红主色，金色作点缀；M3 新版控件外观。
- **导航**：`root_page.dart` 改为 Kazumi 结构：窄屏底部 4 栏、宽屏左侧 NavigationRail + 搜索按钮，页面为 用量 / 历史 / 模型 / 设置。
- **设置页**：分组标题 + M3 split-list（外圆角 24 / 内圆角 4）分类卡片，图标改 tonal badge。
- **设置分类精简**：移除顶层“开发者”分组与“日志”卡片；日志、开发者入口移入关于页，设置只保留 账户 / 通用 / 其他 三组。
- **用量页**：Go 用量条、成本柱状图、模型消耗统一为 16px 圆角 surfaceContainerLow 卡片。
- **新增页面**：`history_page.dart`（使用历史卡片列表）、`model_page.dart`（模型消耗）。
- **关于页**：`about_page.dart` 仿 Kazumi，新增 项目信息、OpenCode 官网/用量页、数据目录、错误日志、开源许可、开发者模式 分区。
- **柱状图 x 轴自适应**：`cost_bar_chart.dart` 按宽度档位抽稀日期标签（<340px 每 5 天、<520px 每 3 天、<760px 每 2 天、其余每天），首尾日期始终显示，并在档位变化时强制重建图表。
- **柱宽自适应**：窄屏（<760px）每天合并为单根堆叠柱，柱宽约为日槽位的 72%；宽屏保持 3 根并排柱并自动缩放宽高，避免“柱细、空隙大”。
- **多语言清理**：搜索框提示、同步状态、错误提示、系统通知改为按当前语言显示；错误详情仅写日志，不再直接展示原始中文异常。
- **fl_chart 坑**：`SideTitles.interval` 对水平柱状图 x 轴不生效（内部会为每个 bar 生成标题），必须配合 `getTitlesWidget` 返回 `SizedBox.shrink()` 主动隐藏。
- **共享数据**：`AppState.loadUsageData()` 统一拉取 lite subscription + 历史 + 全量记录，三个页面共享，避免重复请求。
- **字体**：内置 Noto Serif SC 思源宋体 variable（OFL 开源），一个字体覆盖简中 / 繁中 / 日文，已注册并打进安装包。
- **参考源码**：Kazumi 官方仓库已浅克隆到 `F:\Codex Project\Token display\kazumi_reference`，UI 结构与主题均照其实现复刻。

### 0.2 Windows 上 Flutter 命令防卡死（重要）

**症状**：执行 `flutter.bat` / `dart.bat` 后任务“跑一半卡住”，无输出。

**根因**：Flutter 工具启动时要在 `D:\flutter_ohos\bin\cache\lockfile` 获取文件锁；在受限文件系统或
有其他 Flutter 进程持锁时，会无限等待且不输出。包装脚本还依赖 `where.exe` / 子 shell，容易在沙箱里挂起。

**对策（已写入 `C:\Users\26981\.codex\AGENTS.md`）**：
1. 不要运行 `flutter.bat` / `dart.bat`。
2. 纯 Dart 分析：
   ```
   "D:\flutter_ohos\bin\cache\dart-sdk\bin\dart.exe" analyze
   ```
3. Flutter 工具直连 snapshot（构建/测试/运行）：
   ```
   "D:\flutter_ohos\bin\cache\dart-sdk\bin\dart.exe" --packages="D:\flutter_ohos\packages\flutter_tools\.dart_tool\package_config.json" "D:\flutter_ohos\bin\cache\flutter_tools.snapshot" <命令>
   ```

### 0.3 验证结果
- `dart analyze`：0 error / 0 warning（仅 third_party 与少量 info）。
- `flutter test`：16/16 通过。
- `flutter build windows --release`：成功。
- Inno Setup：`installer/output/TokenKakeiboSetup.exe` 成功生成。

### 0.4 2026-08-10 三端封装
- 统一生成和风朱红“家”图标：`tools/generate_icons.py` 产出 Windows ICO、Android mipmap、macOS AppIcon.appiconset。
- 图标按用户反馈改为朱红底 + 和风字体细“薄”（Yu Mincho Light，回退 Shippori Mincho），已重新打包三端。
- Android 修复：用量/设置页 SafeArea 避让状态栏；通知改用原生 MethodChannel（`token_kakeibo/notifications`），不再依赖 `flutter_local_notifications`，避免 Windows ATL 构建问题。
- 启动缓存：用量、套餐、月度成本写入 `%LOCALAPPDATA%\token_kakeibo\usage_cache.json` / `cost_cache.json`，启动先显示缓存再后台刷新。
- 关于页：按 Kazumi 原版结构重做，只保留 开源 / 外部链接 / 存储与日志 / 应用更新 / 开发者 相关分区。
- Windows 干净构建注意：`flutter clean` 后 CMake 安装前缀会变成 `C:/Program Files/token_kakeibo`，需先用
  `cmake -DCMAKE_INSTALL_PREFIX=<项目>\build\windows\x64\runner\Release <项目>\windows` 重新配置，否则 INSTALL 步骤因无管理员权限失败。
- Windows：`dist/TokenKakeibo-1.2.0-windows-setup.exe`（Inno Setup 安装包，含字体和图标）。
- Android：`dist/TokenKakeibo-1.2.0-android.apk`（release，65.5MB，含字体和图标），已通过 Hermes Weixin 通道发送到微信。
- macOS：当前 Flutter-ohos 工具链没有 `build macos` 命令，Windows 无法产出 `.app/.dmg`；已生成完整 `macos/` 工程、图标、Bundle 名称和 `macos/BUILD.md`，并打包为 `dist/TokenKakeibo-1.2.0-macos-source.zip`。

---

## 1. 项目背景与目标

用户订阅了 **opencode Go 套餐**（`$10/月`，含 DeepSeek V4 Flash/Pro、Kimi、GLM、MiniMax、Qwen 等开放模型，额度约 5小时$12 / 周$30 / 月$60）。官方用量页 `https://opencode.ai/workspace/<id>/usage` 提供成本柱状图 + 使用历史表格，但用户希望有一个**本地桌面应用**集中查看：

- 单账户登录（WebView2 内嵌浏览器登录 opencode，提取会话）
- Cost 柱状图（按月、按模型、堆叠）——照官方页面复刻
- 模型消耗汇总（token 数、百分比、缓存）
- Go 套餐用量限制条（5h/周/月 + 重置时间）
- 额度预警（自定义阈值 → 系统通知）、自动刷新、WebDAV 多端同步、开发者选项

**2026-08-09 重构背景**：旧版是"多供应商 token 记账"（DeepSeek/OpenAI/Kimi/MiniMax/Qwen/智谱等 8 个适配器 + 多账户 UI + agent 模块），用户明确要求**彻底删除**旧供应商/多账户/agent，改为**单 opencode 账户**模式。旧代码已全部删除（45 个文件）。

---

## 2. 技术栈与依赖

```yaml
dependencies:
  flutter: sdk (Dart ^3.9.2, Material 3)
  http: ^1.6.0            # API 请求
  provider: ^6.1.5        # 状态管理（ChangeNotifier）
  fl_chart: ^1.2.0        # 柱状图（2026-08-10 从手绘迁移）
  url_launcher: ^6.3.1    # 跨平台打开项目主页 / Release 页面
  webview_flutter: ^4.13.1
  webview_win_floating: ^3.0.3  # Windows WebView2（vendor 于 third_party/，含 getCookies 原生扩展）
  flutter_desktop_notifications: ^1.1.2  # Windows toast 通知
  path_provider, cryptography
```

**关键**：`webview_win_floating` 被 vendor 到 `third_party/`（`dependency_overrides`），原生 C++ 层加了 `getCookies(uri:)` 方法（CookieManager.GetCookies，可读 httpOnly cookie）。

---

## 3. 目录结构（重构后）

```
lib/
├── main.dart                 # 入口：AppPaths → NotificationService.init → AppState.load
├── app.dart                  # MaterialApp（WafuTheme 明暗 + 4 语言）
├── l10n/                     # 手写 i18n（zhHans/zhHant/ja/en 四个 const map + getter）
├── models/
│   ├── opencode_data.dart    # OcCostRow/OcCostData/OcUsageRecord/OcBilling/OcLiteUsage/OcLiteSubscription
│   ├── opencode_session.dart # 登录态（cookie + workspaceId）
│   ├── sync_config.dart      # WebDAV 配置
│   └── theme_preference.dart
├── services/
│   ├── opencode_api.dart     # ★ 核心：server-function RPC 客户端
│   ├── seroval.dart          # ★ seroval 编解码（请求 wrapped + 响应 JS 流解析）
│   ├── session_store.dart    # 登录态持久化（%LOCALAPPDATA%\token_kakeibo\opencode_session.json）
│   ├── notification_service.dart  # toast 通知（AUMID 注册）
│   ├── webdav_sync.dart      # WebDAV PUT/GET/MKCOL
│   ├── app_logger.dart / app_paths.dart
│   └── app_info.dart / update_service.dart  # 版本、项目主页、GitHub 更新检查
├── state/app_state.dart      # 全局状态：会话/主题/预警阈值/自动刷新/WebDAV
├── pages/
│   ├── dashboard_page.dart   # 主界面（Go 用量条 + Cost 图 + 模型消耗）
│   ├── login_page.dart       # WebView2 登录 + cookie/workspace 提取
│   ├── settings_page.dart    # kazumi 风格分组设置主页
│   ├── settings_subpages.dart # 二级页（外观/自动刷新/账户/预警/同步/开发者/关于）
│   └── log_viewer_page.dart
├── widgets/
│   ├── cost_bar_chart.dart   # fl_chart 堆叠柱状图
│   ├── go_usage_bars.dart    # 5h/周/月用量进度条
│   └── model_consumption.dart # 模型 token 汇总（色点+进度条+百分比+缓存）
└── theme/wafu_*.dart         # 红色和风主题（和纸米白+朱红 / oled 纯黑深色）
```

---

## 4. ★ 核心逆向工程：opencode.ai 私有 API

**这是本项目最宝贵的技术资产**。opencode console（sst/opencode 开源仓库的 console 应用）的前端是 SolidStart，后端函数通过 **server function RPC** 暴露，无公开 REST 文档，全部逆向得出。

### 4.1 端点与函数 ID

所有请求：`POST https://opencode.ai/_server`（**URL 不带任何参数**），函数 ID 通过请求头 `X-Server-Id` 指定。

| 函数 | server function id（64 hex） | 参数 | 用途 |
|---|---|---|---|
| getCosts | `15702f3a12ff8bff357f8c2aa154a17e65b746d5f6b96adc9002c86ee0c15205` | `[workspaceId, year, month(0-based), tzOffset("+08:00")]` | 按月成本聚合 + 密钥列表 |
| getUsageInfo | `bfd684bfc2e4eed05cd0b518f5e4eafd3f3376e3938abb9e536e7c03df831e5c` | `[workspaceId, page]`（50 条/页倒序） | 用量历史明细 |
| querySessionInfo | `9bc4808361cdaee17059a8d3822b36ee8c9a0d93f1adc289fa1926998e3c9768` | `[workspaceId]` | 会话验证 → `{isAdmin, isBeta}` |
| queryLiteSubscription | `c7389bd0e731f80f49593e5ee53835475f4e28594dd6bd83eb229bab753498cd` | `[workspaceId]` | Go 套餐用量 → `{rollingUsage, weeklyUsage, monthlyUsage}`（已含 usagePercent/resetInSec） |
| queryBillingInfo | `c83b78a614689c38ebee981f9b39a8b377716db85c1fd7dbab604adc02d3313d` | `[workspaceId]` | 余额/月用量（备用） |

> ID 从生产 bundle（`/_build/assets/*.js`）用 `createServerReference("...")` 提取。**可能随版本更新失效**，失效时重新抓 bundle 提取。

### 4.2 请求格式（seroval cross-JSON）

**请求头**（与浏览器完全一致，2026-08-10 从 Copy as cURL 逆向）：
```
POST /_server
Content-Type: application/json
X-Server-Id: <64hex>
X-Server-Instance: server-fn:0
Cookie: oc_locale=zh; auth=<Iron session>
```

**请求体**（`JSON.stringify(Mo(args))`，seroval wrapped 格式）：
```json
{"t":{"t":9,"i":0,"l":4,"a":[
  {"t":1,"s":"wrk_01KZK4MHR3231NK6MCBBQKR47J"},
  {"t":0,"s":2026},{"t":0,"s":7},{"t":1,"s":"+08:00"}
],"o":0},"f":31,"m":[]}
```

**关键字段**（血泪教训，缺一不可）：
- `t`：crossJSON node。数组 node 结构 `{"t":9, "i":0, "l":<长度>, "a":[...], "o":0}`——**必须有 `l`（length）字段**！缺失会导致服务端把参数全解析成 undefined（表现为 `Invalid time value` / `got account` 错误）。
- 字符串 node `{"t":1,"s":"..."}`，数字 node `{"t":0,"s":N}`
- `f`：features 位掩码，**31**（Map|Set|Promise|Error|AggregateError；不是 127！127 也会被接受但 31 是浏览器实测值）
- `m`：marked 数组，`[]`

### 4.3 响应格式（JS 模式，SEROVAL_MODE=js）

服务端部署是 **SEROVAL_MODE=js**（`Content-Type: text/javascript`），响应是 **chunk 流 + crossSerialize JS 表达式**：

```
;0x00000d34;((self.$R=self.$R||{})["server-fn:0"]=[],($R=>$R[0]={usage:$R[1]=[...],keys:$R[2]=[...]})($R["server-fn:0"]))
```

- 每个 chunk：`;0x<8位hex长度>;` + JS 表达式
- 表达式是 **JS 对象/数组字面量**（key 不加引号），引用用 `$R[N]`（`$R[0]=` 赋值，后续 `$R[N]` 引用）
- **根值在最后一个 chunk**（拓扑序：引用定义在前，根在后）
- 错误响应：`Object.assign(new Error("消息"),{stack:"..."})`——解析器需提取 `new Error("...")` 消息
- Date 序列化：`new Date("2026-08-10T02:16:20.000Z")`
- bool：`!0`=true `!1`=false；null：`null`

**Dart 解析器**（`seroval.dart`）实现：
1. 按 `;0x` 头切 chunk
2. 先尝试 JSON node 解析（跨 chunk 共享 refs）
3. 失败则 JS 模式：提取核心表达式（剥掉 `((self.$R=...)["id"]=[],` 前缀和 `)($R["id"]))` 后缀），用自写 `_JsParser`（对象/数组/字符串/数字/`$R[N]` 引用/`new Date()`）解析，**最后一个 chunk 的值即根**

### 4.4 认证（WebView2 + Iron session）

- 登录流程：WebView2 打开 `https://opencode.ai/auth`（重定向到 openauth OAuth）→ 用户 GitHub/Google 登录 → 跳回 `/workspace/<id>/...` → 从 URL 提取 workspaceId
- **cookie 提取**：`getCookies()`（**不带 uri**，全域）→ `auth=Fe26.2**...`（hapi Iron sealed session，纯 ASCII）
- session cookie 名 `auth`，**httpOnly**（JS 读不到，必须原生 getCookies）
- 请求时 `Cookie: oc_locale=zh; auth=<值>`

### 4.5 时区坑（重要）

- `getCosts` 的第 4 参数 tzOffset 控制**按天分组**（`DATE(CONVERT_TZ(timeCreated, '+00:00', tz))`）
- 若传 `+00:00`（系统 UTC），柱状图日期与官方（浏览器本地时区）**错位**
- **必须传 `+08:00`**（用户在中国；官方浏览器也按 +08:00 分组）
- 注意：`CONVERT_TZ` 的偏移参数 `+08:00` 是 MySQL 合法格式；传 IANA 名（`Asia/Shanghai`）会报错

### 4.6 限流与稳定性

- 连续快速请求（分页拉全量）约第 12 页触发 **HTTP 503**（服务端限流）
- 对策：**页间延时 250ms + 503 退避重试（500ms×尝试次数，最多 3 次）**
- 实测全量 1347 条（约 27 页）可完整拉取

---

## 5. 数据模型

```dart
// getCosts 行：date 'YYYY-MM-DD'，cost 单位微美分（÷1e8 = $）
OcCostRow { date, model, totalCostMicroCents, keyId, plan }

// 密钥（柱状图筛选下拉）
OcKey { id, displayName, email-keyName, deleted }

// UsageTable 记录（getUsageInfo）
OcUsageRecord {
  model, provider, inputTokens, outputTokens, reasoningTokens,
  cacheReadTokens, cacheWrite5mTokens, cacheWrite1hTokens,
  costMicroCents, keyId, sessionId, plan, timeCreated
}
// 网页口径：totalInputTokens = input + cacheRead + cacheWrite5m + cacheWrite1h
// 缓存写入明细只在模型名含 "claude" 时展示

// Go 套餐用量（queryLiteSubscription，服务端已算好）
OcLiteUsage { usagePercent(0-100), resetInSec, status("ok"/"rate-limited") }
OcLiteSubscription { mine, useBalance, rollingUsage, weeklyUsage, monthlyUsage }
// 限制：rolling 5h $12 / weekly $30 / monthly $60（微美分计）
```

`OcPlan` 枚举：`regular`(BYOK) / `sub`(Black) / `lite`(Go)——柱状图按 plan 分三组独立堆叠。

---

## 6. UI 布局与交互

### 6.1 主界面（dashboard）

自上而下：
1. **Go 用量条**（`go_usage_bars.dart`）：3 个卡片（滚动 5h / 每周 / 每月），各含标签 + 百分比 + 进度条（rate-limited 时变红）+ 重置时间（"重置于 3小时17分"）
2. **成本柱状图**（`cost_bar_chart.dart`）：标题 + 月份选择器（`‹ 2026年8月 ›`）+ 模型下拉 + 密钥下拉 + 刷新按钮 + fl_chart 堆叠柱状图（400px 高）
3. **模型消耗**（`model_consumption.dart`）：本月/全部切换 + 模型行（色点 + 模型名 + 350ms 动画进度条 + 百分比 + token 数 + 橙色缓存增量）

### 6.2 柱状图（fl_chart）

**历史**：手绘 CustomPaint 版（x 轴标签拥挤、柱子重叠、hover 闪烁）→ 2026-08-10 **迁移到 fl_chart 1.2.0**，布局/刻度全自动。

- 每天一个 `BarChartGroupData`，`barRods` 最多 3 根（regular/sub/lite 并排）
- 每根 rod 用 `rodStackItems: [BarChartRodStackItem(fromY, toY, color)]` 按模型堆叠
- 颜色：`ModelColors.forModel()`（网页固定色表 + hash→hsl 兜底）
- plan 透明度：sub 50%、lite 35%（+ 边框色）
- y 轴：`L10n.chartYTick()`（$1.2k/$0.5，小数去尾零避免重复标签）
- tooltip：fl_chart 内置 BarTouchTooltipData（`模型: $0.02`）

### 6.3 设置页（kazumi 风格）

- 主页：**分组**（通用/账户/用量/开发者/关于）+ **分类卡片**（图标+标题+描述+箭头），点击 push 二级页
- 二级页：AppBar 大标题（headlineSmall 20px）+ ListView
- 分类：
  - 外观：语言 + 主题（**MenuAnchor 下拉**）
  - 自动刷新：关闭/5/10/15/30/60 分钟（RadioListTile）
  - 账户：登录信息 + 退出
  - 额度预警：滚动/每周/每月阈值滑杆（10-100%）
  - 多端同步：WebDAV URL/账号/密码 + 立即同步 + 状态
  - 开发者选项：发送测试通知
  - 关于：版本号**连点 5 次**开启开发者模式

### 6.4 主题（红色和风）

- `wafu_colors.dart`：和纸米白 `#F7F3EE` 背景、朱红 `#C9402F` 主色、墨色文字；深色 oled 纯黑（照 kazumi）
- 4 语言 i18n：`l10n.dart` 四个 const map（**注意：不要用脚本在 map 中间插块，极易产生重复 key/破坏结构——手动 patch 最稳**）

---

## 7. 功能清单与实现要点

### 7.1 登录（login_page.dart）
WebView2 → opencode.ai/auth → URL 正则 `/workspace/(wrk_[A-Za-z0-9]+)` 自动识别 → getCookies() 全域提取 → querySessionInfo 验证 → 保存 session

### 7.2 额度预警（AppState.checkAlerts）
每次刷新拉 queryLiteSubscription → 比较 usagePercent ≥ 阈值 → `NotificationService.show()` → 每级别只通知一次（`_notifiedLevels` Set，阈值变更后重置）

### 7.3 自动刷新（AppState）
`setAutoRefreshMinutes()` → Timer.periodic → `onAutoRefresh` 回调（dashboard 注册 `_refresh`）

### 7.4 通知（notification_service.dart）
**Windows 非打包应用必须注册 AUMID**：
```dart
await WindowsNotification.registerAumid(
  aumid: 'TokenKakeibo.TokenKakeibo', displayName: 'Token家计薄');
// 否则 toast 静默失败（无任何报错）
```

### 7.5 WebDAV 同步
- 文件：`{url}/token_kakeibo/settings.json` + `session.json`
- Basic Auth + PUT/GET/MKCOL
- **本地优先**：`syncConfig` 只在远端有有效 URL 时应用（防重装/远端异常覆盖本地）

### 7.6 开发者选项
关于页连点版本号 5 次 → `setDevMode(true)` → 开发者页出现测试通知按钮

---

## 8. 已知坑与教训（血泪清单）

1. **seroval `l` 字段缺失 → 参数全 undefined**（症状：`Invalid time value` / `Expected actor type user, got account`）。这是最难排查的 bug，最终靠浏览器 Copy as cURL 逆向解决。
2. **响应是 JS 模式不是 JSON**——不能 jsonDecode，需要自写 JS 表达式解析器。
3. **GET /_server 会被 auth 中间件 302 拦截**——必须 POST。
4. **URL 不要带 `?id=`**——函数 ID 走 X-Server-Id 头。
5. **hover 闪烁**：setState 每像素重建 → 用 ValueNotifier 隔离（后来 fl_chart 内置解决）。
6. **手绘柱状图布局问题**（标签挤/柱子重叠）→ **用 fl_chart**，别手绘。
7. **时区**：系统 UTC 时 getCosts 传 +00:00 导致按天错位，固定 +08:00。
8. **503 限流**：分页拉取加 250ms 延时 + 重试。
9. **l10n 大 map 用脚本插入极易破坏**（重复 key/双重 `};`/插错位置）——**手动 patch**。
10. **字体**：曾内置 50MB 霞鹜文楷（打包正常，在 `assets/fonts/` 而非 `fonts/`），用户要求改回默认后移除（安装包 30.5MB→13.2MB）。
11. **通知**：unpackaged 必须 registerAumid。
12. **WebView2 cookie 二进制**：Edge/WebView2 的 cookie DB 解密后值可能带二进制前缀，但 `ICoreWebView2Cookie::get_Value` 返回解码后的纯 ASCII（直接用即可）。
13. **电脑上 Edge 的 cookie DB 被独占锁**（sqlite 打不开），WebView2 的（EBWebView）在 app 关闭后可读（DPAPI+AES-GCM 解密，用于调试）。

---

## 9. 构建与发布

```bash
flutter pub get
flutter analyze          # 目标 0 error 0 warning（third_party 的警告忽略）
flutter test             # 16/16（seroval 编解码 + 数据模型）
flutter build windows --release
# 产物：build\windows\x64\runner\Release\token_kakeibo.exe
```

**安装包**：Inno Setup 6
```bash
"C:/Users/26981/AppData/Local/Programs/Inno Setup 6/ISCC.exe" installer/token_kakeibo_setup.iss
# 产物：installer/output/TokenKakeiboSetup.exe（13.2MB）
```
- 版本号在 `installer/token_kakeibo_setup.iss`（`MyAppVersion`）和 `settings_subpages.dart` 的关于页
- 数据目录 `%LOCALAPPDATA%\token_kakeibo\`（登录态/设置/日志），**卸载不删**（Inno `uninsneveruninstall`）

---

## 10. 测试

- `test/seroval_test.dart`：encodeArgs 格式（l 字段/f=31）+ JSON 流解码 + 错误处理
- `test/seroval_js_test.dart`：JS 模式响应（crossSerialize 对象/数组/多 chunk/`new Error`/`new Date`）
- `test/opencode_data_test.dart`：模型解析（cost 换算/token 合计/plan 映射）

---

## 11. 给接手 AI 的快速上手

1. 看 `lib/services/opencode_api.dart` + `seroval.dart`（协议核心）
2. 看 `lib/pages/dashboard_page.dart`（主界面数据流）
3. 调试 API：浏览器 Copy as cURL（打开 usage 页 F12 → Network → 右键 _server 请求）
4. 修改后：analyze + test + build + ISCC 出包
5. 日志：`%LOCALAPPDATA%\token_kakeibo\logs\`（AppLogger 按天分文件）
