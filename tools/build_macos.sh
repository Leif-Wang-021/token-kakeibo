#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

flutter pub get
flutter build macos --release

APP="build/macos/Build/Products/Release/Token家计薄.app"
echo
echo "Build finished: $APP"
open -R "$APP"
