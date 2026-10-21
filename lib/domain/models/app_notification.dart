/// 通知の種類(`notification_type`の値。バックエンド docs/API契約.md 8節)。
enum NotificationType {
  /// 自分の投稿へのコメント。
  comment('comment'),

  /// 自分のコメントへの返信。
  reply('reply'),

  /// 共感のまとめ(誰が共感したかは持たない)。
  reactionDigest('reaction_digest'),

  /// 運営からのお知らせ。止められない。
  moderation('moderation');

  const NotificationType(this.code);

  /// APIの値。
  final String code;

  static NotificationType fromCode(String? code) => values.firstWhere(
    (type) => type.code == code,
    orElse: () => NotificationType.moderation,
  );
}

/// お知らせ(F-08)。本文はサーバーが持たず、種類から定型文で表示する
/// (コメント・返信の本文や、共感した人は、お知らせに含めない)。
class AppNotification {
  const AppNotification({
    required this.id,
    required this.type,
    required this.createdAt,
    this.actorName,
    this.postId,
    this.commentId,
    this.reactionCount = 0,
    this.isRead = false,
  });

  final String id;
  final NotificationType type;
  final DateTime createdAt;

  /// 発生させた人のニックネーム(コメント・返信のとき)。分からなければnull。
  final String? actorName;
  final String? postId;
  final String? commentId;

  /// 共感のまとめの件数。
  final int reactionCount;
  final bool isRead;

  AppNotification copyWith({bool? isRead}) => AppNotification(
    id: id,
    type: type,
    createdAt: createdAt,
    actorName: actorName,
    postId: postId,
    commentId: commentId,
    reactionCount: reactionCount,
    isRead: isRead ?? this.isRead,
  );
}
