import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kosodate_hitoiki/core/constants/app_theme.dart';
import 'package:kosodate_hitoiki/data/mock/mock_post_repository.dart';
import 'package:kosodate_hitoiki/presentation/pages/post_detail/post_detail_page.dart';
import 'package:kosodate_hitoiki/presentation/pages/compose/compose_page.dart';
import 'package:kosodate_hitoiki/presentation/providers/auth_provider.dart';

Future<void> choose(WidgetTester tester, String label) async {
  await tester.tap(find.byTooltip('投稿メニュー'));
  await tester.pumpAndSettle();
  await tester.scrollUntilVisible(
    find.text(label),
    100,
    scrollable: find.byType(Scrollable).last,
  );
  await tester.pumpAndSettle();
  await tester.tap(find.text(label));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('サンプル投稿の受付変更・編集の初期値・削除は未実行', (tester) async {
    tester.view.physicalSize = const Size(320, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final post = (await MockPostRepository().fetchFeed()).firstWhere(
      (post) => post.id == 'p1',
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [isLoggedInProvider.overrideWithValue(true)],
        child: MaterialApp(
          theme: AppTheme.light,
          home: PostDetailPage(post: post),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(TextField), findsNothing);
    await choose(tester, '話を聞きたいに変更');
    await tester.tap(find.text('プレビューで変更'));
    await tester.pumpAndSettle();
    expect(find.byType(TextField), findsOneWidget);
    await choose(tester, 'コメント受付を終了');
    await tester.tap(find.text('プレビューで変更'));
    await tester.pumpAndSettle();
    expect(find.byType(TextField), findsNothing);
    expect(find.text('コメントの受付は終了しています。'), findsOneWidget);
    await choose(tester, 'コメント受付を再開');
    await tester.tap(find.text('プレビューで変更'));
    await tester.pumpAndSettle();
    expect(find.byType(TextField), findsOneWidget);
    await choose(tester, '投稿を編集');
    expect(find.byType(ComposePage), findsOneWidget);
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller!.text,
      post.body,
    );
    await tester.pageBack();
    await tester.pumpAndSettle();
    await choose(tester, '投稿を削除');
    expect(find.textContaining('現在は削除されません。'), findsOneWidget);
    await tester.tap(find.text('戻る'));
    await tester.pumpAndSettle();
    expect(find.text(post.body), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets('ゲストにはサンプル投稿の管理項目を出さない', (tester) async {
    final post = (await MockPostRepository().fetchFeed()).first;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [isLoggedInProvider.overrideWithValue(false)],
        child: MaterialApp(
          theme: AppTheme.light,
          home: PostDetailPage(post: post),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('投稿メニュー'));
    await tester.pumpAndSettle();
    expect(find.text('投稿を編集'), findsNothing);
    expect(find.text('投稿を削除'), findsNothing);
    expect(find.text('話を聞きたいに変更'), findsNothing);
  });
}
