#!/usr/bin/env python3
"""Generate the shared app icon for Windows, Android, and macOS."""

import os
from PIL import Image, ImageDraw, ImageFont

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
ASSET_ICON = os.path.join(ROOT, "assets", "icon", "app_icon.png")
FONT_CANDIDATES = [
    os.path.join(os.environ.get("WINDIR", r"C:\Windows"), "Fonts", "yuminl.ttf"),
    os.path.join(ROOT, "tools", "fonts", "ShipporiMincho-Regular.ttf"),
]

WASHI = (247, 243, 238, 255)
SHU = (201, 64, 47, 255)
GOLD = (201, 162, 39, 255)
WHITE = (255, 255, 255, 255)


def rounded_mask(size, radius):
    mask = Image.new("L", (size, size), 0)
    draw = ImageDraw.Draw(mask)
    draw.rounded_rectangle((0, 0, size - 1, size - 1), radius=radius, fill=255)
    return mask


def make_icon(size):
    scale = size / 1024.0
    img = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    mask = rounded_mask(size, int(210 * scale))
    draw = ImageDraw.Draw(img)
    draw.rounded_rectangle(
        (0, 0, size - 1, size - 1),
        radius=int(210 * scale),
        fill=SHU,
    )
    try:
        font = None
        for candidate in FONT_CANDIDATES:
            try:
                font = ImageFont.truetype(candidate, int(620 * scale))
                break
            except Exception:
                continue
        if font is None:
            raise RuntimeError("no wafu font available")
    except Exception:
        font = ImageFont.load_default()
    text = "薄"
    bbox = draw.textbbox((0, 0), text, font=font)
    tw = bbox[2] - bbox[0]
    th = bbox[3] - bbox[1]
    draw.text(
        (
            (size - tw) / 2 - bbox[0],
            (size - th) / 2 - bbox[1] + int(24 * scale),
        ),
        text,
        font=font,
        fill=WHITE,
    )
    img.putalpha(mask)
    return img


def save_pngs(img):
    os.makedirs(os.path.dirname(ASSET_ICON), exist_ok=True)
    img.save(ASSET_ICON)

    android_res = os.path.join(ROOT, "android", "app", "src", "main", "res")
    for folder, size in [
        ("mipmap-mdpi", 48),
        ("mipmap-hdpi", 72),
        ("mipmap-xhdpi", 96),
        ("mipmap-xxhdpi", 144),
        ("mipmap-xxxhdpi", 192),
    ]:
        path = os.path.join(android_res, folder, "ic_launcher.png")
        os.makedirs(os.path.dirname(path), exist_ok=True)
        make_icon(size).save(path)

    ico_path = os.path.join(
        ROOT, "windows", "runner", "resources", "app_icon.ico"
    )
    img.save(
        ico_path,
        sizes=[(16, 16), (24, 24), (32, 32), (48, 48), (64, 64), (256, 256)],
    )

    mac_iconset = os.path.join(
        ROOT,
        "macos",
        "Runner",
        "Assets.xcassets",
        "AppIcon.appiconset",
    )
    if os.path.isdir(mac_iconset):
        for name, size in [
            ("app_icon_16.png", 16),
            ("app_icon_32.png", 32),
            ("app_icon_32.png", 32),
            ("app_icon_64.png", 64),
            ("app_icon_128.png", 128),
            ("app_icon_256.png", 256),
            ("app_icon_256.png", 256),
            ("app_icon_512.png", 512),
            ("app_icon_512.png", 512),
            ("app_icon_1024.png", 1024),
        ]:
            make_icon(size).save(os.path.join(mac_iconset, name))


if __name__ == "__main__":
    save_pngs(make_icon(1024))
    print("icons generated")
