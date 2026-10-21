import '../models/comment.dart';

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
}
