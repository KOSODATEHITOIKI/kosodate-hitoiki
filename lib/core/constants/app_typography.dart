import 'package:flutter/material.dart';

/// デザイン指定に合わせた文字階層。日本語フォントはアプリに同梱する。
class AppTypography {
  AppTypography._();

  static const fontFamily = 'M PLUS Rounded 1c';
  static const appName = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.w800,
    height: 1.4,
  );
  static const title = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w700,
    height: 1.4,
  );
  static const section = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w700,
    height: 1.5,
  );
  static const body = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    height: 1.7,
  );
  static const button = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w700,
    height: 1.5,
  );
  static const caption = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w400,
    height: 1.7,
  );
}
