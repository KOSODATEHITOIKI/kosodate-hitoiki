import 'package:kosodate_hitoiki/domain/models/post.dart';
import 'package:kosodate_hitoiki/domain/repositories/post_repository.dart';

/// 投稿作成の呼び出しを記録し、決めた順に結果(成功・失敗)を返す偽のリポジトリ。
class ScriptedPostRepository implements PostRepository {
  ScriptedPostRepository(this.script, {this.sample = false});

  /// 呼び出しごとに1つ使う。[CreatedPost]なら成功、それ以外は投げる。
  final List<Object> script;
  final bool sample;
  final calls = <CreateCall>[];

  @override
  bool get isSample => sample;

  @override
  Future<CreatedPost> createPost({
    required PostType type,
    required ResponseMode responseMode,
    required String body,
    required String idempotencyKey,
    bool confirmed = false,
  }) async {
    calls.add(CreateCall(type, responseMode, body, idempotencyKey, confirmed));
    final next = script.removeAt(0);
    if (next is CreatedPost) return next;
    throw next;
  }

  @override
  Future<List<Post>> fetchFeed() async => const [];

  @override
  Future<List<Post>> search({required String query, PostType? type}) async =>
      const [];

  @override
  Future<List<Post>> fetchMyPosts() async => const [];

  @override
  Future<List<Post>> fetchSavedPosts() async => const [];

  @override
  Future<void> toggleSaved(String postId) async {}
}

class CreateCall {
  CreateCall(this.type, this.responseMode, this.body, this.key, this.confirmed);
  final PostType type;
  final ResponseMode responseMode;
  final String body;
  final String key;
  final bool confirmed;
}

CreatedPost created({bool supportNotice = false}) => CreatedPost(
  id: 'p-new',
  createdAt: DateTime(2026, 10, 21, 9),
  supportNotice: supportNotice,
);
