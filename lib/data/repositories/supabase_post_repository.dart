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
/// 段2 = 一覧・検索、段3 = 投稿の作成・編集・削除、段4 = 保存・非表示・ブロック、段6 = 自分の投稿(ここ)。
/// 共感・定型文は、定型文のマスタが未決定のため未接続。自分の投稿の一覧は段6。
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
    final saved = await _savedIds([
      for (final row in rows) (row as Map)['id'] as String,
    ]);
    return [
      for (final row in rows)
        postFromRow(
          (row as Map).cast<String, dynamic>(),
          myUserId: myId,
          isSaved: saved.contains(row['id']),
        ),
    ];
  }

  /// [postIds]のうち、自分が保存しているもの(RLSにより、自分の保存だけが見える)。
  /// 未ログインは保存を持たない。
  Future<Set<String>> _savedIds(List<String> postIds) async {
    if (_client.auth.currentUser == null || postIds.isEmpty) return const {};
    final rows = await _client
        .from('saved_posts')
        .select('post_id')
        .inFilter('post_id', postIds);
    return {for (final row in rows) row['post_id'] as String};
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

  /// 投稿の本文の編集(`PATCH /functions/v1/posts/{id}`)。
  @override
  Future<EditResult> editPost({
    required String postId,
    required String body,
    bool confirmed = false,
  }) async {
    try {
      final response = await _client.functions.invoke(
        'posts/$postId',
        method: HttpMethod.patch,
        body: {'body': body.trim(), if (confirmed) 'confirmed': true},
      );
      return editResultFromResponse(response.data);
    } on FunctionException catch (error) {
      throw ApiException.fromFunction(error);
    }
  }

  /// 投稿の削除(`DELETE /functions/v1/posts/{id}`)。
  @override
  Future<void> deletePost(String postId) async {
    try {
      await _client.functions.invoke(
        'posts/$postId',
        method: HttpMethod.delete,
      );
    } on FunctionException catch (error) {
      throw ApiException.fromFunction(error);
    }
  }

  /// 編集APIの応答(`{ id, edited_at, support_notice }`)。
  static EditResult editResultFromResponse(Object? data) {
    final map = data is Map ? data.cast<String, dynamic>() : const {};
    final editedAt = map['edited_at'] as String?;
    return EditResult(
      editedAt: editedAt == null ? null : DateTime.parse(editedAt).toLocal(),
      supportNotice: map['support_notice'] == true,
    );
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
  /// 自分の投稿(新しい順)。通報による一時非表示で運営が確認中の投稿も含み、
  /// `under_review`が`true`のものは「確認中」と表示する(本人にだけ見える。API契約7節)。
  @override
  Future<List<Post>> fetchMyPosts() async {
    final myId = _client.auth.currentUser?.id;
    if (myId == null) return const [];
    final rows = await _client
        .from('my_posts')
        .select()
        .order('created_at', ascending: false)
        .limit(pageSize);
    final me = await _client
        .from('public_profiles')
        .select('nickname,icon_key')
        .eq('id', myId)
        .maybeSingle();
    final saved = await _savedIds([
      for (final row in rows) row['id'] as String,
    ]);
    return [
      for (final row in rows)
        myPostFromRow(
          row,
          myUserId: myId,
          nickname: me?['nickname'] as String? ?? '',
          iconKey: me?['icon_key'] as String?,
          isSaved: saved.contains(row['id']),
        ),
    ];
  }

  /// `my_posts`の行を投稿にする。投稿者は自分なので、ニックネーム・アイコンは別に渡す。
  static Post myPostFromRow(
    Map<String, dynamic> row, {
    required String myUserId,
    required String nickname,
    String? iconKey,
    bool isSaved = false,
  }) => postFromRow(
    {
      ...row,
      'author_id': myUserId,
      'author_nickname': nickname,
      'author_icon_key': iconKey,
    },
    myUserId: myUserId,
    isSaved: isSaved,
    underReview: row['under_review'] == true,
  );

  /// 保存した投稿(新しく保存した順)。見えなくなった投稿(削除・一時非表示・ブロックなど)は
  /// 出ない(保存自体は残る)。ログイン必須。
  @override
  Future<List<Post>> fetchSavedPosts() async {
    final rows = await _client
        .from('saved_post_list')
        .select()
        .order('saved_at', ascending: false)
        .limit(pageSize);
    final myId = _client.auth.currentUser?.id;
    return [
      for (final row in rows) postFromRow(row, myUserId: myId, isSaved: true),
    ];
  }

  /// 保存の切り替え。いまの保存の有無を調べて、あれば解除、なければ保存する。
  /// 見えない投稿・存在しない投稿は保存できない(どちらも`42501`)。
  @override
  Future<void> toggleSaved(String postId) async {
    final existing = await _client
        .from('saved_posts')
        .select('post_id')
        .eq('post_id', postId)
        .limit(1);
    if (existing.isNotEmpty) {
      await _client.from('saved_posts').delete().eq('post_id', postId);
      return;
    }
    await _insertIgnoringDuplicate('saved_posts', {'post_id': postId});
  }

  @override
  Future<void> hidePost(String postId) => _insertIgnoringDuplicate(
    'hidden_items',
    {'target_type': 'post', 'target_id': postId},
  );

  @override
  Future<void> blockUser(String userId) =>
      _insertIgnoringDuplicate('blocks', {'blocked_id': userId});

  /// 追加する。すでにある(一意制約違反)ときは、何もしない(重ねても成功)。
  Future<void> _insertIgnoringDuplicate(
    String table,
    Map<String, dynamic> row,
  ) async {
    try {
      await _client.from(table).insert(row);
    } on PostgrestException catch (error) {
      if (!isDuplicate(error)) rethrow;
    }
  }

  /// PostgRESTの一意制約違反(`23505`、HTTP 409)か。
  static bool isDuplicate(PostgrestException error) =>
      error.code == '23505' || error.code == '409';

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
  /// 保存の有無は[isSaved]で渡す(自分の保存を別に調べる)。
  static Post postFromRow(
    Map<String, dynamic> row, {
    String? myUserId,
    bool isSaved = false,
    bool underReview = false,
  }) {
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
      isSaved: isSaved,
      underReview: underReview,
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
