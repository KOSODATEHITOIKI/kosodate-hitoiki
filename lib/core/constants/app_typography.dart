import 'package:flutter/material.dart';

/// デザイン指定に合わせた文字階層。日本語フォントはアプリに同梱する。
class AppTypography {
  AppTypography._();

  static const fontFamily = 'M PLUS Rounded 1c';

  /// Webだけ、起動時に読み込む絵文字のフォント(web_emoji_font.dart)。同梱のフォントに無い文字の予備。
  /// アプリでは登録されないので、端末の絵文字が使われる。
  static const emojiFontFamily = 'Noto Color Emoji (Web)';
  static const fontFamilyFallback = [emojiFontFamily];
  static const appName = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w800,
    height: 1.4,
  );
  static const title = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w700,
    height: 1.4,
  );
  static const section = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w700,
    height: 1.5,
  );
  static const body = TextStyle(
    fontSize: 12.5,
    fontWeight: FontWeight.w400,
    height: 1.7,
  );
  static const button = TextStyle(
    fontSize: 12.5,
    fontWeight: FontWeight.w700,
    height: 1.5,
  );
  static const caption = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    height: 1.7,
  );
}
