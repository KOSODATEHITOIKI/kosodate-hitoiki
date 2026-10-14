/// 投稿の種類(F-01、docs/全体設計書.md参照)。
enum PostType {
  grumble('ぐち'),
  consult('相談'),
  tips('コツ・体験談');

  const PostType(this.label);
  final String label;
}

/// 反応モード(F-04)。「ただ聞いてほしい」は共感・定型文のみ、
/// 「話を聞きたい」は自由コメントを受け付ける。
enum ResponseMode {
  listening('ただ聞いてほしい'),
  advice('話を聞きたい');

  const ResponseMode(this.label);
  final String label;
}

/// 投稿(F-01)。バックエンド未接続の間はMockPostRepositoryが返す。
class Post {
  const Post({
    required this.id,
    required this.authorId,
    required this.authorName,
    required this.authorAvatarAsset,
    required this.createdAt,
    required this.type,
    required this.responseMode,
    required this.body,
    required this.empathyCount,
    required this.commentCount,
    this.isMine = false,
    this.isSaved = false,
  });

  final String id;
  final String authorId;
  final String authorName;
  final String authorAvatarAsset;
  final DateTime createdAt;
  final PostType type;
  final ResponseMode responseMode;
  final String body;
  final int empathyCount;
  final int commentCount;
  final bool isMine;
  final bool isSaved;

  Post copyWith({bool? isSaved, ResponseMode? responseMode}) => Post(
    id: id,
    authorId: authorId,
    authorName: authorName,
    authorAvatarAsset: authorAvatarAsset,
    createdAt: createdAt,
    type: type,
    responseMode: responseMode ?? this.responseMode,
    body: body,
    empathyCount: empathyCount,
    commentCount: commentCount,
    isMine: isMine,
    isSaved: isSaved ?? this.isSaved,
  );
}
