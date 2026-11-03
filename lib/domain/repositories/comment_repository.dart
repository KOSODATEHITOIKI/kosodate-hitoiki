import '../models/comment.dart';
import '../models/post.dart' show EditResult;

/// コメント・返信の取得と作成の抽象。バックエンド接続時はSupabase実装に差し替える。
abstract class CommentRepository {
  /// サンプルデータか。trueの間、画面に「サンプルコメントです」の注記を出す。
  bool get isSample;

  /// 投稿のコメント・返信(古い順)。ログイン必須。
  Future<List<Comment>> fetchComments(String postId);

  /// コメント・返信を作る。送信前チェックはサーバー側で行われ、確認が必要なとき・送信不可の
  /// ときは`ApiException`で失敗する。確認後は[confirmed]をtrueにして、同じ
  /// [idempotencyKey]で再送する。[parentId]は、返信のときの親コメントのID。
  Future<CreatedComment> createComment({
    required String postId,
    required String body,
    required String idempotencyKey,
    String? parentId,
    bool confirmed = false,
  });

  /// コメント・返信の本文を編集する(本人のみ。受付終了後も可)。送信前チェックを通る。
  Future<EditResult> editComment({
    required String commentId,
    required String body,
    bool confirmed = false,
  });

  /// コメント・返信を削除する(本人のみ)。本文は消えて「削除済み」になり、返信は残る。
  Future<void> deleteComment(String commentId);
}
