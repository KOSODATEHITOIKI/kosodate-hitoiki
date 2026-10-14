import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kosodate_hitoiki/core/constants/app_theme.dart';
import 'package:kosodate_hitoiki/presentation/pages/compose/compose_page.dart';

void main() {
  testWidgets('空白だけでは投稿不可、入力後も準備中の案内で本文を保持する', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: const Scaffold(body: ComposePage()),
      ),
    );
    await tester.enterText(find.byType(TextField), '   ');
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('compose-submit')),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(
      tester
          .widget<FilledButton>(find.byKey(const ValueKey('compose-submit')))
          .onPressed,
      isNull,
    );
    await tester.scrollUntilVisible(
      find.byType(TextField),
      -200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.enterText(find.byType(TextField), '今日は少し疲れた。');
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('compose-submit')),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const ValueKey('compose-submit')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('compose-submit')));
    await tester.pumpAndSettle();
    expect(find.text('投稿機能は準備中です'), findsOneWidget);
    await tester.tap(find.text('書く画面に戻る'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.byType(TextField),
      -200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller!.text,
      '今日は少し疲れた。',
    );
    expect(tester.takeException(), isNull);
  });
  testWidgets('小さい画面と拡大文字で種類・反応の希望を変更できる', (tester) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: const MediaQuery(
          data: MediaQueryData(textScaler: TextScaler.linear(1.5)),
          child: Scaffold(body: ComposePage()),
        ),
      ),
    );
    await tester.scrollUntilVisible(
      find.widgetWithText(ChoiceChip, '相談'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.widgetWithText(ChoiceChip, '相談'));
    await tester.pumpAndSettle();
    expect(
      tester.widget<ChoiceChip>(find.widgetWithText(ChoiceChip, '相談')).selected,
      isTrue,
    );
    await tester.scrollUntilVisible(
      find.text('話を聞きたい'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('話を聞きたい'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('話を聞きたい'), warnIfMissed: true);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
