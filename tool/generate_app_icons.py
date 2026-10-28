"""アプリのアイコンを、元画像(assets/app-icon-b-sun-sprout-1024.png)から書き出す。

使い方(リポジトリの直下で。Pillowが必要: `python -m pip install pillow`):
    python tool/generate_app_icons.py

書き出すもの:
- Android: 従来のアイコン(mipmap-*/ic_launcher.png)と、適応アイコン(API 26以上)の
  前景(mipmap-*/ic_launcher_foreground.png)。背景は単色(元画像の地の色)。
  dev(別の端末に両方入れたとき見分けるため)は、下の中央に「DEV」の札をつけた別のアイコン
  (android/app/src/dev/res/)。
- iOS: AppIcon.appiconset の各サイズ(角は丸めない。端末側で丸くなる。透過なし)。
- 起動画面: アイコンと同じ絵を、同じ地の色の上に、中央に出す(Android 12以上はシステムの
  起動画面、11以下は launch_background.xml、iOSは LaunchImage と LaunchScreen.storyboard)。
"""

import json
import re
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parent.parent
SOURCE = ROOT / "assets" / "app-icon-b-sun-sprout-1024.png"
ANDROID_RES = ROOT / "android" / "app" / "src" / "main" / "res"
ANDROID_DEV_RES = ROOT / "android" / "app" / "src" / "dev" / "res"
IOS_SET = ROOT / "ios" / "Runner" / "Assets.xcassets" / "AppIcon.appiconset"
IOS_LAUNCH = ROOT / "ios" / "Runner" / "Assets.xcassets" / "LaunchImage.imageset"
IOS_STORYBOARD = ROOT / "ios" / "Runner" / "Base.lproj" / "LaunchScreen.storyboard"

# 従来のアイコン(dp 48)と、適応アイコンの前景(dp 108)の、密度ごとの倍率。
DENSITIES = {"mdpi": 1.0, "hdpi": 1.5, "xhdpi": 2.0, "xxhdpi": 3.0, "xxxhdpi": 4.0}

# 適応アイコンは、中央の約66%だけが、必ず見える。太陽の光とふた葉が欠けないよう、
# 元の絵を、前景の70%に収める。
FOREGROUND_SCALE = 0.70


def background_color(image: Image.Image) -> tuple[int, int, int]:
    """元画像の地の色(四隅の平均)。"""
    w, h = image.size
    corners = [image.getpixel(p) for p in [(2, 2), (w - 3, 2), (2, h - 3), (w - 3, h - 3)]]
    return tuple(round(sum(c[i] for c in corners) / 4) for i in range(3))


def with_dev_badge(image: Image.Image) -> Image.Image:
    """下の中央に「DEV」の札をつける(開発用のアイコンと分かるように)。
    適応アイコンの円で切り取られても欠けない位置・大きさにしている。"""
    size = image.size[0]
    out = image.convert("RGBA").copy()
    draw = ImageDraw.Draw(out)
    width, height = int(size * 0.40), int(size * 0.17)
    left, top = (size - width) // 2, int(size * 0.80)
    draw.rounded_rectangle(
        (left, top, left + width, top + height),
        radius=height // 2,
        fill=(248, 121, 101, 255),
        outline=(255, 255, 255, 255),
        width=max(2, size // 160),
    )
    font = ImageFont.load_default(size=int(height * 0.68))
    draw.text((size // 2, top + height // 2), "DEV", fill="white", font=font, anchor="mm")
    return out.convert("RGB")


def foreground(image: Image.Image, canvas: int, color) -> Image.Image:
    """適応アイコンの前景: 地の色の正方形に、元の絵を縮めて中央に置く。"""
    out = Image.new("RGB", (canvas, canvas), color)
    inner = round(canvas * FOREGROUND_SCALE)
    resized = image.resize((inner, inner), Image.LANCZOS)
    offset = (canvas - inner) // 2
    out.paste(resized, (offset, offset))
    return out


def write_android(image: Image.Image, res_dir: Path, color) -> None:
    for name, scale in DENSITIES.items():
        folder = res_dir / f"mipmap-{name}"
        folder.mkdir(parents=True, exist_ok=True)
        image.resize((round(48 * scale), round(48 * scale)), Image.LANCZOS).save(
            folder / "ic_launcher.png", optimize=True
        )
        foreground(image, round(108 * scale), color).save(
            folder / "ic_launcher_foreground.png", optimize=True
        )


def write_ios(image: Image.Image) -> None:
    contents = json.loads((IOS_SET / "Contents.json").read_text(encoding="utf-8"))
    for entry in contents["images"]:
        points = float(entry["size"].split("x")[0])
        scale = int(entry["scale"].rstrip("x"))
        pixels = round(points * scale)
        image.resize((pixels, pixels), Image.LANCZOS).save(
            IOS_SET / entry["filename"], optimize=True
        )


LAUNCH_BACKGROUND = """<?xml version="1.0" encoding="utf-8"?>
<layer-list xmlns:android="http://schemas.android.com/apk/res/android">
    <item android:drawable="@color/ic_launcher_background" />
    <item>
        <bitmap
            android:gravity="center"
            android:src="@mipmap/ic_launcher_foreground" />
    </item>
</layer-list>
"""

# Android 12以上は、システムが起動画面を出す(中央にアイコン)。地の色を、アイコンと同じにする。
LAUNCH_STYLES_V31 = """<?xml version="1.0" encoding="utf-8"?>
<resources>
    <style name="LaunchTheme" parent="@android:style/Theme.Light.NoTitleBar">
        <item name="android:windowSplashScreenBackground">@color/ic_launcher_background</item>
        <item name="android:windowBackground">@drawable/launch_background</item>
    </style>
    <style name="NormalTheme" parent="@android:style/Theme.Light.NoTitleBar">
        <item name="android:windowBackground">?android:colorBackground</item>
    </style>
</resources>
"""


def write_launch(image: Image.Image, color) -> None:
    """起動画面。アイコンと同じ絵を、同じ地の色の上に、中央に出す。"""
    # iOS: 絵(168ポイント四方)を、1x/2x/3xで。背景色は、storyboardに書く。
    for suffix, scale in [("", 1), ("@2x", 2), ("@3x", 3)]:
        pixels = 168 * scale
        image.resize((pixels, pixels), Image.LANCZOS).save(
            IOS_LAUNCH / f"LaunchImage{suffix}.png", optimize=True
        )
    storyboard = IOS_STORYBOARD.read_text(encoding="utf-8")
    red, green, blue = (round(c / 255, 6) for c in color)
    storyboard = re.sub(
        r'<color key="backgroundColor" red="[^"]*" green="[^"]*" blue="[^"]*" '
        r'alpha="1" colorSpace="custom" customColorSpace="sRGB"/>',
        f'<color key="backgroundColor" red="{red}" green="{green}" blue="{blue}" '
        'alpha="1" colorSpace="custom" customColorSpace="sRGB"/>',
        storyboard,
        count=1,
    )
    IOS_STORYBOARD.write_text(storyboard, encoding="utf-8", newline="")

    # Android 11以下: 地の色の上に、絵を中央に出す(前景は、地の色と同じなので、つなぎ目が出ない)。
    for folder in ("drawable", "drawable-v21"):
        (ANDROID_RES / folder / "launch_background.xml").write_text(
            LAUNCH_BACKGROUND, encoding="utf-8"
        )
    styles = ANDROID_RES / "values-v31"
    styles.mkdir(parents=True, exist_ok=True)
    (styles / "styles.xml").write_text(LAUNCH_STYLES_V31, encoding="utf-8")


def main() -> None:
    source = Image.open(SOURCE).convert("RGB")
    color = background_color(source)
    print("地の色:", "#%02X%02X%02X" % color)

    write_android(source, ANDROID_RES, color)
    write_android(with_dev_badge(source), ANDROID_DEV_RES, color)
    write_ios(source)
    write_launch(source, color)

    (ANDROID_RES / "mipmap-anydpi-v26").mkdir(parents=True, exist_ok=True)
    (ANDROID_RES / "mipmap-anydpi-v26" / "ic_launcher.xml").write_text(
        '<?xml version="1.0" encoding="utf-8"?>\n'
        '<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">\n'
        '    <background android:drawable="@color/ic_launcher_background"/>\n'
        '    <foreground android:drawable="@mipmap/ic_launcher_foreground"/>\n'
        "</adaptive-icon>\n",
        encoding="utf-8",
    )
    (ANDROID_RES / "values" / "ic_launcher_background.xml").write_text(
        '<?xml version="1.0" encoding="utf-8"?>\n'
        "<resources>\n"
        '    <color name="ic_launcher_background">#%02X%02X%02X</color>\n'
        "</resources>\n" % color,
        encoding="utf-8",
    )
    print("書き出しました。")


if __name__ == "__main__":
    main()
