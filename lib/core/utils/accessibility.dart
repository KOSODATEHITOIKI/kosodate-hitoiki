import 'package:flutter/material.dart';

/// 文字拡大が大きいときは装飾要素(アイコン・イラスト)を隠し、
/// 本文の表示スペースと行間を優先する。welcome_page.dartの基準に合わせる。
bool fitsDecoration(BuildContext context, {double maxScale = 1.3}) {
  return MediaQuery.textScalerOf(context).scale(1) <= maxScale;
}

/// デザイン基準幅(一般的なスマートフォンの論理幅)。
const double _designBaseWidth = 390;

/// 画面幅が基準より狭い端末では文字をやや小さく調整する。
/// OSの文字拡大設定(アクセシビリティ)とは乗算で合成し、どちらも尊重する。
/// 基準幅以上(タブレット等)では縮小せず1.0のまま=OS設定のみ反映。
TextScaler responsiveTextScaler(
  BuildContext context, {
  double minFactor = 0.85,
}) {
  final width = MediaQuery.sizeOf(context).width;
  final widthFactor = (width / _designBaseWidth).clamp(minFactor, 1.0);
  final deviceScale = MediaQuery.textScalerOf(context).scale(1);
  return TextScaler.linear(deviceScale * widthFactor);
}
