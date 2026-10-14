import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kosodate_hitoiki/core/constants/app_theme.dart';
import 'package:kosodate_hitoiki/presentation/pages/notifications/notifications_page.dart';

void main() {
  for (final scale in [1.0, 2.0]) {
    testWidgets('通知の未読→詳細→既読→すべての切替（320px・文字$scale倍）', (tester) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: TextScaler.linear(scale)),
            child: child!,
          ),
          home: const Scaffold(body: NotificationsPage()),
        ),
      );
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('未読'),
        150,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('未読'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('未読'));
      await tester.pumpAndSettle();
      for (final id in ['comment', 'reply', 'empathy']) {
        final card = find.byKey(ValueKey('notification-$id'));
        await tester.scrollUntilVisible(
          card,
          150,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.pumpAndSettle();
        await tester.ensureVisible(card);
        await tester.pumpAndSettle();
        await tester.tap(card);
        await tester.pumpAndSettle();
        expect(find.byType(AlertDialog), findsOneWidget);
        await tester.tap(find.text('閉じる'));
        await tester.pumpAndSettle();
        expect(card, findsNothing);
      }
      expect(find.text('未読のお知らせはありません'), findsOneWidget);
      await tester.scrollUntilVisible(
        find.text('すべて'),
        -150,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('すべて'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('すべて'));
      await tester.pumpAndSettle();
      final first = find.byKey(const ValueKey('notification-comment'));
      await tester.scrollUntilVisible(
        first,
        150,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      expect(first, findsOneWidget);
      expect(find.text('未読のお知らせはありません'), findsNothing);
      expect(tester.takeException(), isNull);
    });
  }
}
