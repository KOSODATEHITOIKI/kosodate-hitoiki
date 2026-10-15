import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/mock/mock_post_repository.dart';
import '../../domain/models/post.dart';
import '../../domain/repositories/post_repository.dart';

/// 投稿データの取得先。バックエンド接続時はここをSupabase実装に差し替える。
///
/// ログイン状態の変化(ログイン・ログアウト・利用者の切り替え)時には
/// lib/app.dartがこのProviderをinvalidateし、新しいリポジトリを作り直す。
/// モック実装は投稿データをメモリ内に保持するため、作り直さないと前の
/// 利用者が変更した保存状態等が次の利用者に引き継がれてしまう。
/// ここでisLoggedInProviderを直接watchしない(Supabase初期化前の単体
/// テストやAppを経由しないWidget単体テストが、認証チェーンに巻き込まれて
/// 壊れるのを避けるため)。
final postRepositoryProvider = Provider<PostRepository>(
  (ref) => MockPostRepository(),
);

/// ホームの投稿一覧。
final feedPostsProvider = FutureProvider<List<Post>>(
  (ref) => ref.watch(postRepositoryProvider).fetchFeed(),
);

/// 検索条件(キーワード・投稿種類)。
class SearchQuery {
  const SearchQuery({this.keyword = '', this.type});
  final String keyword;
  final PostType? type;

  SearchQuery copyWith({
    String? keyword,
    PostType? type,
    bool clearType = false,
  }) => SearchQuery(
    keyword: keyword ?? this.keyword,
    type: clearType ? null : (type ?? this.type),
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
      .search(query: query.keyword, type: query.type);
});

/// マイページ: 自分の投稿。
final myPostsProvider = FutureProvider<List<Post>>(
  (ref) => ref.watch(postRepositoryProvider).fetchMyPosts(),
);

/// マイページ: 保存した投稿。
final savedPostsProvider = FutureProvider<List<Post>>(
  (ref) => ref.watch(postRepositoryProvider).fetchSavedPosts(),
);
