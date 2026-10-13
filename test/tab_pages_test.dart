import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kosodate_hitoiki/core/constants/app_theme.dart';
import 'package:kosodate_hitoiki/presentation/pages/search/search_page.dart';
import 'package:kosodate_hitoiki/presentation/pages/notifications/notifications_page.dart';

void main() {
  testWidgets('検索語の入力とクリア、種類選択ができる', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: const Scaffold(body: SearchPage()),
      ),
    );
    await tester.enterText(find.byType(TextField), '夜泣き');
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ChoiceChip, '相談'));
    await tester.pumpAndSettle();
    expect(
      tester.widget<ChoiceChip>(find.widgetWithText(ChoiceChip, '相談')).selected,
      isTrue,
    );
    await tester.tap(find.byTooltip('検索語を消す'));
    await tester.pumpAndSettle();
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller!.text,
      isEmpty,
    );
    expect(tester.takeException(), isNull);
  });
  testWidgets('小さい画面と拡大文字でも通知の未読切替ができる', (tester) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: const MediaQuery(
          data: MediaQueryData(textScaler: TextScaler.linear(1.5)),
          child: Scaffold(body: NotificationsPage()),
        ),
      ),
    );
    await tester.ensureVisible(find.text('未読'));
    await tester.tap(find.text('未読'));
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<SegmentedButton<bool>>(find.byType(SegmentedButton<bool>))
          .selected,
      {true},
    );
    expect(tester.takeException(), isNull);
  });
}
