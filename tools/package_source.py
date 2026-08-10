#!/usr/bin/env python3
"""Package a clean, buildable source zip for sharing with a macOS tester."""

import os
import zipfile

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT = os.path.join(ROOT, "dist", "TokenKakeibo-1.2.0-macos-source.zip")

EXCLUDED_DIRS = {
    ".git",
    ".dart_tool",
    ".idea",
    "build",
    "dist",
    "output",
    "archive",
    "_moved_old_builds",
}

EXCLUDED_FILES = {
    "old_apk_temp.apk",
    "TokenKakeibo-安卓版.apk",
    "chat_log_full_2026-08-04.md",
    "openusage_alibaba.md",
    "bailian_home.html",
    "help_usage.html",
}

def main():
    os.makedirs(os.path.dirname(OUT), exist_ok=True)
    if os.path.exists(OUT):
        os.remove(OUT)
    with zipfile.ZipFile(OUT, "w", zipfile.ZIP_DEFLATED, compresslevel=9) as zf:
        for dirpath, dirnames, filenames in os.walk(ROOT):
            rel = os.path.relpath(dirpath, ROOT)
            parts = rel.split(os.sep)
            if any(part in EXCLUDED_DIRS for part in parts):
                continue
            for name in filenames:
                if name in EXCLUDED_FILES:
                    continue
                src = os.path.join(dirpath, name)
                arc = os.path.join("token_kakeibo", rel, name)
                zf.write(src, arc)
    print(f"packaged: {OUT}")


if __name__ == "__main__":
    main()
