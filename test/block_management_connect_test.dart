import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kosodate_hitoiki/core/constants/app_icons.dart';
import 'package:kosodate_hitoiki/core/constants/app_theme.dart';
import 'package:kosodate_hitoiki/data/repositories/supabase_post_repository.dart';
import 'package:kosodate_hitoiki/domain/models/blocked_user.dart';
import 'package:kosodate_hitoiki/presentation/pages/settings/block_management_page.dart';
import 'package:kosodate_hitoiki/presentation/providers/auth_provider.dart';
import 'package:kosodate_hitoiki/presentation/providers/post_providers.dart';

import 'helpers/scripted_post_repository.dart';

const _hana = BlockedUser(
  id: 'u-1',
  nickname: 'はな',
  avatarAsset: AppAvatars.defaultTulip,
);
const _sora = BlockedUser(
  id: 'u-2',
  nickname: 'そら',
  avatarAsset: AppAvatars.defaultSun,
);

Future<void> pumpPage(
  WidgetTester tester,
  ScriptedPostRepository repository,
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
        home: const BlockManagementPage(),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> unblock(WidgetTester tester, String userId) async {
  await tester.tap(find.byKey(ValueKey('unblock-$userId')));
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(const ValueKey('unblock-confirm')));
  await tester.pumpAndSettle();
}

void main() {
  test('my_blocksの行を、ブロック中の相手にする(画像は、あればその公開URL)', () {
    final user = SupabasePostRepository.blockedUserFromRow({
      'blocked_id': 'u-1',
      'blocked_nickname': 'はな',
      'blocked_icon_key': 'tulip',
      'blocked_avatar_path': null,
      'created_at': '2026-10-21T00:00:00Z',
    });
    expect(user.id, 'u-1');
    expect(user.nickname, 'はな');
    expect(user.avatarAsset, AppAvatars.defaultTulip);

    final withPhoto = SupabasePostRepository.blockedUserFromRow({
      'blocked_id': 'u-2',
      'blocked_nickname': null,
      'blocked_icon_key': null,
      'blocked_avatar_path': 'u-2/a.png',
    });
    expect(withPhoto.nickname, '');
    expect(withPhoto.avatarAsset, contains('/avatars/u-2/a.png'));
  });

  testWidgets('実データでは、取得した相手を並べ、「サンプル」と出さない', (tester) async {
    await pumpPage(tester, ScriptedPostRepository([], blocked: [_hana, _sora]));
    expect(find.text('はな'), findsOneWidget);
    expect(find.text('そら'), findsOneWidget);
    expect(find.textContaining('サンプル'), findsNothing);
  });

  testWidgets('誰もブロックしていなければ、その旨を出す', (tester) async {
    await pumpPage(tester, ScriptedPostRepository([]));
    expect(find.byKey(const ValueKey('blocks-empty')), findsOneWidget);
  });

  testWidgets('解除: 確認してから送り、その相手だけが一覧から消える', (tester) async {
    final repository = ScriptedPostRepository([], blocked: [_hana, _sora]);
    await pumpPage(tester, repository);
    await tester.tap(find.byKey(const ValueKey('unblock-u-1')));
    await tester.pumpAndSettle();
    expect(find.text('はなさんのブロックを解除しますか？'), findsOneWidget);
    // 確認の前は、送らない。
    expect(repository.unblockCalls, isEmpty);
    await tester.tap(find.byKey(const ValueKey('unblock-confirm')));
    await tester.pumpAndSettle();

    expect(repository.unblockCalls, ['u-1']);
    expect(find.text('はな'), findsNothing);
    expect(find.text('そら'), findsOneWidget);
    expect(find.text('ブロックを解除しました'), findsOneWidget);
  });

  testWidgets('キャンセルしたら、送らない', (tester) async {
    final repository = ScriptedPostRepository([], blocked: [_hana]);
    await pumpPage(tester, repository);
    await tester.tap(find.byKey(const ValueKey('unblock-u-1')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('キャンセル'));
    await tester.pumpAndSettle();
    expect(repository.unblockCalls, isEmpty);
    expect(find.text('はな'), findsOneWidget);
  });

  testWidgets('解除できなかったら、案内して、一覧は変えない', (tester) async {
    final repository = ScriptedPostRepository(
      [],
      blocked: [_hana],
      unblockError: Exception('network'),
    );
    await pumpPage(tester, repository);
    await unblock(tester, 'u-1');
    expect(repository.unblockCalls, ['u-1']);
    expect(find.text('はな'), findsOneWidget);
    expect(find.text('ブロックを解除しました'), findsNothing);
    expect(find.textContaining('うまくいきませんでした'), findsOneWidget);
  });

  testWidgets('読み込めなかったら、再読み込みできる', (tester) async {
    final repository = ScriptedPostRepository(
      [],
      blocked: [_hana],
      blockedFetchErrors: [Exception('network')],
    );
    await pumpPage(tester, repository);
    expect(find.byKey(const ValueKey('blocks-load-failed')), findsOneWidget);
    expect(find.text('はな'), findsNothing);

    await tester.tap(find.byKey(const ValueKey('blocks-retry')));
    await tester.pumpAndSettle();
    expect(find.text('はな'), findsOneWidget);
  });
}
