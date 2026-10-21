import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kosodate_hitoiki/core/constants/app_icons.dart';
import 'package:kosodate_hitoiki/core/constants/app_theme.dart';
import 'package:kosodate_hitoiki/data/api/api_exception.dart';
import 'package:kosodate_hitoiki/data/repositories/supabase_post_repository.dart';
import 'package:kosodate_hitoiki/domain/models/post.dart';
import 'package:kosodate_hitoiki/domain/models/reaction_type.dart';
import 'package:kosodate_hitoiki/presentation/pages/post_detail/post_detail_page.dart';
import 'package:kosodate_hitoiki/presentation/providers/auth_provider.dart';
import 'package:kosodate_hitoiki/presentation/providers/post_providers.dart';
import 'package:kosodate_hitoiki/presentation/widgets/post_card.dart';

import 'helpers/scripted_post_repository.dart';

Post _post({bool isMine = false, String id = 'p-1'}) => Post(
  id: id,
  authorId: isMine ? 'me' : 'other',
  authorName: 'はな',
  authorAvatarAsset: 'assets/avatars/avatar-default-sprout.png',
  createdAt: DateTime(2026, 10, 22),
  type: PostType.grumble,
  responseMode: ResponseMode.listening,
  body: '今日はつらかった。',
  empathyCount: 0,
  commentCount: 0,
  isMine: isMine,
);

Future<void> pumpCard(
  WidgetTester tester,
  ScriptedPostRepository repository,
  Post post,
) async {
  tester.view.physicalSize = const Size(390, 1200);
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
        home: Scaffold(
          body: SingleChildScrollView(child: PostCard(post: post)),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> pumpDetail(
  WidgetTester tester,
  ScriptedPostRepository repository,
  Post post,
) async {
  tester.view.physicalSize = const Size(390, 1200);
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

void main() {
  test('reaction_typesの行を、定型文にする。codeでアイコンを選ぶ', () {
    final type = SupabasePostRepository.reactionTypeFromRow({
      'id': 4,
      'code': 'gentle_cheer',
      'label': 'そっと応援',
      'sort_order': 4,
    });
    expect(type.id, 4);
    expect(type.label, 'そっと応援');
    expect(type.isEmpathy, isFalse);
    expect(type.asset, AppReactions.gentleCheer);
    expect(
      const ReactionType(id: 1, code: 'empathy', label: 'わかる').isEmpathy,
      isTrue,
    );
    // 未知のcodeは、共感(わかる)のアイコン。
    expect(AppReactions.forCode('???'), AppReactions.empathy);
  });

  testWidgets('「わかる」を押すと、共感(empathy)を送り、もう一度押すと取り消す', (tester) async {
    final repository = ScriptedPostRepository([]);
    await pumpCard(tester, repository, _post());

    await tester.tap(find.text('わかる'));
    await tester.pumpAndSettle();
    expect(repository.setReactionCalls, [(postId: 'p-1', typeId: 1)]);
    expect(find.text('わかる ✓'), findsOneWidget);

    await tester.tap(find.text('わかる ✓'));
    await tester.pumpAndSettle();
    expect(repository.removeReactionCalls, ['p-1']);
    expect(find.text('わかる'), findsOneWidget);
  });

  testWidgets('すでに選んでいる定型文が、読み込まれて表示される', (tester) async {
    final repository = ScriptedPostRepository([], myReactions: {'p-1': 3});
    await pumpCard(tester, repository, _post());
    expect(find.text('聞いているよ ✓'), findsOneWidget);
  });

  testWidgets('送れなかったら、元に戻して、案内する', (tester) async {
    final repository = ScriptedPostRepository(
      [],
      reactionError: const ApiException(
        code: 'FORBIDDEN',
        message: '',
        status: 403,
        details: {'reason': 'unavailable'},
      ),
    );
    await pumpCard(tester, repository, _post());
    await tester.tap(find.text('わかる'));
    await tester.pumpAndSettle();

    expect(repository.setReactionCalls, hasLength(1));
    expect(find.text('わかる ✓'), findsNothing);
    expect(find.text('わかる'), findsOneWidget);
    expect(find.byType(SnackBar), findsOneWidget);
  });

  testWidgets('送信中に続けて押しても、二重に送らない', (tester) async {
    final gate = Completer<void>();
    final repository = _GatedRepository(gate.future);
    await pumpCard(tester, repository, _post());

    await tester.tap(find.text('わかる'));
    await tester.pump();
    // 表示はすぐに変わる。送信が終わる前に、もう一度押す。
    await tester.tap(find.text('わかる ✓'));
    await tester.pump();
    gate.complete();
    await tester.pumpAndSettle();

    expect(repository.setReactionCalls, hasLength(1));
    expect(repository.removeReactionCalls, isEmpty);
  });

  testWidgets('自分の投稿には、共感できない。件数だけを出す', (tester) async {
    final repository = ScriptedPostRepository([], reactionCounts: {'p-1': 4});
    await pumpCard(tester, repository, _post(isMine: true));

    expect(find.text('わかる 4'), findsOneWidget);
    await tester.tap(find.text('わかる 4'));
    await tester.pumpAndSettle();
    expect(repository.setReactionCalls, isEmpty);
    expect(repository.removeReactionCalls, isEmpty);
  });

  testWidgets('詳細: 定型文を選び直せて、取り消せる(取得したマスタの文言で)', (tester) async {
    final repository = ScriptedPostRepository([]);
    await pumpDetail(tester, repository, _post());

    await tester.ensureVisible(find.text('定型文を送る'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('定型文を送る'));
    await tester.pumpAndSettle();
    expect(find.text('おつかれさま'), findsOneWidget);
    expect(find.textContaining('サンプル'), findsNothing);

    await tester.tap(find.text('おつかれさま'));
    await tester.pumpAndSettle();
    expect(repository.setReactionCalls.last, (postId: 'p-1', typeId: 2));
    expect(find.text('おつかれさま ✓'), findsOneWidget);

    await tester.tap(find.text('おつかれさま ✓'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('共感を取り消す'));
    await tester.pumpAndSettle();
    expect(repository.removeReactionCalls, ['p-1']);
  });

  testWidgets('詳細: 定型文を読み込めなかったら、再読み込みできる', (tester) async {
    final repository = _FlakyTypesRepository();
    await pumpDetail(tester, repository, _post());
    await tester.ensureVisible(find.text('定型文を送る'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('定型文を送る'));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('reaction-types-failed')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('reaction-types-retry')));
    await tester.pumpAndSettle();
    expect(find.text('おつかれさま'), findsOneWidget);
  });
}

/// 共感の送信を、決めるまで待たせる。
class _GatedRepository extends ScriptedPostRepository {
  _GatedRepository(this._gate) : super([]);
  final Future<void> _gate;

  @override
  Future<void> setReaction({
    required String postId,
    required int reactionTypeId,
  }) async {
    await _gate;
    return super.setReaction(postId: postId, reactionTypeId: reactionTypeId);
  }
}

/// 定型文の取得が、1回目だけ失敗する。
class _FlakyTypesRepository extends ScriptedPostRepository {
  _FlakyTypesRepository() : super([]);
  var _calls = 0;

  @override
  Future<List<ReactionType>> fetchReactionTypes() async {
    if (_calls++ == 0) throw Exception('network');
    return super.fetchReactionTypes();
  }
}
