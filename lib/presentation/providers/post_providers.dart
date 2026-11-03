import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/mock/mock_post_repository.dart';
import '../../domain/models/blocked_user.dart';
import '../../domain/models/post.dart';
import '../../domain/models/topic.dart';
import '../../domain/repositories/post_repository.dart';
import 'auth_provider.dart';

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

/// ページ送りのある投稿の一覧。最初のページを読み込み、[loadMore]で次のページを足す。
/// 条件(話題・検索語など)が変わると、最初から読み込み直す。
abstract class PagedPosts extends AsyncNotifier<List<Post>> {
  /// 次のページがありそうか(直前のページが、1ページの件数に達していた)。
  bool hasMore = false;

  /// 次のページを読み込み中か(続けて読み込まない)。
  bool isLoadingMore = false;

  /// 条件が変わって作り直されるたびに増やす(古い読み込みの結果を捨てるため)。
  int _generation = 0;

  /// 次のページの読み込みに失敗したか(「もっと見る」を、もう一度押せるようにする)。
  bool loadMoreFailed = false;

  /// すでに読み込んだ投稿[loaded]の、次の1ページを取得する。空なら最初のページ。
  Future<List<Post>> fetchPage(List<Post> loaded);

  @override
  Future<List<Post>> build() async {
    final generation = ++_generation;
    isLoadingMore = false;
    loadMoreFailed = false;
    final page = await fetchPage(const []);
    if (generation == _generation) {
      hasMore = page.length >= PostRepository.pageSize;
    }
    return page;
  }

  /// 次のページを足す。失敗しても、いま出ている投稿は消さない。
  Future<void> loadMore() async {
    final current = state.valueOrNull;
    if (current == null || current.isEmpty || !hasMore || isLoadingMore) return;
    final generation = _generation;
    isLoadingMore = true;
    loadMoreFailed = false;
    state = AsyncData(current);
    try {
      final page = await fetchPage(current);
      // 読み込み中に条件が変わって作り直された場合は、足さない。
      if (generation != _generation) return;
      final known = {for (final post in current) post.id};
      hasMore = page.length >= PostRepository.pageSize;
      state = AsyncData([
        ...current,
        for (final post in page)
          if (!known.contains(post.id)) post,
      ]);
    } catch (_) {
      if (generation != _generation) return;
      loadMoreFailed = true;
      state = AsyncData(current);
    } finally {
      if (generation == _generation) {
        isLoadingMore = false;
        // 読み込み中の表示を消すため、状態を通知し直す。
        final latest = state.valueOrNull;
        if (latest != null) state = AsyncData(latest);
      }
    }
  }
}

class _FeedPosts extends PagedPosts {
  @override
  Future<List<Post>> fetchPage(List<Post> loaded) {
    final topic = ref.read(feedTopicProvider);
    return ref
        .read(postRepositoryProvider)
        .fetchFeed(
          topicId: topic?.id,
          before: loaded.isEmpty ? null : loaded.last,
        );
  }

  @override
  Future<List<Post>> build() {
    // 話題・リポジトリが変わったら、最初から読み込み直す。
    ref.watch(feedTopicProvider);
    ref.watch(postRepositoryProvider);
    return super.build();
  }
}

/// ホームの投稿一覧。話題を選んでいれば、その話題だけ。
final feedPostsProvider = AsyncNotifierProvider<PagedPosts, List<Post>>(
  _FeedPosts.new,
);

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

class _SearchResults extends PagedPosts {
  @override
  Future<List<Post>> build() {
    ref.watch(searchQueryProvider);
    ref.watch(postRepositoryProvider);
    return super.build();
  }

  @override
  Future<List<Post>> fetchPage(List<Post> loaded) {
    final query = ref.read(searchQueryProvider);
    return ref
        .read(postRepositoryProvider)
        .search(
          query: query.keyword,
          type: query.type,
          topicId: query.topic?.id,
          before: loaded.isEmpty ? null : loaded.last,
        );
  }
}

/// 検索結果。
final searchResultsProvider = AsyncNotifierProvider<PagedPosts, List<Post>>(
  _SearchResults.new,
);

class _MyPosts extends PagedPosts {
  @override
  Future<List<Post>> build() {
    ref.watch(postRepositoryProvider);
    return super.build();
  }

  @override
  Future<List<Post>> fetchPage(List<Post> loaded) =>
      ref.read(postRepositoryProvider).fetchMyPosts(offset: loaded.length);
}

class _SavedPosts extends PagedPosts {
  @override
  Future<List<Post>> build() {
    ref.watch(postRepositoryProvider);
    return super.build();
  }

  @override
  Future<List<Post>> fetchPage(List<Post> loaded) =>
      ref.read(postRepositoryProvider).fetchSavedPosts(offset: loaded.length);
}

/// マイページ: 自分の投稿。
final myPostsProvider = AsyncNotifierProvider<PagedPosts, List<Post>>(
  _MyPosts.new,
);

/// マイページ: 保存した投稿。
final savedPostsProvider = AsyncNotifierProvider<PagedPosts, List<Post>>(
  _SavedPosts.new,
);

/// 投稿1件の最新の状態(投稿IDで取得)。詳細画面が使う。一覧に載っていない投稿
/// (検索・保存一覧・通知から開いた投稿)でも、本文・投稿者・自分の投稿かを、最新にするため。
/// 見えない投稿・取得できない場合は`null`(画面は、開いたときの投稿を使う)。
final postDetailProvider = FutureProvider.autoDispose.family<Post?, String>((
  ref,
  postId,
) async {
  // 投稿の取得は、ログインが必要(ゲストは、開いたときの投稿を使う)。
  if (!ref.watch(isLoggedInProvider)) return null;
  return ref.watch(postRepositoryProvider).fetchPost(postId);
});

/// 設定: ブロック中の相手。
final blockedUsersProvider = FutureProvider<List<BlockedUser>>(
  (ref) => ref.watch(postRepositoryProvider).fetchBlockedUsers(),
);
