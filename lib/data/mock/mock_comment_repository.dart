import '../../core/constants/app_icons.dart';
import '../../domain/models/comment.dart';
import '../../domain/repositories/comment_repository.dart';

/// 画面確認・テスト用のモック実装。投稿`p2`にだけ、サンプルのコメントがある。
class MockCommentRepository implements CommentRepository {
  MockCommentRepository() {
    _byPost['p2'] = [
      Comment(
        id: 'sample-c1',
        authorId: 'sample-komorebi',
        authorName: 'こもれび',
        authorAvatarAsset: AppAvatars.defaultSprout,
        createdAt: DateTime(2026, 10, 20, 9),
        body: 'うちの場合は、小さなおにぎりにしたら食べやすかったです。',
      ),
      Comment(
        id: 'sample-r1',
        authorId: 'sample-hana',
        authorName: 'はな',
        authorAvatarAsset: AppAvatars.defaultTulip,
        createdAt: DateTime(2026, 10, 20, 9, 30),
        parentId: 'sample-c1',
        body: 'ありがとう、試してみます。',
      ),
      Comment(
        id: 'sample-c2',
        authorId: 'sample-mimi',
        authorName: 'みみ',
        authorAvatarAsset: AppAvatars.defaultLittleBird,
        createdAt: DateTime(2026, 10, 20, 10),
        body: 'うちも食べない日があります。無理せず、少しずつで大丈夫。',
      ),
    ];
  }

  final _byPost = <String, List<Comment>>{};

  @override
  bool get isSample => true;

  @override
  Future<List<Comment>> fetchComments(String postId) async =>
      List.of(_byPost[postId] ?? const []);

  @override
  Future<CreatedComment> createComment({
    required String postId,
    required String body,
    required String idempotencyKey,
    String? parentId,
    bool confirmed = false,
  }) async {
    final now = DateTime.now();
    final id = 'mine-c${now.microsecondsSinceEpoch}';
    (_byPost[postId] ??= []).add(
      Comment(
        id: id,
        authorId: 'sample-me',
        authorName: 'あなた',
        authorAvatarAsset: AppAvatars.defaultSprout,
        createdAt: now,
        parentId: parentId,
        body: body.trim(),
        isMine: true,
      ),
    );
    return CreatedComment(id: id, createdAt: now);
  }
}
