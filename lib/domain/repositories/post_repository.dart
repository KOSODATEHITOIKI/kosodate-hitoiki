import '../models/post.dart';

/// 投稿データ取得の抽象。バックエンド接続時はSupabase実装に差し替える
/// (現在はMockPostRepositoryのみ。docs/全体設計書.md F-01〜F-09参照)。
abstract class PostRepository {
  /// サンプルデータか。trueの間、画面に「サンプル投稿です」の注記を出す。
  bool get isSample;

  /// ホームの投稿一覧(新着順)。
  Future<List<Post>> fetchFeed();

  /// キーワード・投稿種類で絞り込んだ検索結果。
  Future<List<Post>> search({required String query, PostType? type});

  /// 自分が投稿したもの。
  Future<List<Post>> fetchMyPosts();

  /// 自分が保存したもの。
  Future<List<Post>> fetchSavedPosts();

  /// 投稿を作る。送信前チェックはサーバー側で行われ、確認が必要なとき・送信不可のときは
  /// `ApiException`(`isConfirmRequired`・`isRejected`)で失敗する。確認後は[confirmed]を
  /// trueにして再送する。[idempotencyKey]は、同じ送信の再送では同じ値にする。
  Future<CreatedPost> createPost({
    required PostType type,
    required ResponseMode responseMode,
    required String body,
    required String idempotencyKey,
    bool confirmed = false,
  });

  /// 投稿の保存/保存解除を切り替える。
  Future<void> toggleSaved(String postId);
}
