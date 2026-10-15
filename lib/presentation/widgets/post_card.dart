import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_icons.dart';
import '../../domain/models/post.dart';
import '../pages/post_detail/post_detail_page.dart';
import '../pages/profile/other_profile_page.dart';
import '../pages/auth/auth_page.dart';
import '../providers/auth_provider.dart';
import '../providers/mock_reaction_providers.dart';
import '../providers/post_providers.dart';
import 'reaction_picker.dart';

/// 投稿の保存・解除。認証確認・一覧Providerの更新・エラー表示をここに集約する。
Future<void> togglePostSaved(
  BuildContext context,
  WidgetRef ref,
  Post post,
) async {
  if (!ref.read(isLoggedInProvider)) {
    Navigator.of(
      context,
    ).push<void>(MaterialPageRoute(builder: (_) => const AuthPage()));
    return;
  }
  try {
    await ref.read(postRepositoryProvider).toggleSaved(post.id);
    // await中に画面が閉じられている可能性があるため、refを使う前に確認する。
    if (!context.mounted) return;
    ref.invalidate(feedPostsProvider);
    ref.invalidate(searchResultsProvider);
    ref.invalidate(myPostsProvider);
    ref.invalidate(savedPostsProvider);
  } catch (_) {
    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('保存状態を変更できませんでした')));
    }
  }
}

/// 投稿一覧・検索結果・マイページ共通の投稿カード(docs/design S-02・S-05参照)。
class PostCard extends ConsumerWidget {
  const PostCard({
    super.key,
    required this.post,
    this.showOpenButton = true,
    this.onOpenComments,
    this.showPresetReactions = false,
    this.showMenuButton = true,
  });

  final Post post;
  final bool showOpenButton;
  final VoidCallback? onOpenComments;
  final bool showPresetReactions;
  final bool showMenuButton;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reacted = ref.watch(mockEmpathyProvider).contains(post.id);
    final reaction = ref.watch(mockReactionsProvider)[post.id];
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipOval(
                child: SvgPicture.asset(
                  post.authorAvatarAsset,
                  width: 36,
                  height: 36,
                  excludeFromSemantics: true,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    InkWell(
                      onTap: () => Navigator.of(context).push<void>(
                        MaterialPageRoute(
                          builder: (_) =>
                              OtherProfilePage(userId: post.authorId),
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Text(
                          post.authorName,
                          style: const TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                    Text(
                      _relativeTime(post.createdAt),
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              if (showMenuButton)
                IconButton(
                  onPressed: () => Navigator.of(context).push<void>(
                    MaterialPageRoute(
                      builder: (_) =>
                          PostDetailPage(post: post, autoOpenMenu: true),
                    ),
                  ),
                  tooltip: '投稿メニュー',
                  icon: const Icon(Icons.more_horiz),
                  visualDensity: VisualDensity.compact,
                ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              _Tag(label: post.type.label, background: _typeColor(post.type)),
              _Tag(
                label: post.responseMode.label,
                background: AppColors.accentPink,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(post.body, style: const TextStyle(fontSize: 14.5, height: 1.6)),
          if (showOpenButton)
            TextButton(
              onPressed: () => Navigator.of(context).push<void>(
                MaterialPageRoute(builder: (_) => PostDetailPage(post: post)),
              ),
              child: const Text('投稿の詳細を見る'),
            ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _FooterChip(
                      icon: AppIcons.heart,
                      label:
                          !showPresetReactions && reaction != null && !reacted
                          ? '${reaction.label} ✓'
                          : '${post.isMine ? 'わかる ${post.empathyCount}' : 'わかる'}${reacted ? ' ✓' : ''}',
                      selected: showPresetReactions
                          ? reacted
                          : reaction != null,
                      onTap: () {
                        if (!ref.read(isLoggedInProvider)) {
                          Navigator.of(context).push<void>(
                            MaterialPageRoute(builder: (_) => const AuthPage()),
                          );
                          return;
                        }
                        ref.read(mockReactionAuthGuardProvider);
                        final current = {...ref.read(mockReactionsProvider)};
                        if (current[post.id] == MockReaction.empathy ||
                            (!showPresetReactions &&
                                current.containsKey(post.id))) {
                          current.remove(post.id);
                        } else {
                          current[post.id] = MockReaction.empathy;
                        }
                        ref.read(mockReactionsProvider.notifier).state =
                            current;
                      },
                      background: reacted
                          ? AppColors.secondary
                          : AppColors.accentPink,
                    ),
                    if (post.responseMode == ResponseMode.advice)
                      _FooterChip(
                        icon: AppIcons.comment,
                        onTap:
                            onOpenComments ??
                            () => Navigator.of(context).push<void>(
                              MaterialPageRoute(
                                builder: (_) => PostDetailPage(
                                  post: post,
                                  focusComments: true,
                                ),
                              ),
                            ),
                        label: post.commentCount > 0
                            ? 'コメント ${post.commentCount}'
                            : 'コメントする',
                        background: AppColors.accentLeaf.withValues(alpha: 0.3),
                      ),
                    if (showPresetReactions)
                      _FooterChip(
                        icon: AppIcons.send,
                        selected: reaction != null && !reacted,
                        onTap: () {
                          if (!ref.read(isLoggedInProvider)) {
                            Navigator.of(context).push<void>(
                              MaterialPageRoute(
                                builder: (_) => const AuthPage(),
                              ),
                            );
                            return;
                          }
                          showReactionPicker(context, post.id);
                        },
                        label: reaction != null && !reacted
                            ? '${reaction.label} ✓'
                            : '定型文を送る',
                        background: AppColors.secondary.withValues(alpha: 0.45),
                      ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => togglePostSaved(context, ref, post),
                tooltip: post.isSaved ? '保存を解除' : '保存する',
                icon: SvgPicture.asset(
                  post.isSaved ? AppIcons.bookmarkSaved : AppIcons.bookmark,
                  width: 22,
                  height: 22,
                  excludeFromSemantics: true,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static Color _typeColor(PostType type) => switch (type) {
    PostType.grumble => AppColors.accentPink,
    PostType.consult || PostType.tips => AppColors.secondary,
  };

  static String _relativeTime(DateTime time) {
    final diff = DateTime.now().difference(time);
    if (diff.inMinutes < 1) {
      return 'たった今';
    }
    if (diff.inMinutes < 60) {
      return '${diff.inMinutes}分前';
    }
    if (diff.inHours < 24) {
      return '${diff.inHours}時間前';
    }
    return '${diff.inDays}日前';
  }
}

class _Tag extends StatelessWidget {
  const _Tag({required this.label, required this.background});
  final String label;
  final Color background;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(
      color: background,
      borderRadius: BorderRadius.circular(999),
    ),
    child: Text(
      label,
      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
    ),
  );
}

class _FooterChip extends StatelessWidget {
  const _FooterChip({
    required this.icon,
    required this.label,
    this.background = AppColors.surface,
    this.onTap,
    this.selected,
  });
  final String icon;
  final String label;
  final Color background;
  final VoidCallback? onTap;
  final bool? selected;

  @override
  Widget build(BuildContext context) => Semantics(
    button: onTap != null,
    selected: selected,
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SvgPicture.asset(
              icon,
              width: 16,
              height: 16,
              excludeFromSemantics: true,
              colorFilter: const ColorFilter.mode(
                AppColors.textPrimary,
                BlendMode.srcIn,
              ),
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
