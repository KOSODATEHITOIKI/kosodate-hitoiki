import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kosodate_hitoiki/presentation/widgets/app_asset.dart';

/// 重いためPNG化した装飾(SVG原本は`design/svg-src/`)。
const _heavy = {'sun-smiling', 'sun-simple'};

void main() {
  for (final name in [
    'leaves-sprout',
    'heart-warm',
    'sun-smiling',
    'sun-simple',
  ]) {
    testWidgets('$nameの絵がSVG枠の中央にあり、欠けていない', (tester) async {
      final key = GlobalKey();
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: Center(
            child: RepaintBoundary(
              key: key,
              child: AppAsset(
                'assets/decorations/decoration-$name.${_heavy.contains(name) ? 'png' : 'svg'}',
                width: 240,
                height: 240,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final boundary =
          key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      await tester.runAsync(() async {
        // PNGは非同期にデコードされる(表示サイズに縮小するため、precacheでは
        // 同じ画像にならない)。何か描画されるまで、少しずつ待って撮り直す。
        late ByteData rgba;
        late ui.Image image;
        for (var attempt = 0; attempt < 100; attempt++) {
          await Future<void>.delayed(const Duration(milliseconds: 50));
          await tester.pump();
          image = await boundary.toImage(pixelRatio: 1);
          rgba = (await image.toByteData(format: ui.ImageByteFormat.rawRgba))!;
          var drawn = false;
          for (var i = 3; i < rgba.lengthInBytes; i += 4) {
            if (rgba.getUint8(i) >= 32) {
              drawn = true;
              break;
            }
          }
          if (drawn) break;
          image.dispose();
        }
        var left = 240, top = 240, right = -1, bottom = -1;
        for (var y = 0; y < 240; y++) {
          for (var x = 0; x < 240; x++) {
            if (rgba.getUint8((y * 240 + x) * 4 + 3) < 32) continue;
            if (x < left) left = x;
            if (x > right) right = x;
            if (y < top) top = y;
            if (y > bottom) bottom = y;
          }
        }
        expect(((left + right) / 2 - 119.5).abs(), lessThanOrEqualTo(1));
        expect(((top + bottom) / 2 - 119.5).abs(), lessThanOrEqualTo(1));
        expect(left, greaterThan(0));
        expect(top, greaterThan(0));
        expect(right, lessThan(239));
        expect(bottom, lessThan(239));
        image.dispose();
        expect(right, greaterThan(left));
      });
    });
  }
}
