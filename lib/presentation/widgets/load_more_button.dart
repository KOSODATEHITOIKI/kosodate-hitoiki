import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/post.dart';
import '../providers/post_providers.dart';

/// 一覧の終わりの「もっと見る」。次のページがあるときだけ出す。読み込み中は押せず、
/// 失敗したときは、いま出ている投稿を残したまま、もう一度押せる。
class LoadMoreButton extends ConsumerWidget {
  const LoadMoreButton({super.key, required this.provider});

  final AsyncNotifierProvider<PagedPosts, List<Post>> provider;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 状態が変わるたびに作り直す(読み込み中・失敗の表示を更新する)。
    ref.watch(provider);
    final notifier = ref.read(provider.notifier);
    if (!notifier.hasMore) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        children: [
          if (notifier.loadMoreFailed)
            const Padding(
              padding: EdgeInsets.only(bottom: 8),
              child: Text(
                '続きを読み込めませんでした。',
                key: ValueKey('load-more-failed'),
                style: TextStyle(fontSize: 13),
              ),
            ),
          OutlinedButton(
            key: const ValueKey('load-more'),
            onPressed: notifier.isLoadingMore ? null : notifier.loadMore,
            child: Text(notifier.isLoadingMore ? '読み込んでいます…' : 'もっと見る'),
          ),
        ],
      ),
    );
  }
}
