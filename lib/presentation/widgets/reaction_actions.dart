import 'package:flutter/material.dart';
import '../../core/widgets/centered_page_transitions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../pages/auth/auth_page.dart';
import '../providers/auth_provider.dart';
import '../providers/reaction_providers.dart';

/// 共感する・取り消す。ゲストは、ログインへ案内する。失敗したときは、案内を出す
/// (表示は、元に戻る)。[reactionTypeId]が`null`なら取り消し。
Future<void> changeReaction(
  BuildContext context,
  WidgetRef ref, {
  required String postId,
  int? reactionTypeId,
}) async {
  if (!ref.read(isLoggedInProvider)) {
    pushFullWidth<void>(context, builder: (_) => const AuthPage());
    return;
  }
  final messenger = ScaffoldMessenger.of(context);
  final notifier = ref.read(myReactionsProvider.notifier);
  final failure = reactionTypeId == null
      ? await notifier.clear(postId)
      : await notifier.select(postId, reactionTypeId);
  if (failure != null) {
    messenger.showSnackBar(SnackBar(content: Text(failure)));
  }
}
