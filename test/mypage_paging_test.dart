import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kosodate_hitoiki/domain/models/post.dart';
import 'package:kosodate_hitoiki/domain/repositories/post_repository.dart';
import 'package:kosodate_hitoiki/presentation/providers/post_providers.dart';

import 'helpers/scripted_post_repository.dart';

List<Post> _posts(int count) => [
  for (var i = 0; i < count; i++)
    Post(
      id: 'm-$i',
      authorId: 'me',
      authorName: 'こもれび',
      authorAvatarAsset: 'assets/avatars/avatar-default-sprout.png',
      createdAt: DateTime.utc(2026, 10, 22).subtract(Duration(minutes: i)),
      type: PostType.grumble,
      responseMode: ResponseMode.listening,
      body: '投稿$i',
      empathyCount: 0,
      commentCount: 0,
      isMine: true,
    ),
];

void main() {
  const page = PostRepository.pageSize;

  for (final saved in [false, true]) {
    final provider = saved ? savedPostsProvider : myPostsProvider;
    final name = saved ? '保存した投稿' : '自分の投稿';

    test('$name: 「もっと見る」で、読み込んだ件数の続きから足す', () async {
      final repository = saved
          ? ScriptedPostRepository([], savedPosts: _posts(page + 4))
          : ScriptedPostRepository([], myPosts: _posts(page + 4));
      final container = ProviderContainer(
        overrides: [postRepositoryProvider.overrideWithValue(repository)],
      );
      addTearDown(container.dispose);

      expect(await container.read(provider.future), hasLength(page));
      final notifier = container.read(provider.notifier);
      expect(notifier.hasMore, isTrue);

      await notifier.loadMore();
      final posts = container.read(provider).value!;
      expect(posts, hasLength(page + 4));
      expect({for (final p in posts) p.id}, hasLength(page + 4));
      expect(notifier.hasMore, isFalse);
    });

    test('$name: 1ページに満たなければ、続きはない', () async {
      final repository = saved
          ? ScriptedPostRepository([], savedPosts: _posts(3))
          : ScriptedPostRepository([], myPosts: _posts(3));
      final container = ProviderContainer(
        overrides: [postRepositoryProvider.overrideWithValue(repository)],
      );
      addTearDown(container.dispose);
      await container.read(provider.future);
      expect(container.read(provider.notifier).hasMore, isFalse);
    });
  }
}
