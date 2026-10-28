import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kosodate_hitoiki/core/constants/app_theme.dart';
import 'package:kosodate_hitoiki/domain/models/post.dart';
import 'package:kosodate_hitoiki/presentation/pages/post_detail/post_detail_page.dart';
import 'package:kosodate_hitoiki/presentation/providers/auth_provider.dart';
import 'package:kosodate_hitoiki/presentation/providers/post_providers.dart';

import 'helpers/scripted_post_repository.dart';

Post _post({required String body, String authorId = '', bool isMine = false}) =>
    Post(
      id: 'p-1',
      authorId: authorId,
      authorName: 'はな',
      authorAvatarAsset: 'assets/avatars/avatar-default-sprout.png',
      createdAt: DateTime(2026, 10, 28),
      type: PostType.grumble,
      responseMode: ResponseMode.listening,
      body: body,
      empathyCount: 0,
      commentCount: 0,
      isMine: isMine,
    );

Future<void> pumpDetail(
  WidgetTester tester,
  ScriptedPostRepository repository,
  Post opened, {
  bool loggedIn = true,
}) async {
  tester.view.physicalSize = const Size(390, 1400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        isLoggedInProvider.overrideWithValue(loggedIn),
        postRepositoryProvider.overrideWithValue(repository),
      ],
      child: MaterialApp(
        theme: AppTheme.light,
        home: PostDetailPage(post: opened),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('一覧に載っていない投稿でも、取得した最新の本文・投稿者に更新される', (tester) async {
    final repository = ScriptedPostRepository([]);
    repository.fetchedPosts['p-1'] = _post(body: '最新の本文', authorId: 'author-1');
    // 開いたときの投稿は、古い(本文が違い、投稿者IDもない)。
    await pumpDetail(tester, repository, _post(body: '古い本文'));

    expect(find.text('最新の本文'), findsOneWidget);
    expect(find.text('古い本文'), findsNothing);
  });

  testWidgets('取得した投稿で「自分の投稿」と分かり、編集・削除が出る', (tester) async {
    final repository = ScriptedPostRepository([]);
    repository.fetchedPosts['p-1'] = _post(
      body: '自分の本文',
      authorId: 'me',
      isMine: true,
    );
    await pumpDetail(tester, repository, _post(body: '自分の本文'));

    await tester.tap(find.byTooltip('投稿メニュー'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('投稿を削除'),
      100,
      scrollable: find.byType(Scrollable).last,
    );
    expect(find.text('投稿を編集'), findsOneWidget);
    expect(find.text('投稿を削除'), findsOneWidget);
    // 自分の投稿は、ブロック・非表示の対象にならない。
    expect(find.text('投稿者をブロック'), findsNothing);
  });

  testWidgets('取得した投稿の投稿者IDで、ブロックできる(開いたときの投稿には、投稿者IDがない)', (tester) async {
    final repository = ScriptedPostRepository([]);
    repository.fetchedPosts['p-1'] = _post(body: '本文', authorId: 'author-1');
    await pumpDetail(tester, repository, _post(body: '本文'));

    await tester.tap(find.byTooltip('投稿メニュー'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('投稿者をブロック'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('post-action-confirm')));
    await tester.pumpAndSettle();

    expect(repository.blockCalls, ['author-1']);
  });

  testWidgets('取得できない(見えない投稿など)ときは、開いたときの投稿を使う', (tester) async {
    final repository = ScriptedPostRepository([]);
    await pumpDetail(tester, repository, _post(body: '開いたときの本文'));
    expect(find.text('開いたときの本文'), findsOneWidget);
  });

  testWidgets('ゲストは、取得せず、開いたときの投稿を使う', (tester) async {
    final repository = ScriptedPostRepository([]);
    repository.fetchedPosts['p-1'] = _post(body: '最新の本文');
    await pumpDetail(
      tester,
      repository,
      _post(body: '開いたときの本文'),
      loggedIn: false,
    );
    expect(find.text('開いたときの本文'), findsOneWidget);
    expect(find.text('最新の本文'), findsNothing);
  });
}
