import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kosodate_hitoiki/core/constants/app_icons.dart';
import 'package:kosodate_hitoiki/core/constants/app_theme.dart';
import 'package:kosodate_hitoiki/domain/models/post.dart';
import 'package:kosodate_hitoiki/domain/models/user_profile.dart';
import 'package:kosodate_hitoiki/domain/repositories/profile_repository.dart';
import 'package:kosodate_hitoiki/presentation/pages/auth/auth_page.dart';
import 'package:kosodate_hitoiki/presentation/pages/mypage/mypage_page.dart';
import 'package:kosodate_hitoiki/presentation/pages/profile/profile_edit_page.dart';
import 'package:kosodate_hitoiki/presentation/pages/settings/settings_page.dart';
import 'package:kosodate_hitoiki/presentation/providers/auth_provider.dart';
import 'package:kosodate_hitoiki/presentation/providers/post_providers.dart';
import 'package:kosodate_hitoiki/presentation/providers/profile_providers.dart';

import 'helpers/scripted_post_repository.dart';

class _FakeProfileRepository implements ProfileRepository {
  @override
  Future<UserProfile?> fetchProfile(String userId) async => const UserProfile(
    id: 'me',
    nickname: 'こもれび',
    avatarAsset: AppAvatars.defaultTulip,
    bio: '子育ての気持ちを、少しずつ。',
  );
}

Post _post(String id, String body, {bool underReview = false}) => Post(
  id: id,
  authorId: 'me',
  authorName: 'こもれび',
  authorAvatarAsset: AppAvatars.defaultTulip,
  createdAt: DateTime(2026, 10, 21),
  type: PostType.grumble,
  responseMode: ResponseMode.listening,
  body: body,
  empathyCount: 0,
  commentCount: 0,
  isMine: true,
  underReview: underReview,
);

Future<void> pumpMyPage(
  WidgetTester tester, {
  required bool loggedIn,
  ScriptedPostRepository? posts,
  double scale = 1,
  Size size = const Size(390, 900),
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        isLoggedInProvider.overrideWithValue(loggedIn),
        currentUserIdProvider.overrideWithValue(loggedIn ? 'me' : null),
        postRepositoryProvider.overrideWithValue(
          posts ?? ScriptedPostRepository([]),
        ),
        profileRepositoryProvider.overrideWithValue(_FakeProfileRepository()),
      ],
      child: MaterialApp(
        theme: AppTheme.light,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(scale)),
          child: child!,
        ),
        home: const Scaffold(body: MyPagePage()),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> reveal(
  WidgetTester tester,
  Finder finder, {
  double dy = 150,
}) async {
  await tester.scrollUntilVisible(
    finder,
    dy,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('ゲストには、登録・ログインの案内だけを出す(投稿一覧も編集も出さない)', (tester) async {
    await pumpMyPage(tester, loggedIn: false);
    expect(find.text('あなたのプロフィール'), findsOneWidget);
    expect(find.byType(SegmentedButton<bool>), findsNothing);
    expect(find.text('プロフィールを編集'), findsNothing);

    await reveal(tester, find.text('登録・ログイン'));
    await tester.tap(find.text('登録・ログイン'));
    await tester.pumpAndSettle();
    expect(find.byType(AuthPage), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.text('登録・ログイン'), findsOneWidget);
  });

  testWidgets('ログイン済みは、自分のニックネームと自己紹介を出す', (tester) async {
    await pumpMyPage(tester, loggedIn: true);
    expect(find.byKey(const ValueKey('mypage-name')), findsOneWidget);
    expect(find.text('こもれび'), findsOneWidget);
    expect(find.text('子育ての気持ちを、少しずつ。'), findsOneWidget);
    expect(find.text('登録・ログイン'), findsNothing);
  });

  testWidgets('自分の投稿を出し、通報で一時非表示の投稿には「確認中」を付ける', (tester) async {
    await pumpMyPage(
      tester,
      loggedIn: true,
      posts: ScriptedPostRepository(
        [],
        myPosts: [
          _post('p1', '公開中の投稿です。'),
          _post('p2', '確認中の投稿です。', underReview: true),
        ],
      ),
    );
    await reveal(tester, find.text('公開中の投稿です。'));
    expect(find.text('公開中の投稿です。'), findsOneWidget);
    await reveal(tester, find.text('確認中の投稿です。'));
    // 「確認中」の表示は、一時非表示の投稿にだけ付く。
    expect(find.byKey(const ValueKey('under-review-tag')), findsOneWidget);
    expect(find.byKey(const ValueKey('under-review-note')), findsOneWidget);
    expect(find.textContaining('サンプル'), findsNothing);
  });

  testWidgets('投稿が0件のときは、サンプルではない文言を出す', (tester) async {
    await pumpMyPage(tester, loggedIn: true);
    await reveal(tester, find.text('自分の投稿はまだありません'));
    expect(find.text('自分の投稿はまだありません'), findsOneWidget);
  });

  testWidgets('保存した投稿に切り替え、一覧を出す。戻っても選択を保持する', (tester) async {
    await pumpMyPage(
      tester,
      loggedIn: true,
      posts: ScriptedPostRepository([], savedPosts: [_post('s1', '保存した投稿です。')]),
    );
    await reveal(tester, find.text('保存した投稿'));
    await tester.tap(find.text('保存した投稿'));
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<SegmentedButton<bool>>(find.byType(SegmentedButton<bool>))
          .selected,
      {true},
    );
    await reveal(tester, find.text('あとで読みたい投稿'));
    expect(find.text('保存したことは相手に通知されません。'), findsOneWidget);
    await reveal(tester, find.text('保存した投稿です。'));
    expect(find.text('保存した投稿です。'), findsOneWidget);
  });

  testWidgets('小さい画面と拡大文字でプロフィール編集・設定の案内を開く', (tester) async {
    await pumpMyPage(
      tester,
      loggedIn: true,
      scale: 1.5,
      size: const Size(320, 640),
    );
    for (final label in ['設定', 'プロフィールを編集']) {
      await reveal(tester, find.text(label));
      await tester.ensureVisible(find.text(label));
      await tester.pumpAndSettle();
      await tester.tap(find.text(label));
      await tester.pumpAndSettle();
      expect(
        find.byType(label == '設定' ? SettingsPage : ProfileEditPage),
        findsOneWidget,
      );
      await tester.pageBack();
      await tester.pumpAndSettle();
    }
    expect(tester.takeException(), isNull);
  });
}
