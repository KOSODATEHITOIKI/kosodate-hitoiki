import 'package:kosodate_hitoiki/domain/models/blocked_user.dart';
import 'package:kosodate_hitoiki/domain/models/post.dart';
import 'package:kosodate_hitoiki/domain/models/reaction_type.dart';
import 'package:kosodate_hitoiki/domain/repositories/post_repository.dart';

/// 投稿の作成・編集・削除の呼び出しを記録し、決めた順に結果(成功・失敗)を返す偽のリポジトリ。
class ScriptedPostRepository implements PostRepository {
  ScriptedPostRepository(
    this.script, {
    this.sample = false,
    List<Object>? editScript,
    this.deleteError,
    this.actionError,
    this.modeError,
    List<BlockedUser>? blocked,
    this.blockedFetchErrors,
    this.unblockError,
    this.reactionTypes = const [
      ReactionType(id: 1, code: 'empathy', label: 'わかる'),
      ReactionType(id: 2, code: 'take_a_break', label: 'おつかれさま'),
      ReactionType(id: 3, code: 'listening', label: '聞いているよ'),
    ],
    Map<String, int>? myReactions,
    this.reactionError,
    this.reactionCounts = const {},
    this.myPosts = const [],
    this.savedPosts = const [],
  }) : editScript = editScript ?? [],
       blocked = blocked ?? [],
       myReactions = myReactions ?? {};

  /// マイページの「自分の投稿」「保存した投稿」に返す一覧。
  final List<Post> myPosts;
  final List<Post> savedPosts;

  /// 作成の呼び出しごとに1つ使う。[CreatedPost]なら成功、`Future Function()`なら
  /// その結果を待つ(送信中の状態を作る)、それ以外は投げる。
  final List<Object> script;
  final bool sample;
  final calls = <CreateCall>[];

  /// 編集の呼び出しごとに1つ使う。[EditResult]なら成功、それ以外は投げる。
  final List<Object> editScript;
  final editCalls = <EditCall>[];

  /// 削除で投げるエラー(nullなら成功)。
  final Object? deleteError;
  final deleteCalls = <String>[];

  /// 非表示・ブロック・保存の切り替えで投げるエラー(nullなら成功)。
  final Object? actionError;
  final hideCalls = <String>[];
  final blockCalls = <String>[];
  final saveCalls = <String>[];

  /// 反応モード・受付状態の変更で投げるエラー(nullなら成功)。
  final Object? modeError;
  final modeCalls =
      <({String postId, ResponseMode mode, bool? commentsOpen})>[];

  /// 共感の定型文・自分の共感(送ると変わる)・件数。
  final List<ReactionType> reactionTypes;
  final Map<String, int> myReactions;
  final Map<String, int> reactionCounts;

  /// 共感の送信・取消で投げるエラー(nullなら成功)。
  final Object? reactionError;
  final setReactionCalls = <({String postId, int typeId})>[];
  final removeReactionCalls = <String>[];

  @override
  Future<List<ReactionType>> fetchReactionTypes() async => reactionTypes;

  @override
  Future<Map<String, int>> fetchMyReactions() async => Map.of(myReactions);

  @override
  Future<void> setReaction({
    required String postId,
    required int reactionTypeId,
  }) async {
    setReactionCalls.add((postId: postId, typeId: reactionTypeId));
    if (reactionError != null) throw reactionError!;
    myReactions[postId] = reactionTypeId;
  }

  @override
  Future<void> removeReaction(String postId) async {
    removeReactionCalls.add(postId);
    if (reactionError != null) throw reactionError!;
    myReactions.remove(postId);
  }

  @override
  Future<int> fetchReactionCount(String postId) async =>
      reactionCounts[postId] ?? 0;

  /// ブロック中の相手(解除すると取り除く)。
  final List<BlockedUser> blocked;

  /// 取得の呼び出しごとに1つ使う(なくなったら成功)。投げる。
  final List<Object>? blockedFetchErrors;
  var blockedFetchCount = 0;

  /// 解除で投げるエラー(nullなら成功)。
  final Object? unblockError;
  final unblockCalls = <String>[];

  @override
  Future<List<BlockedUser>> fetchBlockedUsers() async {
    blockedFetchCount++;
    final errors = blockedFetchErrors;
    if (errors != null && errors.isNotEmpty) throw errors.removeAt(0);
    return List.of(blocked);
  }

  @override
  Future<void> unblockUser(String userId) async {
    unblockCalls.add(userId);
    if (unblockError != null) throw unblockError!;
    blocked.removeWhere((user) => user.id == userId);
  }

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
    if (next is Future<CreatedPost> Function()) return next();
    throw next;
  }

  @override
  Future<EditResult> editPost({
    required String postId,
    required String body,
    bool confirmed = false,
  }) async {
    editCalls.add(EditCall(postId, body, confirmed));
    final next = editScript.removeAt(0);
    if (next is EditResult) return next;
    throw next;
  }

  @override
  Future<void> deletePost(String postId) async {
    deleteCalls.add(postId);
    if (deleteError != null) throw deleteError!;
  }

  @override
  Future<List<Post>> fetchFeed() async => const [];

  @override
  Future<List<Post>> search({required String query, PostType? type}) async =>
      const [];

  /// ID指定の取得で返す投稿(なければnull)。
  final fetchedPosts = <String, Post>{};

  @override
  Future<Post?> fetchPost(String postId) async => fetchedPosts[postId];

  @override
  Future<List<Post>> fetchMyPosts() async => myPosts;

  @override
  Future<List<Post>> fetchSavedPosts() async => savedPosts;

  @override
  Future<void> updateReactionMode({
    required String postId,
    required ResponseMode mode,
    bool? commentsOpen,
  }) async {
    modeCalls.add((postId: postId, mode: mode, commentsOpen: commentsOpen));
    if (modeError != null) throw modeError!;
  }

  @override
  Future<void> hidePost(String postId) async {
    hideCalls.add(postId);
    if (actionError != null) throw actionError!;
  }

  @override
  Future<void> blockUser(String userId) async {
    blockCalls.add(userId);
    if (actionError != null) throw actionError!;
  }

  @override
  Future<void> toggleSaved(String postId) async {
    saveCalls.add(postId);
    if (actionError != null) throw actionError!;
  }
}

class EditCall {
  EditCall(this.postId, this.body, this.confirmed);
  final String postId;
  final String body;
  final bool confirmed;
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
