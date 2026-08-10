# 让 Mac 朋友帮忙测试

## 朋友电脑需要先装

- macOS 12 或更高版本
- Xcode（从 App Store 安装）
- Flutter 稳定版
- CocoaPods（可选，Flutter 提示时再装）

检查环境：

```bash
flutter doctor
```

`Xcode` 和 `macOS` 两项通过即可。

## 测试步骤

1. 把完整源码包解压：

```bash
unzip TokenKakeibo-1.2.1-macos-source.zip
cd TokenKakeibo-1.2.1-macos-source/token_kakeibo
```

2. 安装依赖：

```bash
flutter pub get
```

3. 直接运行测试：

```bash
flutter run -d macos
```

或者打正式 Release：

```bash
flutter build macos --release
```

也可以直接执行项目里的脚本：

```bash
bash tools/build_macos.sh
```

## 产物位置

```text
build/macos/Build/Products/Release/Token家计薄.app
```

## 如果打不开

未签名的应用第一次打开可能被 Gatekeeper 拦截，在终端执行：

```bash
xattr -dr com.apple.quarantine "build/macos/Build/Products/Release/Token家计薄.app"
```

然后重新打开即可。

## 测试重点

- 登录 opencode，确认 WebView 能正常打开
- 查看 Go 用量条、成本柱状图、历史、模型消耗
- 切换简体中文 / 繁體中文 / 日本語 / English
- 切换 和纸 / 墨色 主题
- 拉伸窗口宽度，确认图表日期和柱宽自适应
