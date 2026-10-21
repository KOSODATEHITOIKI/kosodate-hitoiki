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
        // PNGは非同期にデコードされるため、描画前に読み込みを待つ。
        if (_heavy.contains(name)) {
          await precacheImage(
            AssetImage('assets/decorations/decoration-$name.png'),
            key.currentContext!,
          );
          await tester.pump();
        }
        final image = await boundary.toImage(pixelRatio: 1);
        final rgba = (await image.toByteData(
          format: ui.ImageByteFormat.rawRgba,
        ))!;
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
