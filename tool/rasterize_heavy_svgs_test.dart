// 重いSVG(パス数が多い水彩風イラスト)をPNGに書き出す使い捨てツール。
//
// flutter_svgは実行時にSVGを解析・描画するため、1万パス級のSVGを画面に出すと
// UIが固まる。元SVGは`design/svg-src/`に置き(アプリには同梱しない)、
// 表示用に240×240の2倍(480×480)のPNGを`assets/`へ出力する。
//
// 使い方: flutter test tool/rasterize_heavy_svgs_test.dart
// 入力: design/svg-src/<カテゴリ>/*.svg → 出力: assets/<カテゴリ>/*.png
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';

const _logicalSize = 240.0;
const _pixelRatio = 2.0;

void main() {
  final srcRoot = Directory('design/svg-src');
  final svgs =
      srcRoot
          .listSync(recursive: true)
          .whereType<File>()
          .where((f) => f.path.endsWith('.svg'))
          .toList()
        ..sort((a, b) => a.path.compareTo(b.path));

  for (final svg in svgs) {
    final normalized = svg.path.replaceAll(r'\', '/');
    final relative = normalized.substring('design/svg-src/'.length);
    final out = File('assets/${relative.replaceAll('.svg', '.png')}');

    testWidgets('$relative をPNGに書き出す', (tester) async {
      final key = GlobalKey();
      final svgString = svg.readAsStringSync();
      await tester.runAsync(() async {
        await tester.pumpWidget(
          Directionality(
            textDirection: TextDirection.ltr,
            child: Center(
              child: RepaintBoundary(
                key: key,
                child: SvgPicture.string(
                  svgString,
                  width: _logicalSize,
                  height: _logicalSize,
                ),
              ),
            ),
          ),
        );
        // SVGの解析は非同期なので、描画が確定するまで待つ。
        await Future<void>.delayed(const Duration(seconds: 3));
        await tester.pump();
        final boundary =
            key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
        final image = await boundary.toImage(pixelRatio: _pixelRatio);
        final data = await image.toByteData(format: ui.ImageByteFormat.png);
        out.writeAsBytesSync(data!.buffer.asUint8List());
        image.dispose();
      });
    });
  }
}
