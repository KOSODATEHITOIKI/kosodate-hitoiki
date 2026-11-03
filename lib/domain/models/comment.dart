/// コメント・返信(F-03)。返信は1段階のみで、親コメントの下に表示する。
class Comment {
  const Comment({
    required this.id,
    required this.authorId,
    required this.authorName,
    required this.authorAvatarAsset,
    required this.createdAt,
    this.parentId,
    this.body,
    this.isDeleted = false,
    this.isEdited = false,
    this.isMine = false,
  });

  final String id;
  final String authorId;
  final String authorName;
  final String authorAvatarAsset;
  final DateTime createdAt;

  /// 返信なら、親コメントのID。
  final String? parentId;

  /// 削除済みのコメントは、本文がnull(「削除済み」と表示する)。
  final String? body;
  final bool isDeleted;

  /// 編集済み(「編集済み」と表示する)。
  final bool isEdited;
  final bool isMine;

  bool get isReply => parentId != null;

  Comment copyWith({
    String? body,
    bool? isEdited,
    bool? isDeleted,
    bool clearBody = false,
  }) => Comment(
    id: id,
    authorId: authorId,
    authorName: authorName,
    authorAvatarAsset: authorAvatarAsset,
    createdAt: createdAt,
    parentId: parentId,
    body: clearBody ? null : (body ?? this.body),
    isDeleted: isDeleted ?? this.isDeleted,
    isEdited: isEdited ?? this.isEdited,
    isMine: isMine,
  );
}

/// コメント作成に成功した結果(`POST /functions/v1/comments`の201応答)。
class CreatedComment {
  const CreatedComment({
    required this.id,
    required this.createdAt,
    this.supportNotice = false,
  });

  final String id;
  final DateTime createdAt;

  /// 本人にだけ、相談先を案内する。コメントは止めない。
  final bool supportNotice;
}
