import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kosodate_hitoiki/core/constants/app_theme.dart';
import 'package:kosodate_hitoiki/presentation/pages/compose/compose_page.dart';

void main() {
  testWidgets('初回案内は320px文字2倍でも延期でき、本文を失わない', (tester) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: AppTheme.light,
          home: const MediaQuery(
            data: MediaQueryData(textScaler: TextScaler.linear(2)),
            child: Scaffold(body: ComposePage()),
          ),
        ),
      ),
    );
    await tester.scrollUntilVisible(
      find.byType(TextField),
      180,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'いまの気持ち');
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('compose-submit')),
      180,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('compose-submit')));
    await tester.pumpAndSettle();
    expect(find.text('はじめて投稿する前に'), findsOneWidget);
    await tester.tap(find.text('あとにする'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.byType(TextField),
      -180,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller!.text,
      'いまの気持ち',
    );
    expect(tester.takeException(), isNull);
  });
  testWidgets('反応の希望は縦並びで選択できる', (tester) async {
    tester.view.physicalSize = const Size(768, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: AppTheme.light,
          home: const Scaffold(body: ComposePage()),
        ),
      ),
    );
    await tester.scrollUntilVisible(
      find.text('話を聞きたい'),
      150,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('話を聞きたい'));
    await tester.pumpAndSettle();
    expect(
      tester.getTopLeft(find.text('話を聞きたい')).dy,
      greaterThan(tester.getTopLeft(find.text('ただ聞いてほしい')).dy),
    );
    await tester.tap(find.text('話を聞きたい'));
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<Semantics>(find.byKey(const ValueKey('response-advice')))
          .properties
          .selected,
      isTrue,
    );
    expect(tester.takeException(), isNull);
  });
  testWidgets('空白だけでは投稿不可、初回案内と確認後も本文を保持する', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: AppTheme.light,
          home: const Scaffold(body: ComposePage()),
        ),
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
    expect(find.text('はじめて投稿する前に'), findsOneWidget);
    await tester.tap(find.text('確認して書く'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('compose-submit')));
    await tester.pumpAndSettle();
    expect(find.text('投稿の確認'), findsOneWidget);
    expect(find.text('今日は少し疲れた。'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('書き直す'),
      160,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('書き直す'));
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
      ProviderScope(
        child: MaterialApp(
          theme: AppTheme.light,
          home: const MediaQuery(
            data: MediaQueryData(textScaler: TextScaler.linear(1.5)),
            child: Scaffold(body: ComposePage()),
          ),
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
