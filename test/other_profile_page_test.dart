import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kosodate_hitoiki/core/constants/app_theme.dart';
import 'package:kosodate_hitoiki/data/mock/mock_profile_repository.dart';
import 'package:kosodate_hitoiki/data/mock/mock_post_repository.dart';
import 'package:kosodate_hitoiki/domain/models/user_profile.dart';
import 'package:kosodate_hitoiki/presentation/pages/auth/auth_page.dart';
import 'package:kosodate_hitoiki/presentation/pages/profile/other_profile_page.dart';
import 'package:kosodate_hitoiki/presentation/providers/auth_provider.dart';
import 'package:kosodate_hitoiki/presentation/providers/profile_providers.dart';
import 'package:kosodate_hitoiki/presentation/widgets/post_card.dart';

class _Repository extends MockProfileRepository {
  int calls = 0;
  bool fail = false;
  @override
  Future<UserProfile?> fetchProfile(String userId) {
    calls++;
    if (fail) throw StateError('offline');
    return super.fetchProfile(userId);
  }
}

void main() {
  testWidgets('画面表示中にログアウトするとプロフィール本文を取り除く', (tester) async {
    final session = StateProvider<bool>((ref) => true);
    final container = ProviderContainer(
      overrides: [isLoggedInProvider.overrideWith((ref) => ref.watch(session))],
    );
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: AppTheme.light,
          home: const OtherProfilePage(userId: 'sample-hana'),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('はな'), findsOneWidget);
    container.read(session.notifier).state = false;
    await tester.pumpAndSettle();
    expect(find.text('はな'), findsNothing);
    expect(find.text('未就学児'), findsNothing);
    expect(find.text('ログイン'), findsOneWidget);
  });
  testWidgets('直接開いてもゲストのプロフィール取得は0回・ログイン画面から戻れる', (tester) async {
    final repository = _Repository();
    final container = ProviderContainer(
      overrides: [
        isLoggedInProvider.overrideWithValue(false),
        profileRepositoryProvider.overrideWithValue(repository),
      ],
    );
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: AppTheme.light,
          home: const OtherProfilePage(userId: 'sample-hana'),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(repository.calls, 0);
    expect(find.text('はな'), findsNothing);
    expect(find.text('未就学児'), findsNothing);
    // 画面以外からProviderを読んでも、取得しない。
    expect(
      await container.read(otherProfileProvider('sample-hana').future),
      isNull,
    );
    expect(repository.calls, 0);
    await tester.ensureVisible(find.text('ログイン'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('ログイン'));
    await tester.pumpAndSettle();
    expect(find.byType(AuthPage), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.byType(OtherProfilePage), findsOneWidget);
    expect(repository.calls, 0);
  });

  for (final width in [320.0, 768.0]) {
    for (final scale in [1.0, 2.0]) {
      testWidgets('幅$width・文字倍率$scaleで投稿者からプロフィールと通報案内を開ける', (tester) async {
        tester.view.physicalSize = Size(width, 800);
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
              home: Scaffold(
                body: SingleChildScrollView(child: PostCard(post: post)),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.text('はな'));
        await tester.pumpAndSettle();
        expect(find.byType(OtherProfilePage), findsOneWidget);
        expect(find.text('慌ただしい毎日、\nここでひと息ついています。'), findsOneWidget);
        expect(find.text('未就学児'), findsOneWidget);
        expect(find.byType(PostCard), findsNothing);
        await tester.scrollUntilVisible(
          find.text('通報'),
          150,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.pumpAndSettle();
        await tester.tap(find.text('通報'));
        await tester.pumpAndSettle();
        expect(find.text('この利用者について'), findsOneWidget);
        await tester.pageBack();
        await tester.pumpAndSettle();
        await tester.ensureVisible(find.text('ブロック'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('ブロック'));
        await tester.pumpAndSettle();
        expect(find.text('ブロックは準備中です'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }
  }

  testWidgets('取得失敗から再試行でき未設定項目を表示する', (tester) async {
    final repository = _Repository()..fail = true;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          isLoggedInProvider.overrideWithValue(true),
          profileRepositoryProvider.overrideWithValue(repository),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          home: const OtherProfilePage(userId: 'sample-haru'),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('読み込めませんでした'), findsOneWidget);
    repository.fail = false;
    await tester.ensureVisible(find.text('再読み込み'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('再読み込み'));
    await tester.pumpAndSettle();
    expect(repository.calls, 2);
    expect(find.text('自己紹介はまだありません。'), findsOneWidget);
    expect(find.text('未設定'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('存在しないプロフィールは空表示', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [isLoggedInProvider.overrideWithValue(true)],
        child: MaterialApp(
          theme: AppTheme.light,
          home: const OtherProfilePage(userId: 'missing'),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('プロフィールが見つかりません'), findsOneWidget);
    expect(find.text('通報'), findsNothing);
  });
}
