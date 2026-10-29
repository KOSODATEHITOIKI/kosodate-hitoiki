import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kosodate_hitoiki/core/config/auth_config.dart';
import 'package:kosodate_hitoiki/core/widgets/wide_screen_frame.dart';

Future<Size> pumpAt(WidgetTester tester, Size size) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    const MaterialApp(
      home: WideScreenFrame(child: SizedBox.expand(key: ValueKey('content'))),
    ),
  );
  return tester.getSize(find.byKey(const ValueKey('content')));
}

void main() {
  testWidgets('狭い画面(スマホ)では、画面いっぱいに使う', (tester) async {
    expect(await pumpAt(tester, const Size(390, 800)), const Size(390, 800));
    // 境目の幅でも、列にしない。
    expect(
      await pumpAt(tester, const Size(WideScreenFrame.breakpoint, 800)),
      const Size(WideScreenFrame.breakpoint, 800),
    );
  });

  testWidgets('少し広い画面(タブレット縦など)では、中央の細い列に収める。高さは変えない', (tester) async {
    expect(
      await pumpAt(tester, const Size(800, 900)),
      const Size(WideScreenFrame.maxWidth, 900),
    );
    final left = tester.getTopLeft(find.byKey(const ValueKey('content'))).dx;
    expect(left, (800 - WideScreenFrame.maxWidth) / 2);
  });

  testWidgets('パソコン向けの広い画面(1024px以上)では、列に収めない(画面側が幅を決める)', (tester) async {
    expect(await pumpAt(tester, const Size(1280, 900)), const Size(1280, 900));
  });

  test('認証メールの戻り先は、アプリ(Android・iOS)では独自スキーム', () {
    // Webでは、いま開いているサイトのURLになる(テストはWebではない)。
    expect(authCallbackUrl, 'kosodatehitoiki://auth-callback');
  });
}
