import '../models/blocked_user.dart';
import '../models/post.dart';
import '../models/reaction_type.dart';
import '../models/topic.dart';

/// 投稿データ取得の抽象。バックエンド接続時はSupabase実装に差し替える
/// (現在はMockPostRepositoryのみ。docs/全体設計書.md F-01〜F-09参照)。
abstract class PostRepository {
  /// サンプルデータか。trueの間、画面に「サンプル投稿です」の注記を出す。
  bool get isSample;

  /// 投稿の話題(並び順どおり。未ログインでも読める)。
  Future<List<Topic>> fetchTopics();

  /// ホームの投稿一覧(新着順)。[topicId]を指定すると、その話題の投稿だけ。
  /// [before]を指定すると、その投稿より古い投稿(次のページ)。
  Future<List<Post>> fetchFeed({int? topicId, Post? before});

  /// キーワード・投稿種類・話題で絞り込んだ検索結果。[before]を指定すると、その投稿より
  /// 古い結果(次のページ)。1ページの件数は[pageSize]。
  Future<List<Post>> search({
    required String query,
    PostType? type,
    int? topicId,
    Post? before,
  });

  /// 1ページの件数。返ってきた件数がこれ未満なら、最後のページ。
  static const pageSize = 30;

  /// 投稿1件(ID指定)。見えない投稿(削除・一時非表示・ブロックなど)や、存在しない投稿は
  /// `null`(どちらも同じ。存在を知る手がかりにしない)。ログイン必須。
  Future<Post?> fetchPost(String postId);

  /// 自分が投稿したもの。
  /// [offset]は、すでに読み込んだ件数(次のページを取得する)。1ページの件数は[pageSize]。
  Future<List<Post>> fetchMyPosts({int offset = 0});

  /// 自分が保存したもの。
  Future<List<Post>> fetchSavedPosts({int offset = 0});

  /// 投稿を作る。送信前チェックはサーバー側で行われ、確認が必要なとき・送信不可のときは
  /// `ApiException`(`isConfirmRequired`・`isRejected`)で失敗する。確認後は[confirmed]を
  /// trueにして再送する。[idempotencyKey]は、同じ送信の再送では同じ値にする。
  Future<CreatedPost> createPost({
    required PostType type,
    required ResponseMode responseMode,
    required String body,
    required String idempotencyKey,
    int? topicId,
    bool confirmed = false,
  });

  /// 投稿の本文を編集する(本人のみ。種類・反応モードは変えられない)。送信前チェックは
  /// 作成と同じで、確認が必要なときは[confirmed]をtrueにして再送する。
  Future<EditResult> editPost({
    required String postId,
    required String body,
    bool confirmed = false,
  });

  /// 投稿を削除する(本人のみ)。コメント・返信・共感・保存・通知も一緒に消える。
  Future<void> deletePost(String postId);

  /// 反応モード・コメント受付状態を変える(本人のみ)。[mode]は変更後の(受付状態だけ
  /// 変えるときは、今の)反応モードで、サーバーは常に必要とする。「ただ聞いてほしい」⇄
  /// 「話を聞きたい」の相互変更ができる。[commentsOpen]は「話を聞きたい」のときだけ
  /// 指定でき(省略すると今の状態を保つ。「話を聞きたい」へ変えた直後は受付中)、
  /// 「ただ聞いてほしい」には指定できない(`ApiException`)。
  Future<void> updateReactionMode({
    required String postId,
    required ResponseMode mode,
    bool? commentsOpen,
  });

  /// 投稿を、自分の画面にだけ表示しないようにする(非表示)。相手には知らせない。
  /// 同じ投稿を重ねて非表示にしても、エラーにならない。
  Future<void> hidePost(String postId);

  /// 投稿者をブロックする。相手の投稿・コメントが自分に表示されなくなり、相手は自分への
  /// コメント・返信・共感ができなくなる。相手には知らせない。重ねても、エラーにならない。
  Future<void> blockUser(String userId);

  /// 共感の定型文(並び順どおり。未ログインでも読める)。
  Future<List<ReactionType>> fetchReactionTypes();

  /// 自分の共感(投稿ID→定型文のID)。未ログインは空。
  Future<Map<String, int>> fetchMyReactions();

  /// 共感する(登録・選び直しを1操作で扱う。1投稿1人1つ)。自分の投稿・ブロックされている
  /// 投稿・見えない投稿などは`ApiException`で失敗する。
  Future<void> setReaction({
    required String postId,
    required int reactionTypeId,
  });

  /// 共感を取り消す(していなくても、エラーにならない)。
  Future<void> removeReaction(String postId);

  /// 自分の投稿への共感の件数(投稿者本人だけが取得できる)。
  Future<int> fetchReactionCount(String postId);

  /// ブロック中の相手の一覧(新しくブロックした順。自分がブロックした相手だけ)。
  Future<List<BlockedUser>> fetchBlockedUsers();

  /// ブロックを解除する。相手には知らせない。ブロックしていない相手でも、エラーにならない。
  Future<void> unblockUser(String userId);

  /// 投稿の保存/保存解除を切り替える。
  Future<void> toggleSaved(String postId);
}
