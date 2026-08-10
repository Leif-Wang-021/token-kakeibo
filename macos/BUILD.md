# macOS 构建说明

当前开发机是 Windows + Flutter-ohos 工具链，Flutter-ohos 分支不支持
`flutter build macos`，因此这里只能准备 macOS 工程，不能直接在 Windows 上
产出 `.app` / `.dmg`。

在 macOS 上使用官方 Flutter 构建：

```bash
flutter pub get
flutter build macos --release
```

产物：

```text
build/macos/Build/Products/Release/Token家计薄.app
```

如需 `.dmg`，在 macOS 上用 `create-dmg` 打包：

```bash
create-dmg \
  --volname "Token家计薄" \
  --window-pos 200 120 \
  --window-size 800 500 \
  --icon-size 100 \
  "TokenKakeibo.dmg" \
  "build/macos/Build/Products/Release/Token家计薄.app"
```

macOS 图标、App 名称、Bundle ID 和字体均已随工程准备好。
