import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/constants/app_icons.dart';
import '../../domain/models/comment.dart';
import '../../domain/repositories/comment_repository.dart';
import '../api/api_exception.dart';

/// コメント・返信の取得(`member_comments`)と作成(`POST /functions/v1/comments`)。
/// 一覧はログイン必須。ブロック・非表示・一時非表示は、サーバー側のビューが除外する
/// (kosodate-hitoiki-backend docs/API契約.md 4・6節)。
class SupabaseCommentRepository implements CommentRepository {
  SupabaseCommentRepository(this._client);

  final SupabaseClient _client;

  static const _columns =
      'id,author_id,parent_comment_id,body,is_deleted,created_at,edited_at,'
      'author_nickname,author_icon_key,author_avatar_path';

  @override
  bool get isSample => false;

  @override
  Future<List<Comment>> fetchComments(String postId) async {
    final rows = await _client
        .from('member_comments')
        .select(_columns)
        .eq('post_id', postId)
        .order('created_at', ascending: true);
    final myId = _client.auth.currentUser?.id;
    return [for (final row in rows) commentFromRow(row, myUserId: myId)];
  }

  @override
  Future<CreatedComment> createComment({
    required String postId,
    required String body,
    required String idempotencyKey,
    String? parentId,
    bool confirmed = false,
  }) async {
    try {
      final response = await _client.functions.invoke(
        'comments',
        headers: {'Idempotency-Key': idempotencyKey},
        body: createBody(
          postId: postId,
          body: body,
          parentId: parentId,
          confirmed: confirmed,
        ),
      );
      final data = (response.data as Map).cast<String, dynamic>();
      return CreatedComment(
        id: data['id'] as String,
        createdAt: DateTime.parse(data['created_at'] as String).toLocal(),
        supportNotice: data['support_notice'] == true,
      );
    } on FunctionException catch (error) {
      throw ApiException.fromFunction(error);
    }
  }

  /// コメント作成APIのリクエスト本文。
  static Map<String, dynamic> createBody({
    required String postId,
    required String body,
    String? parentId,
    bool confirmed = false,
  }) => {
    'post_id': postId,
    'parent_comment_id': parentId,
    'body': body.trim(),
    if (confirmed) 'confirmed': true,
  };

  /// APIの行をアプリのコメントにする。削除済み(`is_deleted`)は本文がnull。
  static Comment commentFromRow(Map<String, dynamic> row, {String? myUserId}) {
    final authorId = row['author_id'] as String?;
    return Comment(
      id: row['id'] as String,
      authorId: authorId ?? '',
      authorName: row['author_nickname'] as String? ?? '',
      authorAvatarAsset: AppAvatars.forIconKey(
        row['author_icon_key'] as String?,
      ),
      createdAt: DateTime.parse(row['created_at'] as String).toLocal(),
      parentId: row['parent_comment_id'] as String?,
      body: row['body'] as String?,
      isDeleted: row['is_deleted'] == true,
      isEdited: row['edited_at'] != null,
      isMine: myUserId != null && authorId == myUserId,
    );
  }
}
