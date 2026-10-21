import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/constants/app_icons.dart';
import '../api/api_exception.dart';
import '../../domain/models/post.dart';
import '../../domain/repositories/post_repository.dart';

/// 投稿の読み取り(新着一覧・検索)をSupabaseから取得する。
///
/// 未ログインでも使える`search_posts`を、一覧(語なし)にも検索にも使う。
/// 未ログインは公開投稿だけ(`author_id`はnull)、ログイン済みはブロック・
/// 非表示・ミュートが適用される(kosodate-hitoiki-backend docs/API契約.md 3・6節)。
///
/// 接続の段階(バックエンド docs/Flutter結合ガイド.md 2節):
/// 段2 = 一覧・検索、段3 = 投稿の作成(ここ)。自分の投稿・保存の一覧は段6、保存の切り替えは段4で接続する。
class SupabasePostRepository implements PostRepository {
  SupabasePostRepository(this._client);

  final SupabaseClient _client;

  /// 1回に取得する件数(API契約の上限は50)。ページ送りは未実装で、新着から
  /// この件数だけを表示する。
  static const pageSize = 30;

  @override
  bool get isSample => false;

  @override
  Future<List<Post>> fetchFeed() => search(query: '');

  @override
  Future<List<Post>> search({required String query, PostType? type}) async {
    final rows = await _client.rpc<List<dynamic>>(
      'search_posts',
      params: searchParams(query: query, type: type),
    );
    final myId = _client.auth.currentUser?.id;
    return [
      for (final row in rows)
        postFromRow((row as Map).cast<String, dynamic>(), myUserId: myId),
    ];
  }

  /// 投稿の作成(`POST /functions/v1/posts`)。送信前チェックもこのAPIの中で行われる。
  @override
  Future<CreatedPost> createPost({
    required PostType type,
    required ResponseMode responseMode,
    required String body,
    required String idempotencyKey,
    bool confirmed = false,
  }) async {
    try {
      final response = await _client.functions.invoke(
        'posts',
        headers: {'Idempotency-Key': idempotencyKey},
        body: createBody(
          type: type,
          responseMode: responseMode,
          body: body,
          confirmed: confirmed,
        ),
      );
      final data = (response.data as Map).cast<String, dynamic>();
      return CreatedPost(
        id: data['id'] as String,
        createdAt: DateTime.parse(data['created_at'] as String).toLocal(),
        supportNotice: data['support_notice'] == true,
      );
    } on FunctionException catch (error) {
      throw ApiException.fromFunction(error);
    }
  }

  /// 投稿作成APIのリクエスト本文。話題は、マスタが未決定のため送らない。
  static Map<String, dynamic> createBody({
    required PostType type,
    required ResponseMode responseMode,
    required String body,
    bool confirmed = false,
  }) => {
    'post_type': postTypeCode(type),
    'body': body.trim(),
    'reaction_mode': reactionModeCode(responseMode),
    if (confirmed) 'confirmed': true,
  };

  static String reactionModeCode(ResponseMode mode) => switch (mode) {
    ResponseMode.listening => 'quiet_support',
    ResponseMode.advice => 'want_comments',
  };

  // 自分の投稿・保存した投稿は、投稿の作成(段3)・保存(段4)・マイページ(段6)の
  // 接続まで、空を返す(サンプルを見せない)。
  @override
  Future<List<Post>> fetchMyPosts() async => const [];

  @override
  Future<List<Post>> fetchSavedPosts() async => const [];

  @override
  Future<void> toggleSaved(String postId) {
    throw StateError('保存の接続は未実装です(接続段4)');
  }

  /// `search_posts`の引数。空の検索語は渡さない(新着一覧になる)。
  static Map<String, dynamic> searchParams({
    required String query,
    PostType? type,
    int limit = pageSize,
  }) {
    final trimmed = query.trim();
    return {
      if (trimmed.isNotEmpty) 'p_query': trimmed,
      if (type != null) 'p_post_type': postTypeCode(type),
      'p_limit': limit,
    };
  }

  /// APIの行をアプリの投稿にする。
  ///
  /// 共感の件数は、投稿者本人にしか返らない仕様(別の段で取得)なので0にする。
  /// 保存の有無は段4で接続するため、いまはfalse。
  static Post postFromRow(Map<String, dynamic> row, {String? myUserId}) {
    final authorId = row['author_id'] as String?;
    return Post(
      id: row['id'] as String,
      authorId: authorId ?? '',
      authorName: row['author_nickname'] as String? ?? '',
      authorAvatarAsset: AppAvatars.forIconKey(
        row['author_icon_key'] as String?,
      ),
      createdAt: DateTime.parse(row['created_at'] as String).toLocal(),
      type: postTypeFromCode(row['post_type'] as String?),
      responseMode: responseModeFromCode(row['reaction_mode'] as String?),
      body: row['body'] as String? ?? '',
      empathyCount: 0,
      commentCount: (row['comment_count'] as num?)?.toInt() ?? 0,
      isMine: myUserId != null && authorId == myUserId,
      commentsOpen: row['comment_acceptance'] != 'closed',
    );
  }

  static PostType postTypeFromCode(String? code) => switch (code) {
    'soudan' => PostType.consult,
    'kotsu' => PostType.tips,
    _ => PostType.grumble,
  };

  static String postTypeCode(PostType type) => switch (type) {
    PostType.grumble => 'guchi',
    PostType.consult => 'soudan',
    PostType.tips => 'kotsu',
  };

  static ResponseMode responseModeFromCode(String? code) =>
      code == 'want_comments' ? ResponseMode.advice : ResponseMode.listening;
}
