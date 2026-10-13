import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kosodate_hitoiki/app.dart';
import 'package:kosodate_hitoiki/presentation/pages/welcome/welcome_page.dart';

void main() {
  testWidgets('起動時に利用案内を表示し、ゲスト閲覧後は案内に戻らない', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: App()));

    expect(find.byType(WelcomePage), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);
    for (final title in ['名前や個人情報は書かない', '気持ちを否定しない', '自分のペースで大丈夫']) {
      expect(find.text(title), findsOneWidget);
    }

    await tester.ensureVisible(find.text('登録せずに読む'));
    await tester.tap(find.text('登録せずに読む'));
    await tester.pumpAndSettle();
    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.byType(WelcomePage), findsNothing);
    expect(
      Navigator.of(tester.element(find.byType(NavigationBar))).canPop(),
      isFalse,
    );
  });

  for (final action in ['登録してはじめる', 'ログイン']) {
    testWidgets('$actionから準備中の案内を閉じられる', (tester) async {
      await tester.pumpWidget(const ProviderScope(child: App()));
      await tester.ensureVisible(find.text(action));
      await tester.tap(find.text(action));
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsOneWidget);
      await tester.tap(find.text('閉じる'));
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsNothing);
      expect(find.byType(WelcomePage), findsOneWidget);
    });
  }

  testWidgets('小さい画面・文字拡大でも全ボタンに到達できる', (tester) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: const TextScaler.linear(2)),
            child: child!,
          ),
          home: const WelcomePage(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    for (final label in ['登録してはじめる', '登録せずに読む', 'ログイン']) {
      await tester.ensureVisible(find.text(label));
      await tester.pumpAndSettle();
      expect(find.text(label).hitTestable(), findsOneWidget);
      expect(tester.takeException(), isNull);
    }
  });
}
