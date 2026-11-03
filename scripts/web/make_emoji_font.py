"""Web用の絵文字フォント(web/fonts/NotoColorEmoji-subset.woff2)を作る。

Webは、同梱のフォントに無い文字を、外部(fonts.gstatic.com)へ取りに行くが、CSPで外部は
許可しない。そのため、使う絵文字だけに絞ったフォントを、同じサイトに置く(docs/Web版の公開.md)。

使い方:
  python -m pip install fonttools brotli lxml
  # 元のフォント(約25MB。リポジトリには入れない。OFL)
  curl -LO https://raw.githubusercontent.com/google/fonts/main/ofl/notocoloremoji/NotoColorEmoji-Regular.ttf
  python scripts/web/make_emoji_font.py NotoColorEmoji-Regular.ttf web/fonts/NotoColorEmoji-subset.woff2

含める絵文字を変えるときは、下のCODE_POINTSを直して、作り直す。大きさの目安:
  顔・ハート・手・人・天気・食べ物・記号・キーキャップ ... 約700KB(いまの範囲)
  上に動物を足す ... 約1.1MB
"""

import os
import sys

from fontTools import subset
from fontTools.ttLib import TTFont
from fontTools.ttLib.tables._g_l_y_f import Glyph


def _r(a, b):
    return set(range(a, b + 1))


CODE_POINTS = (
    _r(0x1F600, 0x1F64F)  # 顔
    | _r(0x1F910, 0x1F92F)
    | _r(0x1F970, 0x1F97A)
    | _r(0x1F493, 0x1F49F)  # ハート
    | {0x2764, 0x1F90D, 0x1F90E, 0x1F5A4, 0x1F9E1}
    | {0x1F44D, 0x1F44E, 0x1F44F, 0x1F44B, 0x1F44A, 0x1F64C, 0x1F64F}  # 手
    | {0x1F91D, 0x270C, 0x270A, 0x270B, 0x1F4AA}
    | _r(0x1F90C, 0x1F90F)
    | _r(0x1F3FB, 0x1F3FF)  # 肌の色
    | _r(0x1F466, 0x1F469)  # 人・家族
    | {0x1F476, 0x1F9D1, 0x1F9D2, 0x1F9D3, 0x1F46A, 0x1F46B, 0x1F46C, 0x1F46D}
    | {0x1F931, 0x1F930, 0x1F926, 0x1F937, 0x1F37C, 0x1F6BC, 0x1F9F8}
    | _r(0x1F32D, 0x1F37F)  # 食べ物・飲み物
    | {0x2600, 0x2601, 0x2614, 0x26C5, 0x2744, 0x26A1, 0x1F319, 0x1F338, 0x1F31F}  # 天気・自然
    | {0x2728, 0x2B50, 0x2B55, 0x1F525, 0x1F4AF, 0x2705, 0x274C, 0x1F389, 0x1F38A}  # 記号
    | {0x2753, 0x2754, 0x2755, 0x2757, 0x203C, 0x2049, 0x2139, 0x26A0}
    | {0x1F4A1, 0x1F4A2, 0x1F4A4, 0x1F4A5, 0x1F4A6, 0x1F4AB, 0x1F4AC, 0x1F4AD}
    | {0x1F440, 0x1F9E0, 0x1F3E0, 0x1F697, 0x1F4DA, 0x1F4F1, 0x1F6CC, 0x1F375, 0x2615}
    | _r(0x30, 0x39) | {0x23, 0x2A, 0x20E3}  # キーキャップ(1️⃣など)
    | {0x200D, 0xFE0F}  # 結合(家族・肌の色)と、絵文字として出す印
)


def build(src, dst):
    opts = subset.Options()
    opts.layout_features = ["*"]
    opts.drop_tables = list(opts.drop_tables) + ["SVG "]  # COLRがあれば、SVGは要らない(大きい)
    opts.notdef_outline = False
    opts.name_IDs = [0, 1, 2, 3, 4, 5, 6, 13, 14]
    font = TTFont(src)
    sub = subset.Subsetter(opts)
    sub.populate(unicodes=CODE_POINTS)
    sub.subset(font)

    # FE0F(絵文字として出す印)を、文字表に、幅ゼロの空の字形で載せる。載せないと、Flutterが
    # 「この文字を表示できない」と見なして、外部のフォントを取りに行き続ける(1️⃣などで起きる)。
    name = "uniFE0F"
    order = font.getGlyphOrder()
    if name not in order:
        order.append(name)
        font.setGlyphOrder(order)
        glyph = Glyph()
        glyph.numberOfContours = 0
        font["glyf"].glyphs[name] = glyph
        font["glyf"].glyphOrder = order
        font["hmtx"].metrics[name] = (0, 0)
        if "vmtx" in font:
            font["vmtx"].metrics[name] = (1024, 0)
    for table in font["cmap"].tables:
        if table.format in (4, 12):
            table.cmap[0xFE0F] = name

    font.flavor = "woff2"
    font.save(dst)
    print(f"{dst}: {os.path.getsize(dst) // 1024} KB")


if __name__ == "__main__":
    if len(sys.argv) != 3:
        sys.exit(__doc__)
    build(sys.argv[1], sys.argv[2])
