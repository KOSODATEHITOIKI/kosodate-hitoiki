import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kosodate_hitoiki/core/constants/app_theme.dart';
import 'package:kosodate_hitoiki/data/api/api_exception.dart';
import 'package:kosodate_hitoiki/data/repositories/supabase_post_repository.dart';
import 'package:kosodate_hitoiki/domain/models/post.dart';
import 'package:kosodate_hitoiki/presentation/pages/post_detail/post_detail_page.dart';
import 'package:kosodate_hitoiki/presentation/providers/auth_provider.dart';
import 'package:kosodate_hitoiki/presentation/providers/post_providers.dart';

import 'helpers/scripted_post_repository.dart';

Post _post({
  ResponseMode mode = ResponseMode.listening,
  bool commentsOpen = true,
}) => Post(
  id: 'p-1',
  authorId: 'me',
  authorName: 'はな',
  authorAvatarAsset: 'assets/avatars/avatar-default-sprout.png',
  createdAt: DateTime(2026, 10, 21),
  type: PostType.grumble,
  responseMode: mode,
  body: '今日はつらかった。',
  empathyCount: 0,
  commentCount: 0,
  isMine: true,
  commentsOpen: commentsOpen,
);

Future<void> pumpDetail(
  WidgetTester tester,
  ScriptedPostRepository repository,
  Post post,
) async {
  tester.view.physicalSize = const Size(390, 1000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        isLoggedInProvider.overrideWithValue(true),
        postRepositoryProvider.overrideWithValue(repository),
      ],
      child: MaterialApp(
        theme: AppTheme.light,
        home: PostDetailPage(post: post),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

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

Future<void> confirm(WidgetTester tester) async {
  await tester.tap(find.byKey(const ValueKey('post-action-confirm')));
  await tester.pumpAndSettle();
}

void main() {
  group('リクエスト本文', () {
    test('反応モードは常に入れ、受付状態は指定したときだけ入れる', () {
      expect(
        SupabasePostRepository.reactionModeBody(mode: ResponseMode.advice),
        {'reaction_mode': 'want_comments'},
      );
      // 受付状態だけを変えるときも、反応モードを添える(サーバーは必須とする)。
      expect(
        SupabasePostRepository.reactionModeBody(
          mode: ResponseMode.advice,
          commentsOpen: false,
        ),
        {'reaction_mode': 'want_comments', 'comment_acceptance': 'closed'},
      );
      expect(
        SupabasePostRepository.reactionModeBody(
          mode: ResponseMode.advice,
          commentsOpen: true,
        ),
        {'reaction_mode': 'want_comments', 'comment_acceptance': 'open'},
      );
      expect(
        SupabasePostRepository.reactionModeBody(mode: ResponseMode.listening),
        {'reaction_mode': 'quiet_support'},
      );
    });
  });

  testWidgets('話を聞きたいに変更: 確認して送り、コメント欄が使えるようになる', (tester) async {
    final repository = ScriptedPostRepository([]);
    await pumpDetail(tester, repository, _post());
    expect(find.byType(TextField), findsNothing);

    await choose(tester, '話を聞きたいに変更');
    expect(find.text('話を聞きたいに変更しますか？'), findsOneWidget);
    // 確認の前は、送らない。
    expect(repository.modeCalls, isEmpty);
    await confirm(tester);

    expect(repository.modeCalls, hasLength(1));
    expect(repository.modeCalls.single.postId, 'p-1');
    expect(repository.modeCalls.single.mode, ResponseMode.advice);
    expect(repository.modeCalls.single.commentsOpen, isNull);
    expect(find.text('話を聞きたいに変更しました'), findsOneWidget);
    expect(find.byType(TextField), findsOneWidget);
  });

  testWidgets('確認で「やめる」を選んだら、送らない', (tester) async {
    final repository = ScriptedPostRepository([]);
    await pumpDetail(tester, repository, _post());
    await choose(tester, '話を聞きたいに変更');
    await tester.tap(find.text('やめる'));
    await tester.pumpAndSettle();
    expect(repository.modeCalls, isEmpty);
    expect(find.byType(TextField), findsNothing);
  });

  testWidgets('変更できなかったら、案内して、表示は変えない', (tester) async {
    final repository = ScriptedPostRepository(
      [],
      modeError: const ApiException(
        code: 'FORBIDDEN',
        message: '',
        status: 403,
      ),
    );
    await pumpDetail(tester, repository, _post());
    await choose(tester, '話を聞きたいに変更');
    await confirm(tester);

    expect(repository.modeCalls, hasLength(1));
    expect(find.byType(TextField), findsNothing);
    expect(find.text('話を聞きたいに変更しました'), findsNothing);
    expect(find.text('この操作はできません。'), findsOneWidget);
  });

  testWidgets('受付の終了と再開: 投稿の持つ状態から始まり、受付状態だけを送る', (tester) async {
    final repository = ScriptedPostRepository([]);
    await pumpDetail(
      tester,
      repository,
      _post(mode: ResponseMode.advice, commentsOpen: true),
    );
    expect(find.byType(TextField), findsOneWidget);

    await choose(tester, 'コメント受付を終了');
    expect(find.text('コメントの受付を終了しますか？'), findsOneWidget);
    await confirm(tester);
    expect(repository.modeCalls.last.commentsOpen, isFalse);
    // 受付状態だけを変えるときも、反応モードを添える。
    expect(repository.modeCalls.last.mode, ResponseMode.advice);
    expect(find.byType(TextField), findsNothing);
    expect(find.text('コメントの受付は終了しています。'), findsOneWidget);

    await choose(tester, 'コメント受付を再開');
    await confirm(tester);
    expect(repository.modeCalls.last.commentsOpen, isTrue);
    expect(find.byType(TextField), findsOneWidget);
  });

  testWidgets('すでに受付を終了している投稿は、「再開」から始まる', (tester) async {
    final repository = ScriptedPostRepository([]);
    await pumpDetail(
      tester,
      repository,
      _post(mode: ResponseMode.advice, commentsOpen: false),
    );
    expect(find.text('コメントの受付は終了しています。'), findsOneWidget);
    await choose(tester, 'コメント受付を再開');
    expect(find.text('コメントの受付を再開しますか？'), findsOneWidget);
  });
}
