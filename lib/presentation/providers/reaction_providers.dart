import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/api/api_exception.dart';
import '../../domain/models/reaction_type.dart';
import '../../domain/repositories/post_repository.dart';
import '../pages/compose/post_messages.dart';
import 'post_providers.dart';

/// 共感の定型文(運営が用意した少数の種類。未ログインでも読める)。
final reactionTypesProvider = FutureProvider<List<ReactionType>>(
  (ref) => ref.watch(postRepositoryProvider).fetchReactionTypes(),
);

/// 自分の共感(投稿ID→定型文のID)。利用者が変わると、リポジトリごと作り直される
/// (lib/app.dartが`postRepositoryProvider`を作り直す)ので、前の利用者の共感は残らない。
final myReactionsProvider =
    StateNotifierProvider<MyReactionsNotifier, Map<String, int>>(
      (ref) => MyReactionsNotifier(ref.watch(postRepositoryProvider)),
    );

/// 自分の投稿への共感の件数(投稿者本人だけが取得できる)。
final reactionCountProvider = FutureProvider.autoDispose.family<int, String>(
  (ref, postId) => ref.watch(postRepositoryProvider).fetchReactionCount(postId),
);

/// 自分の共感。画面にはすぐ反映し、サーバーへ送る。送れなかったときは、元に戻す。
class MyReactionsNotifier extends StateNotifier<Map<String, int>> {
  MyReactionsNotifier(this._repository) : super(const {});

  final PostRepository _repository;

  /// すでに取得を依頼した投稿(同じ投稿を、何度も取得しない)。
  final _requested = <String>{};

  /// まとめて取得するための、取得待ちの投稿。
  final _queue = <String>{};
  bool _flushScheduled = false;

  /// 送信中の投稿(同じ投稿への操作を、続けて送らない)。
  final _pending = <String>{};

  /// 表示する投稿への、自分の共感を取得する。同じ画面で表示する投稿の分は、1回にまとめて
  /// 取得し、一度取得した投稿は取得し直さない(共感の操作は、状態へ直接反映される)。
  void request(String postId) {
    if (!_requested.add(postId)) return;
    _queue.add(postId);
    if (_flushScheduled) return;
    _flushScheduled = true;
    Future<void>.microtask(_flush);
  }

  Future<void> _flush() async {
    _flushScheduled = false;
    final ids = _queue.toList();
    _queue.clear();
    if (ids.isEmpty) return;
    try {
      final loaded = await _repository.fetchMyReactions(ids);
      // 読み込み中に操作した分は、操作を優先する。
      if (mounted) state = {...loaded, ...state};
    } catch (_) {
      // 読めなくても、操作はできる(選択の表示だけが出ない)。次に表示したとき、取得し直す。
      _requested.removeAll(ids);
    }
  }

  /// 共感する(選び直しも同じ)。成功は`null`、失敗は利用者向けの文言。
  Future<String?> select(String postId, int reactionTypeId) =>
      _change(postId, reactionTypeId);

  /// 共感を取り消す。成功は`null`、失敗は利用者向けの文言。
  Future<String?> clear(String postId) => _change(postId, null);

  Future<String?> _change(String postId, int? reactionTypeId) async {
    if (!_pending.add(postId)) return null;
    final previous = state[postId];
    _apply(postId, reactionTypeId);
    try {
      if (reactionTypeId == null) {
        await _repository.removeReaction(postId);
      } else {
        await _repository.setReaction(
          postId: postId,
          reactionTypeId: reactionTypeId,
        );
      }
      return null;
    } catch (error) {
      if (mounted) _apply(postId, previous);
      return reactionFailureMessage(error);
    } finally {
      _pending.remove(postId);
    }
  }

  void _apply(String postId, int? reactionTypeId) {
    final next = {...state};
    if (reactionTypeId == null) {
      next.remove(postId);
    } else {
      next[postId] = reactionTypeId;
    }
    state = next;
  }
}

/// 共感の送信・取消が失敗したときの、利用者向けの文言。
String reactionFailureMessage(Object error) {
  if (error is ApiException) {
    if (error.details['reason'] == 'not_owner') {
      return '自分の投稿には、共感できません。';
    }
    if (error.code == 'VALIDATION_FAILED') {
      return 'この定型文は、いまは選べません。';
    }
  }
  return postFailureMessage(error);
}
