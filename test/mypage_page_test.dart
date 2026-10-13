import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kosodate_hitoiki/core/constants/app_theme.dart';
import 'package:kosodate_hitoiki/presentation/pages/mypage/mypage_page.dart';
import 'package:kosodate_hitoiki/presentation/pages/settings/settings_page.dart';

void main() {
  testWidgets('保存した投稿に切り替え、登録案内を閉じても選択を保持する', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: const Scaffold(body: MyPagePage()),
      ),
    );
    await tester.scrollUntilVisible(
      find.text('保存した投稿'),
      150,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('保存した投稿'));
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<SegmentedButton<bool>>(find.byType(SegmentedButton<bool>))
          .selected,
      {true},
    );
    await tester.scrollUntilVisible(
      find.text('あとで読みたい投稿'),
      150,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('保存したことは相手に通知されません。'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('登録・ログイン'),
      -150,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('登録・ログイン'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('登録・ログイン'));
    await tester.pumpAndSettle();
    expect(find.text('登録・ログインは準備中です'), findsOneWidget);
    await tester.tap(find.text('閉じる'));
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<SegmentedButton<bool>>(find.byType(SegmentedButton<bool>))
          .selected,
      {true},
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('小さい画面と拡大文字でプロフィール編集・設定の案内を開く', (tester) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: const MediaQuery(
          data: MediaQueryData(textScaler: TextScaler.linear(1.5)),
          child: Scaffold(body: MyPagePage()),
        ),
      ),
    );
    for (final label in ['設定', 'プロフィールを編集']) {
      await tester.scrollUntilVisible(
        find.text(label),
        150,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text(label));
      await tester.pumpAndSettle();
      await tester.tap(find.text(label));
      await tester.pumpAndSettle();
      if (label == '設定') {
        expect(find.byType(SettingsPage), findsOneWidget);
        await tester.pageBack();
      } else {
        expect(find.byType(AlertDialog), findsOneWidget);
        await tester.tap(find.text('閉じる'));
      }
      await tester.pumpAndSettle();
    }
    expect(tester.takeException(), isNull);
  });
}
