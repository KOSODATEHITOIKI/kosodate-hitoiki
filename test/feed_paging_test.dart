import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kosodate_hitoiki/core/constants/app_theme.dart';
import 'package:kosodate_hitoiki/data/repositories/supabase_post_repository.dart';
import 'package:kosodate_hitoiki/domain/models/post.dart';
import 'package:kosodate_hitoiki/domain/models/topic.dart';
import 'package:kosodate_hitoiki/domain/repositories/post_repository.dart';
import 'package:kosodate_hitoiki/presentation/pages/home/home_page.dart';
import 'package:kosodate_hitoiki/presentation/providers/post_providers.dart';

import 'helpers/scripted_post_repository.dart';

List<Post> _posts(int count) => [
  for (var i = 0; i < count; i++)
    Post(
      id: 'p-$i',
      authorId: 'other',
      authorName: 'はな',
      authorAvatarAsset: 'assets/avatars/avatar-default-sprout.png',
      // 新着順(iが大きいほど古い)。
      createdAt: DateTime.utc(2026, 10, 22, 12).subtract(Duration(minutes: i)),
      type: PostType.grumble,
      responseMode: ResponseMode.listening,
      body: '投稿$i',
      empathyCount: 0,
      commentCount: 0,
    ),
];

ProviderContainer _container(ScriptedPostRepository repository) {
  final container = ProviderContainer(
    overrides: [postRepositoryProvider.overrideWithValue(repository)],
  );
  addTearDown(container.dispose);
  return container;
}

void main() {
  const page = PostRepository.pageSize;

  group('検索の引数', () {
    test('次のページは、最後の投稿の(時刻, ID)を両方渡す。最初のページには入れない', () {
      expect(SupabasePostRepository.searchParams(query: ''), {'p_limit': page});
      final last = _posts(1).single;
      final params = SupabasePostRepository.searchParams(
        query: '夜泣き',
        before: last,
      );
      expect(params['p_before_id'], 'p-0');
      expect(params['p_before_created_at'], '2026-10-22T12:00:00.000Z');
      expect(params['p_query'], '夜泣き');
    });
  });

  group('一覧の状態', () {
    test('1ページに満たなければ、「もっと見る」は出ない', () async {
      final repository = ScriptedPostRepository([])
        ..pagedPosts = _posts(page - 1);
      final container = _container(repository);
      final posts = await container.read(feedPostsProvider.future);

      expect(posts, hasLength(page - 1));
      expect(container.read(feedPostsProvider.notifier).hasMore, isFalse);
    });

    test('「もっと見る」で、最後の投稿より古い投稿を足す', () async {
      final repository = ScriptedPostRepository([])
        ..pagedPosts = _posts(page + 5);
      final container = _container(repository);
      await container.read(feedPostsProvider.future);
      final notifier = container.read(feedPostsProvider.notifier);
      expect(notifier.hasMore, isTrue);

      await notifier.loadMore();
      final posts = container.read(feedPostsProvider).value!;
      expect(posts, hasLength(page + 5));
      expect(repository.feedBeforeCalls, [null, 'p-${page - 1}']);
      // 最後のページは1ページに満たない。
      expect(notifier.hasMore, isFalse);
      // 重複しない。
      expect({for (final p in posts) p.id}, hasLength(page + 5));
    });

    test('続けて呼んでも、同じページを二重に読み込まない', () async {
      final repository = ScriptedPostRepository([])
        ..pagedPosts = _posts(page * 2 + 1);
      final container = _container(repository);
      await container.read(feedPostsProvider.future);
      final notifier = container.read(feedPostsProvider.notifier);

      final first = notifier.loadMore();
      final second = notifier.loadMore();
      await Future.wait([first, second]);
      expect(
        repository.feedBeforeCalls.where((id) => id != null),
        hasLength(1),
      );
    });

    test('次のページを読み込めなくても、出ている投稿は消えない。もう一度読み込める', () async {
      final repository = ScriptedPostRepository([])
        ..pagedPosts = _posts(page + 5)
        ..nextPageError = Exception('network');
      final container = _container(repository);
      await container.read(feedPostsProvider.future);
      final notifier = container.read(feedPostsProvider.notifier);

      await notifier.loadMore();
      expect(container.read(feedPostsProvider).value, hasLength(page));
      expect(notifier.loadMoreFailed, isTrue);
      expect(notifier.hasMore, isTrue);

      await notifier.loadMore();
      expect(container.read(feedPostsProvider).value, hasLength(page + 5));
      expect(notifier.loadMoreFailed, isFalse);
    });

    test('話題を変えると、最初のページから読み込み直す', () async {
      final repository = ScriptedPostRepository([])
        ..pagedPosts = _posts(page + 5);
      final container = _container(repository);
      await container.read(feedPostsProvider.future);
      await container.read(feedPostsProvider.notifier).loadMore();
      expect(container.read(feedPostsProvider).value, hasLength(page + 5));

      container.read(feedTopicProvider.notifier).state = const Topic(
        id: 2,
        label: '食事・離乳食',
      );
      final reloaded = await container.read(feedPostsProvider.future);
      expect(reloaded, hasLength(page));
      expect(repository.feedTopicCalls.last, 2);
      expect(repository.feedBeforeCalls.last, isNull);
    });
  });

  group('画面', () {
    Future<void> pumpHome(
      WidgetTester tester,
      ScriptedPostRepository repo,
    ) async {
      tester.view.physicalSize = const Size(390, 1600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [postRepositoryProvider.overrideWithValue(repo)],
          child: MaterialApp(
            theme: AppTheme.light,
            home: Scaffold(body: HomePage(onCompose: () {})),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('一覧の終わりに「もっと見る」が出て、押すと続きが読み込まれる', (tester) async {
      final repository = ScriptedPostRepository([])
        ..pagedPosts = _posts(page + 3);
      await pumpHome(tester, repository);

      await tester.scrollUntilVisible(
        find.byKey(const ValueKey('load-more')),
        400,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.ensureVisible(find.byKey(const ValueKey('load-more')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('load-more')));
      await tester.pumpAndSettle();

      expect(repository.feedBeforeCalls.last, 'p-${page - 1}');
      // 最後のページなので、ボタンは消える。
      expect(find.byKey(const ValueKey('load-more')), findsNothing);
    });

    testWidgets('1ページに収まるときは、「もっと見る」を出さない', (tester) async {
      final repository = ScriptedPostRepository([])..pagedPosts = _posts(3);
      await pumpHome(tester, repository);
      await tester.scrollUntilVisible(
        find.text('投稿2'),
        400,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.byKey(const ValueKey('load-more')), findsNothing);
    });
  });
}
