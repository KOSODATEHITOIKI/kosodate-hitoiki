import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/mock/mock_comment_repository.dart';
import '../../domain/models/comment.dart';
import '../../domain/repositories/comment_repository.dart';

/// コメントの取得先。バックエンド接続時は、main_dev/prodでSupabase実装に差し替える。
/// 利用者が変わったときは、lib/app.dartが作り直す。
final commentRepositoryProvider = Provider<CommentRepository>(
  (ref) => MockCommentRepository(),
);

/// 画面にサンプルコメントの注記を出すか。
final commentsAreSampleProvider = Provider<bool>(
  (ref) => ref.watch(commentRepositoryProvider).isSample,
);

/// 投稿ごとのコメント・返信(古い順)。
final commentsProvider = FutureProvider.family<List<Comment>, String>(
  (ref, postId) => ref.watch(commentRepositoryProvider).fetchComments(postId),
);
