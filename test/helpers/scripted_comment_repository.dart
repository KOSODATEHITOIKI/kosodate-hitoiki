import 'package:kosodate_hitoiki/domain/models/comment.dart';
import 'package:kosodate_hitoiki/domain/models/post.dart' show EditResult;
import 'package:kosodate_hitoiki/domain/repositories/comment_repository.dart';

/// コメント取得の結果を固定し、作成・編集・削除の呼び出しを記録して、決めた順に結果を返す偽のリポジトリ。
class ScriptedCommentRepository implements CommentRepository {
  ScriptedCommentRepository({
    this.comments = const [],
    List<Object>? script,
    List<Object>? editScript,
    this.deleteError,
  }) : script = script ?? [],
       editScript = editScript ?? [];

  final List<Comment> comments;

  /// 作成の呼び出しごとに1つ使う。[CreatedComment]なら成功、`Future Function()`なら
  /// その結果を待つ、それ以外は投げる。
  final List<Object> script;
  final calls = <CommentCall>[];

  /// 編集の呼び出しごとに1つ使う。[EditResult]なら成功、それ以外は投げる。
  final List<Object> editScript;
  final editCalls = <({String id, String body, bool confirmed})>[];

  /// 削除で投げるエラー(nullなら成功)。
  final Object? deleteError;
  final deleteCalls = <String>[];

  @override
  bool get isSample => false;

  @override
  Future<List<Comment>> fetchComments(String postId) async => comments;

  @override
  Future<CreatedComment> createComment({
    required String postId,
    required String body,
    required String idempotencyKey,
    String? parentId,
    bool confirmed = false,
  }) async {
    calls.add(CommentCall(postId, body, idempotencyKey, parentId, confirmed));
    final next = script.removeAt(0);
    if (next is CreatedComment) return next;
    if (next is Future<CreatedComment> Function()) return next();
    throw next;
  }

  @override
  Future<EditResult> editComment({
    required String commentId,
    required String body,
    bool confirmed = false,
  }) async {
    editCalls.add((id: commentId, body: body, confirmed: confirmed));
    final next = editScript.removeAt(0);
    if (next is EditResult) return next;
    throw next;
  }

  @override
  Future<void> deleteComment(String commentId) async {
    deleteCalls.add(commentId);
    if (deleteError != null) throw deleteError!;
  }
}

class CommentCall {
  CommentCall(this.postId, this.body, this.key, this.parentId, this.confirmed);
  final String postId;
  final String body;
  final String key;
  final String? parentId;
  final bool confirmed;
}

CreatedComment createdComment({bool supportNotice = false}) => CreatedComment(
  id: 'c-new',
  createdAt: DateTime(2026, 10, 21, 9),
  supportNotice: supportNotice,
);

Comment comment(
  String id,
  String name,
  String? body, {
  String? parentId,
  bool isDeleted = false,
  bool isEdited = false,
  bool isMine = false,
}) => Comment(
  id: id,
  authorId: 'u-$id',
  authorName: name,
  authorAvatarAsset: 'assets/avatars/avatar-default-sprout.png',
  createdAt: DateTime(2026, 10, 21, 8),
  parentId: parentId,
  body: body,
  isDeleted: isDeleted,
  isEdited: isEdited,
  isMine: isMine,
);
