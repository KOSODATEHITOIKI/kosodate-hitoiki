import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kosodate_hitoiki/core/constants/app_theme.dart';
import 'package:kosodate_hitoiki/presentation/pages/compose/compose_review_page.dart';
import 'package:kosodate_hitoiki/presentation/pages/support/support_resources_page.dart';

Future<void> showSample(WidgetTester tester, String label) async {
  final target = find.widgetWithText(ChoiceChip, label);
  await tester.scrollUntilVisible(
    target,
    150,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.pumpAndSettle();
  await tester.tap(target);
  await tester.pumpAndSettle();
}

void main() {
  for (final scale in [1.0, 2.0]) {
    testWidgets('320px文字$scale倍で確認・送信不可・相談先表示を確認する', (tester) async {
      tester.view.physicalSize = const Size(320, 700);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: AppTheme.light,
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(textScaler: TextScaler.linear(scale)),
              child: child!,
            ),
            home: const ComposeReviewPage(
              body: '今日は少し疲れた。',
              postType: '相談',
              responseMode: '話を聞きたい',
              topic: '食事',
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('今日は少し疲れた。'),
        150,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      expect(find.text('今日は少し疲れた。'), findsOneWidget);
      expect(find.text('相談'), findsOneWidget);
      await tester.scrollUntilVisible(
        find.text('チェック結果の表示サンプル'),
        160,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('チェック結果の表示サンプル'));
      await tester.pumpAndSettle();
      await showSample(tester, '送信不可');
      expect(find.text('この内容で投稿する'), findsNothing);
      await tester.scrollUntilVisible(
        find.text('この内容では送信できません。（表示サンプル）'),
        -150,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      expect(find.text('この内容では送信できません。（表示サンプル）'), findsOneWidget);
      await showSample(tester, '相談先案内');
      await tester.scrollUntilVisible(
        find.text('困ったときの相談先'),
        -150,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      expect(find.text('困ったときの相談先'), findsOneWidget);
      await tester.ensureVisible(find.text('困ったときの相談先'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('困ったときの相談先'));
      await tester.pumpAndSettle();
      expect(find.byType(SupportResourcesPage), findsOneWidget);
      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(find.text('この内容で投稿する'), findsOneWidget);
      await tester.ensureVisible(find.text('この内容で投稿する'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('この内容で投稿する'));
      await tester.pumpAndSettle();
      expect(find.text('投稿機能は準備中です'), findsOneWidget);
      await tester.tap(find.text('確認に戻る'));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('今日は少し疲れた。'),
        -150,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      expect(find.text('今日は少し疲れた。'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
