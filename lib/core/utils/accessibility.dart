import 'package:flutter/material.dart';

/// 文字拡大が大きいときは装飾要素(アイコン・イラスト)を隠し、
/// 本文の表示スペースと行間を優先する。welcome_page.dartの基準に合わせる。
bool fitsDecoration(BuildContext context, {double maxScale = 1.3}) {
  return MediaQuery.textScalerOf(context).scale(1) <= maxScale;
}
