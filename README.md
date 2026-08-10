# Token家计薄

集中查看 **OpenCode Go 套餐**（opencode-go）多模型 token 用量与成本的 Flutter Windows 应用。

## 功能

- **单账户登录**：应用内 WebView2 登录 opencode.ai（GitHub/Google OAuth），自动提取
  会话 cookie（含 httpOnly）与 workspace ID，本地保存登录态（`%LOCALAPPDATA%\token_kakeibo\`）。
- **成本柱状图**（照 opencode.ai usage 页面复刻）：
  - 按月查看，`‹ 2026年8月 ›` 月份切换
  - 按模型 / 按密钥筛选下拉
  - 每天三组堆叠柱（按量 / 订阅 / Go），模型颜色使用网页固定色表 + 哈希兜底
  - hover 显示 `模型: $0.02` tooltip
- **使用历史表格**：日期 / 模型 / 输入 / 输出 / 成本 / 会话，分页（50 条/页），
  token 明细弹出（输入 / 缓存读取 / 缓存写入 / 输出 / 推理）。
- 明暗两套主题，配色照 opencode 网页（Apple 系：`#007aff` 主色等）。
- UI 整体复刻 Kazumi（Material 3 split-list 设置页 + OLED 深色），配色改为和风朱红 / 和纸米白，内置 Noto Serif SC 思源宋体（覆盖简中 / 繁中 / 日文）。
- 4 语言：简体中文 / 繁體中文 / 日本語 / English。

## 数据来源

opencode.ai console 的 server-function RPC（`POST /_server?id=<serverFunctionId>`），
请求体为 seroval cross-JSON（`lib/services/seroval.dart` 实现编解码），
鉴权用登录提取的会话 cookie。端点 ID 从 production bundle 提取（2026-08）：

| 接口 | server function id |
| --- | --- |
| getCosts（按月成本聚合 + 密钥列表） | `15702f3a...` |
| getUsageInfo（用量历史分页） | `bfd684bf...` |
| queryBillingInfo（余额/月用量） | `c83b78a6...` |
| querySessionInfo（会话验证） | `9bc48083...` |

## 构建

```bash
# 不要直接运行 flutter.bat / dart.bat，它们可能因 SDK 缓存锁挂起。
# 纯分析：
"D:\flutter_ohos\bin\cache\dart-sdk\bin\dart.exe" analyze
# Flutter 命令（构建/测试）：
"D:\flutter_ohos\bin\cache\dart-sdk\bin\dart.exe" --packages="D:\flutter_ohos\packages\flutter_tools\.dart_tool\package_config.json" "D:\flutter_ohos\bin\cache\flutter_tools.snapshot" build windows --release
```

产物：`build\windows\x64\runner\Release\token_kakeibo.exe`

## 数据目录

- 登录态 / 设置：`%LOCALAPPDATA%\token_kakeibo\`
- WebView2 数据（cookie）：`%LOCALAPPDATA%\token_kakeibo\webview2\`
- 日志：`%LOCALAPPDATA%\token_kakeibo\logs\`（设置页可查看）
