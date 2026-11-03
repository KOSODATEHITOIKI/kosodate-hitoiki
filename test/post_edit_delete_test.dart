import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kosodate_hitoiki/core/constants/app_theme.dart';
import 'package:kosodate_hitoiki/data/api/api_exception.dart';
import 'package:kosodate_hitoiki/domain/models/post.dart';
import 'package:kosodate_hitoiki/presentation/pages/compose/compose_page.dart';
import 'package:kosodate_hitoiki/presentation/pages/compose/compose_review_page.dart';
import 'package:kosodate_hitoiki/presentation/pages/post_detail/post_detail_page.dart';
import 'package:kosodate_hitoiki/presentation/providers/auth_provider.dart';
import 'package:kosodate_hitoiki/presentation/providers/post_providers.dart';

import 'helpers/scripted_post_repository.dart';

final _post = Post(
  id: 'p-1',
  authorId: 'me',
  authorName: 'こもれび',
  authorAvatarAsset: 'assets/avatars/avatar-default-sprout.png',
  createdAt: DateTime(2026, 10, 21),
  type: PostType.consult,
  responseMode: ResponseMode.advice,
  body: 'もとの本文です。',
  empathyCount: 0,
  commentCount: 0,
  isMine: true,
);

EditResult edited({bool supportNotice = false}) => EditResult(
  editedAt: DateTime(2026, 10, 21, 10),
  supportNotice: supportNotice,
);

Future<void> tapKey(WidgetTester tester, String key) async {
  await tester.scrollUntilVisible(
    find.byKey(ValueKey(key)),
    200,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(ValueKey(key)));
  await tester.pumpAndSettle();
}

/// [child]を、別の画面から開き、閉じたときの戻り値を[result]に入れる。
Future<void> pumpOpened(
  WidgetTester tester,
  ScriptedPostRepository repository,
  Widget child, {
  required List<Object?> result,
}) async {
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
                onPressed: () async {
                  result.add(
                    await Navigator.of(
                      context,
                    ).push<Object?>(MaterialPageRoute(builder: (_) => child)),
                  );
                },
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

void main() {
  group('確認画面(編集)', () {
    const review = ComposeReviewPage(
      body: '直した本文です。',
      postType: PostType.consult,
      responseMode: ResponseMode.advice,
      editing: true,
      postId: 'p-1',
    );

    testWidgets('編集できたら、本文だけをAPIへ送り(作成は呼ばない)、「変更しました」を出す', (tester) async {
      final repository = ScriptedPostRepository([], editScript: [edited()]);
      final result = <Object?>[];
      await pumpOpened(tester, repository, review, result: result);

      expect(find.text('変更の確認'), findsOneWidget);
      expect(find.text('この内容で変更する'), findsOneWidget);
      await tapKey(tester, 'compose-send');

      expect(repository.editCalls, hasLength(1));
      expect(repository.editCalls.single.postId, 'p-1');
      expect(repository.editCalls.single.body, '直した本文です。');
      expect(repository.editCalls.single.confirmed, isFalse);
      expect(repository.calls, isEmpty);
      expect(find.text('変更しました。'), findsOneWidget);

      await tapKey(tester, 'compose-done');
      expect(result, [true]);
    });

    testWidgets('確認が必要なときは確認を出し、「そのまま投稿する」で confirmed:true で再送する', (
      tester,
    ) async {
      final repository = ScriptedPostRepository(
        [],
        editScript: [
          const ApiException(
            code: 'MODERATION_CONFIRM_REQUIRED',
            message: '強い言葉が含まれています。',
            status: 409,
          ),
          edited(),
        ],
      );
      await pumpOpened(tester, repository, review, result: []);
      await tapKey(tester, 'compose-send');
      expect(find.text('強い言葉が含まれています。'), findsOneWidget);

      await tapKey(tester, 'compose-send');
      expect(repository.editCalls, hasLength(2));
      expect(repository.editCalls[1].confirmed, isTrue);
      expect(find.text('変更しました。'), findsOneWidget);
    });

    testWidgets('送信不可のときは理由を出し、送るボタンはない', (tester) async {
      final repository = ScriptedPostRepository(
        [],
        editScript: [
          const ApiException(
            code: 'MODERATION_REJECTED',
            message: '',
            status: 422,
            details: {
              'reasons': ['pii_phone'],
            },
          ),
        ],
      );
      await pumpOpened(tester, repository, review, result: []);
      await tapKey(tester, 'compose-send');
      expect(find.textContaining('個人が特定される情報'), findsOneWidget);
      expect(find.byKey(const ValueKey('compose-send')), findsNothing);
    });
  });

  group('書く画面(編集)', () {
    testWidgets('編集できるのは本文だけ。種類・反応の希望は選べず、直して保存すると新しい本文を返す', (tester) async {
      final repository = ScriptedPostRepository([], editScript: [edited()]);
      final result = <Object?>[];
      await pumpOpened(
        tester,
        repository,
        Scaffold(body: ComposePage(initialPost: _post)),
        result: result,
      );

      expect(find.byKey(const ValueKey('compose-edit-note')), findsOneWidget);
      expect(
        tester.widget<TextField>(find.byType(TextField)).controller!.text,
        'もとの本文です。',
      );
      // 種類のチップは、押せない。
      for (final chip in tester.widgetList<ChoiceChip>(
        find.byType(ChoiceChip),
      )) {
        expect(chip.onSelected, isNull);
      }

      await tester.enterText(find.byType(TextField), '  直した本文です。  ');
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pumpAndSettle();
      await tapKey(tester, 'compose-submit');
      await tapKey(tester, 'compose-send');
      await tapKey(tester, 'compose-done');

      expect(repository.editCalls.single.body.trim(), '直した本文です。');
      // 新しい本文を持って、詳細へ戻る。
      expect(result, ['直した本文です。']);
    });
  });

  group('投稿詳細(編集・削除)', () {
    Future<void> openMenu(WidgetTester tester, String label) async {
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

    testWidgets('削除: 確認して削除すると、APIを呼び、詳細を閉じる', (tester) async {
      final repository = ScriptedPostRepository([]);
      final result = <Object?>[];
      await pumpOpened(
        tester,
        repository,
        PostDetailPage(post: _post),
        result: result,
      );
      await openMenu(tester, '投稿を削除');
      expect(find.text('投稿を削除しますか？'), findsOneWidget);
      expect(find.textContaining('元に戻せません'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('post-delete-confirm')));
      await tester.pumpAndSettle();

      expect(repository.deleteCalls, ['p-1']);
      expect(find.byType(PostDetailPage), findsNothing);
      expect(find.text('投稿を削除しました'), findsOneWidget);
    });

    testWidgets('削除の失敗は案内し、詳細は閉じない', (tester) async {
      final repository = ScriptedPostRepository(
        [],
        deleteError: const ApiException(
          code: 'NOT_FOUND',
          message: '',
          status: 404,
        ),
      );
      await pumpOpened(
        tester,
        repository,
        PostDetailPage(post: _post),
        result: [],
      );
      await openMenu(tester, '投稿を削除');
      await tester.tap(find.byKey(const ValueKey('post-delete-confirm')));
      await tester.pumpAndSettle();

      expect(find.byType(PostDetailPage), findsOneWidget);
      expect(find.text('見つかりませんでした。すでに削除されているかもしれません。'), findsOneWidget);
    });

    testWidgets('編集できたら、詳細にすぐ新しい本文が出る', (tester) async {
      final repository = ScriptedPostRepository([], editScript: [edited()]);
      await pumpOpened(
        tester,
        repository,
        PostDetailPage(post: _post),
        result: [],
      );
      expect(find.text('もとの本文です。'), findsOneWidget);
      await openMenu(tester, '投稿を編集');
      await tester.enterText(find.byType(TextField), '直した本文です。');
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pumpAndSettle();
      await tapKey(tester, 'compose-submit');
      await tapKey(tester, 'compose-send');
      await tapKey(tester, 'compose-done');

      expect(find.byType(PostDetailPage), findsOneWidget);
      expect(find.text('直した本文です。'), findsOneWidget);
      expect(find.text('もとの本文です。'), findsNothing);
    });
  });
}
