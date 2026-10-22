import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/mock/mock_post_repository.dart';
import '../../domain/models/blocked_user.dart';
import '../../domain/models/post.dart';
import '../../domain/models/topic.dart';
import '../../domain/repositories/post_repository.dart';

/// 投稿データの取得先。バックエンド接続時はここをSupabase実装に差し替える。
/// 利用者ID変化時はlib/app.dartがinvalidateして作り直す(ここで直接authをwatchしないのは、認証未初期化の単体テストを壊さないため)。
final postRepositoryProvider = Provider<PostRepository>(
  (ref) => MockPostRepository(),
);

/// 画面にサンプル投稿の注記を出すか。
final postsAreSampleProvider = Provider<bool>(
  (ref) => ref.watch(postRepositoryProvider).isSample,
);

/// 投稿の話題(運営が用意した少数の種類。未ログインでも読める)。
final topicsProvider = FutureProvider<List<Topic>>(
  (ref) => ref.watch(postRepositoryProvider).fetchTopics(),
);

/// ホームで選んでいる話題(選んでいなければ、すべて)。
final feedTopicProvider = StateProvider<Topic?>((ref) => null);

/// ホームの投稿一覧。話題を選んでいれば、その話題だけ。
final feedPostsProvider = FutureProvider<List<Post>>((ref) {
  final topic = ref.watch(feedTopicProvider);
  return ref.watch(postRepositoryProvider).fetchFeed(topicId: topic?.id);
});

/// 検索条件(キーワード・投稿種類・話題)。
class SearchQuery {
  const SearchQuery({this.keyword = '', this.type, this.topic});
  final String keyword;
  final PostType? type;
  final Topic? topic;

  SearchQuery copyWith({
    String? keyword,
    PostType? type,
    bool clearType = false,
    Topic? topic,
    bool clearTopic = false,
  }) => SearchQuery(
    keyword: keyword ?? this.keyword,
    type: clearType ? null : (type ?? this.type),
    topic: clearTopic ? null : (topic ?? this.topic),
  );
}

final searchQueryProvider = StateProvider<SearchQuery>(
  (ref) => const SearchQuery(),
);

/// 検索結果。
final searchResultsProvider = FutureProvider<List<Post>>((ref) {
  final query = ref.watch(searchQueryProvider);
  return ref
      .watch(postRepositoryProvider)
      .search(query: query.keyword, type: query.type, topicId: query.topic?.id);
});

/// マイページ: 自分の投稿。
final myPostsProvider = FutureProvider<List<Post>>(
  (ref) => ref.watch(postRepositoryProvider).fetchMyPosts(),
);

/// マイページ: 保存した投稿。
final savedPostsProvider = FutureProvider<List<Post>>(
  (ref) => ref.watch(postRepositoryProvider).fetchSavedPosts(),
);

/// 設定: ブロック中の相手。
final blockedUsersProvider = FutureProvider<List<BlockedUser>>(
  (ref) => ref.watch(postRepositoryProvider).fetchBlockedUsers(),
);
