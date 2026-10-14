import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kosodate_hitoiki/core/constants/app_theme.dart';
import 'package:kosodate_hitoiki/data/mock/mock_post_repository.dart';
import 'package:kosodate_hitoiki/presentation/pages/post_detail/post_detail_page.dart';
import 'package:kosodate_hitoiki/presentation/providers/auth_provider.dart';

void main() {
  for (final scale in [1.0, 2.0]) {
    testWidgets('320px・文字$scale倍でコメント・返信と未送信時の入力保持', (tester) async {
      tester.view.physicalSize = const Size(320, 700);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final post = (await MockPostRepository().fetchFeed()).firstWhere(
        (post) => post.id == 'p2',
      );
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
            home: PostDetailPage(post: post, focusComments: true),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('ありがとう、試してみます。'), findsOneWidget);
      expect(find.text('はなさんに返信'), findsNothing);
      await tester.ensureVisible(find.text('こもれびさんに返信'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('こもれびさんに返信'));
      await tester.pumpAndSettle();
      expect(find.text('こもれびさんへの返信'), findsOneWidget);
      await tester.ensureVisible(find.byType(TextField));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<FilledButton>(find.widgetWithText(FilledButton, '送信'))
            .onPressed,
        isNull,
      );
      await tester.enterText(find.byType(TextField), 'うちの場合は');
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('送信'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('送信'));
      await tester.pumpAndSettle();
      expect(find.text('コメント送信は準備中です'), findsOneWidget);
      await tester.tap(find.text('入力に戻る'));
      await tester.pumpAndSettle();
      expect(
        tester.widget<TextField>(find.byType(TextField)).controller!.text,
        'うちの場合は',
      );
      await tester.ensureVisible(find.text('返信をやめる'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('返信をやめる'));
      await tester.pumpAndSettle();
      expect(find.text('コメントを書く'), findsOneWidget);
      expect(tester.widget<TextField>(find.byType(TextField)).maxLength, 500);
      expect(tester.takeException(), isNull);
    });
  }
}
