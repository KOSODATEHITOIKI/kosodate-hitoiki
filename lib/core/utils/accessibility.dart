import 'package:flutter/material.dart';

/// 文字拡大が大きいときは装飾要素(アイコン・イラスト)を隠し、
/// 本文の表示スペースと行間を優先する。welcome_page.dartの基準に合わせる。
bool fitsDecoration(BuildContext context, {double maxScale = 1.3}) {
  return MediaQuery.textScalerOf(context).scale(1) <= maxScale;
}

/// デザイン基準幅(一般的なスマートフォンの論理幅)。
const double _designBaseWidth = 390;

/// 画面幅が基準より狭い端末では文字をやや小さく調整する。
/// OSの文字拡大設定(非線形スケールを含む)とは合成で尊重する。scale(1)の
/// 一点サンプルから線形倍率を作ると、OS側が非線形カーブ(大きいフォントほど
/// 比率を抑える設定)を使っている場合に曲線形状が失われるため、元の
/// TextScalerをラップしてfontSizeごとに合成する。
/// 基準幅以上(タブレット等)では縮小せず1.0のまま=OS設定のみ反映。
TextScaler responsiveTextScaler(
  BuildContext context, {
  double minFactor = 0.85,
}) {
  final width = MediaQuery.sizeOf(context).width;
  final widthFactor = (width / _designBaseWidth).clamp(minFactor, 1.0);
  final deviceScaler = MediaQuery.textScalerOf(context);
  if (widthFactor == 1.0) {
    return deviceScaler;
  }
  return _CompositeTextScaler(deviceScaler, widthFactor);
}

/// [deviceScaler]の非線形カーブを保ったまま、さらに[factor]倍する合成スケーラー。
class _CompositeTextScaler extends TextScaler {
  const _CompositeTextScaler(this._base, this._factor);

  final TextScaler _base;
  final double _factor;

  @override
  double scale(double fontSize) => _base.scale(fontSize) * _factor;

  @override
  @Deprecated(
    'Use of textScaleFactor was deprecated in preparation for the upcoming nonlinear text scaling support. '
    'This feature was deprecated after v3.12.0-2.0.pre.',
  )
  double get textScaleFactor => scale(1);

  @override
  bool operator ==(Object other) =>
      other is _CompositeTextScaler &&
      other._base == _base &&
      other._factor == _factor;

  @override
  int get hashCode => Object.hash(_base, _factor);
}
