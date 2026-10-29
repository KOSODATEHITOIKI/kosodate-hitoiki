import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kosodate_hitoiki/app.dart';
import 'package:kosodate_hitoiki/presentation/pages/auth/auth_page.dart';
import 'package:kosodate_hitoiki/presentation/providers/auth_provider.dart';
import 'package:kosodate_hitoiki/presentation/widgets/desktop_hero_panel.dart';

Future<void> pumpApp(WidgetTester tester, Size size) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [isLoggedInProvider.overrideWithValue(false)],
      child: const App(),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('スマホ幅では、案内もログインも、左の絵の面を出さない', (tester) async {
    await pumpApp(tester, const Size(390, 900));
    expect(find.byType(DesktopHeroPanel), findsNothing);
    await tester.ensureVisible(find.text('ログイン'));
    await tester.tap(find.text('ログイン'));
    await tester.pumpAndSettle();
    expect(find.byType(AuthPage), findsOneWidget);
    expect(find.byType(DesktopHeroPanel), findsNothing);
  });

  testWidgets('広い画面(1280px)では、案内もログインも、左に絵の面、右に内容を出す', (tester) async {
    await pumpApp(tester, const Size(1280, 900));
    expect(find.byType(DesktopHeroPanel), findsOneWidget);
    // 案内の右側には、約束とボタンがある。
    expect(find.text('名前や個人情報は書かない'), findsOneWidget);
    expect(find.text('登録せずに読む'), findsOneWidget);

    await tester.tap(find.text('ログイン'));
    await tester.pumpAndSettle();
    expect(find.byType(AuthPage), findsOneWidget);
    expect(find.byType(DesktopHeroPanel), findsOneWidget);
    expect(find.text('ログインする'), findsOneWidget);
    // 絵の面は、画面の左半分あたり。フォームは右側にある。
    final hero = tester.getRect(find.byType(DesktopHeroPanel));
    final button = tester.getRect(find.text('ログインする'));
    expect(hero.left, 0);
    expect(button.left, greaterThan(hero.right));
    expect(tester.takeException(), isNull);
  });
}
