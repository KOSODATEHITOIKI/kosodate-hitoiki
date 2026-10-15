import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kosodate_hitoiki/core/constants/app_theme.dart';
import 'package:kosodate_hitoiki/presentation/pages/settings/settings_page.dart';
import 'package:kosodate_hitoiki/presentation/pages/settings/notification_settings_page.dart';
import 'package:kosodate_hitoiki/presentation/providers/auth_provider.dart';

void main() {
  for (final scale in [1.0, 2.0]) {
    testWidgets('320px文字$scale倍で通知を個別に切り替える', (tester) async {
      tester.view.physicalSize = const Size(320, 700);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [isLoggedInProvider.overrideWithValue(true)],
          child: MaterialApp(
            theme: AppTheme.light,
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(textScaler: TextScaler.linear(scale)),
              child: child!,
            ),
            home: const SettingsPage(),
          ),
        ),
      );
      await tester.scrollUntilVisible(
        find.text('通知'),
        150,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('通知'));
      await tester.pumpAndSettle();
      expect(find.byType(NotificationSettingsPage), findsOneWidget);
      final comments = find.widgetWithText(SwitchListTile, 'コメント');
      final empathy = find.widgetWithText(SwitchListTile, '共感のまとめ');
      await tester.scrollUntilVisible(
        comments,
        150,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      await tester.tap(comments);
      await tester.pumpAndSettle();
      expect(tester.widget<SwitchListTile>(comments).value, isFalse);
      await tester.scrollUntilVisible(
        empathy,
        150,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      expect(tester.widget<SwitchListTile>(empathy).value, isFalse);
      expect(
        tester
            .widget<SwitchListTile>(find.widgetWithText(SwitchListTile, '返信'))
            .value,
        isTrue,
      );
      await tester.tap(empathy);
      await tester.pumpAndSettle();
      expect(tester.widget<SwitchListTile>(empathy).value, isTrue);
      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(find.byType(SettingsPage), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
  testWidgets('ゲストには通知設定を表示しない', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [isLoggedInProvider.overrideWithValue(false)],
        child: MaterialApp(
          theme: AppTheme.light,
          home: const NotificationSettingsPage(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(SwitchListTile), findsNothing);
    expect(find.text('ログイン'), findsOneWidget);
  });
}
