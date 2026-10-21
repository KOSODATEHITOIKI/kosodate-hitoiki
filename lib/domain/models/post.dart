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

/// 投稿・コメントの編集に成功した結果(`PATCH`の200応答)。
class EditResult {
  const EditResult({this.editedAt, this.supportNotice = false});

  /// 本文が実際に変わったときだけ設定される(「編集済み」の表示に使う)。
  final DateTime? editedAt;

  /// 本人にだけ、相談先を案内する。編集は止めない。
  final bool supportNotice;
}

/// 投稿の作成に成功した結果(`POST /functions/v1/posts`の201応答)。
class CreatedPost {
  const CreatedPost({
    required this.id,
    required this.createdAt,
    this.supportNotice = false,
  });

  final String id;
  final DateTime createdAt;

  /// 本人にだけ、相談先を案内する(自分や子どもへの危害をほのめかす内容のとき)。
  /// 投稿は止めず、他の利用者には分からない(API契約3節・要件定義書6.2.1)。
  final bool supportNotice;
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
    this.commentsOpen = true,
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

  /// コメントの受付中か。「話を聞きたい」の投稿だけで意味を持つ(終了していれば、
  /// 既存のコメントは残り、新しいコメント・返信は送れない)。
  final bool commentsOpen;

  Post copyWith({bool? isSaved, ResponseMode? responseMode, String? body}) =>
      Post(
        id: id,
        authorId: authorId,
        authorName: authorName,
        authorAvatarAsset: authorAvatarAsset,
        createdAt: createdAt,
        type: type,
        responseMode: responseMode ?? this.responseMode,
        body: body ?? this.body,
        empathyCount: empathyCount,
        commentCount: commentCount,
        isMine: isMine,
        isSaved: isSaved ?? this.isSaved,
        commentsOpen: commentsOpen,
      );
}
