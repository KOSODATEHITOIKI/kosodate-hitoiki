import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_icons.dart';
import '../../domain/models/post.dart';
import '../providers/post_providers.dart';
import 'comfort_page.dart';
import 'load_more_button.dart';
import 'post_card.dart';

/// API未接続の画面確認用一覧。実際の投稿と区別して表示する。
class MockPostList extends ConsumerWidget {
  const MockPostList({
    super.key,
    required this.posts,
    required this.emptyAsset,
    required this.emptyTitle,
    required this.onRetry,
    this.pagedProvider,
  });
  final AsyncValue<List<Post>> posts;

  /// ページ送りのある一覧のとき、その一覧。「もっと見る」を出す。
  final AsyncNotifierProvider<PagedPosts, List<Post>>? pagedProvider;
  final String emptyAsset;
  final String emptyTitle;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context, WidgetRef ref) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      if (ref.watch(postsAreSampleProvider)) ...[
        const Text(
          'サンプル投稿です。保存状態はアプリ終了時にリセットされます。',
          style: TextStyle(fontSize: 11, height: 1.6),
        ),
        const SizedBox(height: 12),
      ],
      posts.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => Column(
          children: [
            const ComfortNotice(
              asset: AppIllustrations.connectionRetry,
              title: '投稿を読み込めませんでした',
              message: 'もう一度お試しください。',
            ),
            TextButton(onPressed: onRetry, child: const Text('再読み込み')),
          ],
        ),
        data: (items) => items.isEmpty
            ? ComfortNotice(
                asset: emptyAsset,
                title: emptyTitle,
                message: '別の条件や投稿一覧をお試しください。',
              )
            : Column(
                children: [
                  for (final post in items) ...[
                    PostCard(post: post),
                    const SizedBox(height: 12),
                  ],
                  if (pagedProvider != null)
                    LoadMoreButton(provider: pagedProvider!),
                ],
              ),
      ),
    ],
  );
}
