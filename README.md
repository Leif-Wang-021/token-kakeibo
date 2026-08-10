# Token家计薄

> 本地优先的 OpenCode Go 套餐用量与成本查看器。
>
> 支持 Windows、Android，并提供 macOS 源码工程；界面为和风朱红风格，内置思源宋体。

![License](https://img.shields.io/badge/License-GPL--3.0-red)
![Platform](https://img.shields.io/badge/Platform-Windows%20%7C%20Android%20%7C%20macOS-blue)
![Flutter](https://img.shields.io/badge/Flutter-M3-3b82f6)

## 这是什么

Token家计薄用于集中查看 **opencode.ai** 的 Go 套餐用量：

- 应用内 WebView2 登录 opencode，自动保存会话 cookie 与 Workspace ID
- Go 套餐滚动 / 每周 / 每月用量条和重置时间
- 月度成本堆叠柱状图，支持按模型、按密钥筛选
- 使用历史明细，支持 token 输入、输出、缓存、推理拆分
- 模型消耗汇总，支持本月 / 全部切换
- 额度预警、自动刷新、WebDAV 多端同步
- 简体中文、繁體中文、日本語、English 四语言
- 和纸 / 墨色两套主题，内置 Noto Serif SC 可变字体
- 应用内检查更新，从 GitHub Releases 获取最新版本
- 支持 120Hz / ProMotion 高刷新率，高刷设备上自动解锁最高刷新率

## 项目说明

本项目采用 **Vibe Coding** 方式开发：人类负责产品方向、需求、验收与发布，AI 负责代码生成、调试和持续迭代。开发过程、逆向工程笔记和踩坑记录都写在 [docs/DEVELOPMENT_LOG.md](docs/DEVELOPMENT_LOG.md)。

界面布局参考了开源项目 [Kazumi](https://github.com/Predidit/Kazumi) 的 Material 3 设置页、分组卡片、导航和关于页结构；配色、字体和应用名做了独立的和风设计。具体声明见 [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md)。

## 功能细节

### 使用量

- 顶部显示 Go 套餐三条用量限制：滚动 5 小时 / 每周 / 每月
- 月度成本柱状图只显示有数据的日期，窄屏自动抽稀日期标签
- 窄屏合并为单根堆叠柱，宽屏按 plan 分为 BYOK / Black / Go 三组
- 鼠标悬停显示模型和金额

### 历史

- 全部使用记录按时间倒序展示
- 点击记录查看输入、输出、缓存读取、缓存写入、推理 token 明细

### 模型

- 按模型聚合 token 总量和占比
- 本月 / 全部切换，缓存 token 用橙色单独显示

### 设置与关于

- 设置页分组：账户 / 通用 / 其他
- 关于页：开源许可、项目主页、数据目录、日志、当前版本、检查更新
- 关于页“项目主页”点击直接打开 GitHub 仓库
- 点击当前版本 5 次开启开发者模式，开发者页面可发送测试通知

## 技术栈

| 模块 | 技术 |
| --- | --- |
| 应用框架 | Flutter / Dart 3.9+ / Material 3 |
| 状态管理 | provider + ChangeNotifier |
| 图表 | fl_chart 1.2+ |
| 高刷新率 | refresh_rate |
| 登录与 WebView | webview_flutter + vendored webview_win_floating（含 getCookies 原生扩展） |
| 通知 | Windows toast（AUMID）+ Android 原生 MethodChannel |
| 数据存储 | `%LOCALAPPDATA%/token_kakeibo`（Windows）、应用支持目录（其他平台） |
| 更新检查 | GitHub Releases API |
| 开源许可 | GPL-3.0 |

## 目录结构

```text
lib/
├── app.dart                     # MaterialApp、语言与主题
├── main.dart                    # 启动、许可证注册、数据目录迁移
├── l10n/                        # 四语言文案
├── models/                      # opencode 数据模型、会话、配置
├── services/                    # API、seroval、会话、通知、WebDAV、更新检查
├── state/app_state.dart         # 全局状态与缓存
├── pages/                       # 使用量、历史、模型、设置、关于、登录、日志
├── theme/                       # 和纸 / 墨色主题与颜色
└── widgets/                     # 柱状图、用量条、模型消耗
```

## 构建

### Windows

```bash
flutter pub get
flutter build windows --release
```

生成 Inno Setup 安装包：

```bash
"C:/Users/26981/AppData/Local/Programs/Inno Setup 6/ISCC.exe" installer/token_kakeibo_setup.iss
```

### Android

```bash
flutter build apk --release
```

产物位于 `build/app/outputs/flutter-apk/app-release.apk`。

发布版本会统一放在 `dist/`：

```text
dist/
├── TokenKakeibo-1.2.1-windows-setup.exe
├── TokenKakeibo-1.2.1-android.apk
└── TokenKakeibo-1.2.1-macos-source.zip
```

### macOS

当前 Windows 开发机无法直接构建 macOS 包。项目内已包含完整 `macos/` 工程，Mac 朋友可参考 [docs/MAC_TEST_GUIDE.md](docs/MAC_TEST_GUIDE.md) 构建测试。

## 检查更新与发布

- 应用内：设置 → 关于 → 应用更新 → 检查更新
- 发布：打标签后把 Windows 安装包和 Android APK 上传到 GitHub Releases

## 数据目录

| 平台 | 路径 |
| --- | --- |
| Windows | `%LOCALAPPDATA%\token_kakeibo\` |
| Android / macOS | 应用支持目录下的 `token_kakeibo` |

数据目录包含登录会话、设置、WebView2 数据、缓存和日志。卸载 Windows 安装包不会删除用户数据。

## 测试

```bash
flutter analyze
flutter test
```

测试覆盖 seroval 编解码、opencode 数据模型和关键解析逻辑。

## 许可证

- 项目代码：GNU General Public License v3.0
- UI 参考 Kazumi：GPL-3.0，见 [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md)
- Noto Serif SC / Shippori Mincho：SIL Open Font License 1.1
- 其他 Flutter 依赖遵循各自开源许可证

## 免责声明

本项目与 opencode.ai 无官方关联，使用非公开 server-function RPC 接口读取用量数据；若 opencode 调整接口，本应用可能失效并需要更新。请勿将本项目用于违反 opencode 服务条款的行为。
