import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kosodate_hitoiki/core/constants/app_theme.dart';
import 'package:kosodate_hitoiki/data/api/api_exception.dart';
import 'package:kosodate_hitoiki/domain/models/post.dart';
import 'package:kosodate_hitoiki/presentation/pages/post_detail/post_detail_page.dart';
import 'package:kosodate_hitoiki/presentation/providers/auth_provider.dart';
import 'package:kosodate_hitoiki/presentation/providers/post_providers.dart';

import 'helpers/scripted_post_repository.dart';

Post _post({
  bool isMine = false,
  String authorId = 'author-1',
  bool isSaved = false,
}) => Post(
  id: 'p-1',
  authorId: authorId,
  authorName: 'はな',
  authorAvatarAsset: 'assets/avatars/avatar-default-sprout.png',
  createdAt: DateTime(2026, 10, 21),
  type: PostType.consult,
  responseMode: ResponseMode.advice,
  body: '夜泣きが続いています。',
  empathyCount: 0,
  commentCount: 0,
  isMine: isMine,
  isSaved: isSaved,
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
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: TextButton(
                onPressed: () => Navigator.of(context).push<void>(
                  MaterialPageRoute(builder: (_) => PostDetailPage(post: post)),
                ),
                child: const Text('開く'),
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('開く'));
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

void main() {
  testWidgets('非表示: 確認して実行すると、APIを呼び、詳細を閉じる', (tester) async {
    final repository = ScriptedPostRepository([]);
    await pumpDetail(tester, repository, _post());
    await choose(tester, 'この投稿を非表示');
    expect(find.text('この投稿を非表示にしますか？'), findsOneWidget);
    expect(find.textContaining('相手には知らせません'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('post-action-confirm')));
    await tester.pumpAndSettle();

    expect(repository.hideCalls, ['p-1']);
    expect(find.byType(PostDetailPage), findsNothing);
    expect(find.text('投稿を非表示にしました'), findsOneWidget);
  });

  testWidgets('ブロック: 確認して実行すると、投稿者のIDでAPIを呼び、詳細を閉じる', (tester) async {
    final repository = ScriptedPostRepository([]);
    await pumpDetail(tester, repository, _post());
    await choose(tester, '投稿者をブロック');
    expect(find.text('投稿者をブロックしますか？'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('post-action-confirm')));
    await tester.pumpAndSettle();

    expect(repository.blockCalls, ['author-1']);
    expect(find.byType(PostDetailPage), findsNothing);
    expect(find.text('投稿者をブロックしました'), findsOneWidget);
  });

  testWidgets('やめると、何も実行しない', (tester) async {
    final repository = ScriptedPostRepository([]);
    await pumpDetail(tester, repository, _post());
    await choose(tester, '投稿者をブロック');
    await tester.tap(find.text('やめる'));
    await tester.pumpAndSettle();
    expect(repository.blockCalls, isEmpty);
    expect(find.byType(PostDetailPage), findsOneWidget);
  });

  testWidgets('失敗したときは案内し、詳細は閉じない', (tester) async {
    final repository = ScriptedPostRepository(
      [],
      actionError: const ApiException(
        code: 'FORBIDDEN',
        message: '',
        status: 403,
      ),
    );
    await pumpDetail(tester, repository, _post());
    await choose(tester, 'この投稿を非表示');
    await tester.tap(find.byKey(const ValueKey('post-action-confirm')));
    await tester.pumpAndSettle();
    expect(find.byType(PostDetailPage), findsOneWidget);
    expect(find.text('この操作はできません。'), findsOneWidget);
  });

  testWidgets('自分の投稿には、非表示・ブロックを出さない', (tester) async {
    final repository = ScriptedPostRepository([]);
    await pumpDetail(tester, repository, _post(isMine: true));
    await tester.tap(find.byTooltip('投稿メニュー'));
    await tester.pumpAndSettle();
    expect(find.text('この投稿を非表示'), findsNothing);
    expect(find.text('投稿者をブロック'), findsNothing);
    expect(find.text('投稿を編集'), findsOneWidget);
  });

  testWidgets('投稿者が分からない(ゲストの一覧の行)ときは、ブロックを実行しない', (tester) async {
    final repository = ScriptedPostRepository([]);
    await pumpDetail(tester, repository, _post(authorId: ''));
    await choose(tester, '投稿者をブロック');
    expect(find.text('投稿者をブロックしますか？'), findsNothing);
    expect(repository.blockCalls, isEmpty);
  });

  testWidgets('実データでは、サンプルの注記を出さない', (tester) async {
    final repository = ScriptedPostRepository([]);
    await pumpDetail(tester, repository, _post());
    await tester.tap(find.byTooltip('投稿メニュー'));
    await tester.pumpAndSettle();
    expect(find.text('投稿の操作'), findsOneWidget);
    expect(find.textContaining('モック'), findsNothing);
  });

  testWidgets('保存: 保存アイコンで、保存の切り替えをAPIへ送る', (tester) async {
    final repository = ScriptedPostRepository([]);
    await pumpDetail(tester, repository, _post());
    await tester.tap(find.byTooltip('保存する'));
    await tester.pumpAndSettle();
    expect(repository.saveCalls, ['p-1']);
    // 未保存の投稿は、「保存する」を求める(サーバーの状態は、調べない)。
    expect(repository.savedStates, [true]);
  });

  testWidgets('保存済みの投稿は、保存アイコンで、「解除する」を求める', (tester) async {
    final repository = ScriptedPostRepository([]);
    await pumpDetail(tester, repository, _post(isSaved: true));
    await tester.tap(find.byTooltip('保存を解除'));
    await tester.pumpAndSettle();
    expect(repository.saveCalls, ['p-1']);
    expect(repository.savedStates, [false]);
  });

  testWidgets('保存の失敗は案内する', (tester) async {
    final repository = ScriptedPostRepository(
      [],
      actionError: Exception('42501'),
    );
    await pumpDetail(tester, repository, _post());
    await tester.tap(find.byTooltip('保存する'));
    await tester.pumpAndSettle();
    expect(find.text('保存状態を変更できませんでした'), findsOneWidget);
  });
}
