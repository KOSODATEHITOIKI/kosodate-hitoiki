import 'package:flutter/material.dart';

/// 確定カラーパレット(2026-09-29確定)。
class AppColors {
  AppColors._();

  /// コーラル。プライマリボタン等。
  static const primary = Color(0xFFF87965);

  /// 黄。セカンダリボタン・選択中チップ等。
  static const secondary = Color(0xFFF6CA65);

  /// 紙。画面背景。
  static const background = Color(0xFFFFFCF6);

  /// クリーム。案内・装飾の背景。
  static const surface = Color(0xFFFFF3D5);

  /// ホワイト。カード・入力欄。
  static const white = Color(0xFFFFFFFF);

  /// ココア。見出し・本文。
  static const textPrimary = Color(0xFF654536);
  static const textSecondary = textPrimary;

  /// 葉。安心・成功系のアクセント。
  static const accentLeaf = Color(0xFF95B78B);

  /// 淡い桃。共感・ハート系のアクセント。
  static const accentPink = Color(0xFFFAD7CB);

  /// ココアの薄い線。
  static const divider = Color(0x29654536);
}
