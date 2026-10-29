import 'package:flutter/material.dart';
import '../../core/widgets/centered_page_transitions.dart';
import 'package:kosodate_hitoiki/presentation/widgets/app_asset.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_icons.dart';
import '../../domain/models/post.dart';
import '../pages/post_detail/post_detail_page.dart';
import '../pages/profile/other_profile_page.dart';
import '../pages/auth/auth_page.dart';
import '../providers/auth_provider.dart';
import '../providers/post_providers.dart';
import '../providers/reaction_providers.dart';
import 'reaction_actions.dart';
import 'reaction_picker.dart';

/// 投稿の保存・解除。認証確認・一覧Providerの更新・エラー表示をここに集約する。
Future<void> togglePostSaved(
  BuildContext context,
  WidgetRef ref,
  Post post,
) async {
  if (!ref.read(isLoggedInProvider)) {
    pushFullWidth<void>(context, builder: (_) => const AuthPage());
    return;
  }
  try {
    await ref.read(postRepositoryProvider).toggleSaved(post.id);
    // await中に画面が閉じられている可能性があるため、refを使う前に確認する。
    if (!context.mounted) return;
    ref.invalidate(postDetailProvider);
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

/// 投稿一覧・検索結果・マイページ共通の投稿カード(確定デザインS-02・S-05参照)。
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
    // この投稿への自分の共感を取得する(表示している投稿の分を、まとめて取得する)。
    ref.read(myReactionsProvider.notifier).request(post.id);
    // この投稿への自分の共感だけを監視し、他の投稿への操作で再構築しない。
    final reactionId = ref.watch(
      myReactionsProvider.select((reactions) => reactions[post.id]),
    );
    final types = ref.watch(reactionTypesProvider).valueOrNull ?? const [];
    final empathy = types.where((type) => type.isEmpathy).firstOrNull;
    final reacted =
        reactionId != null && empathy != null && reactionId == empathy.id;
    // 「わかる」以外の定型文を選んでいるとき、その文言。
    final otherLabel = reactionId != null && !reacted
        ? (types.where((type) => type.id == reactionId).firstOrNull?.label ??
              '共感済み')
        : null;
    // 自分の投稿には共感できない。件数だけを出す(件数は、投稿者本人だけが取得できる)。
    final ownCount = post.isMine
        ? ref.watch(reactionCountProvider(post.id)).valueOrNull ??
              post.empathyCount
        : null;
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
                child: AppAsset(
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
                            fontSize: 12.5,
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
              if (post.underReview)
                const _Tag(
                  key: ValueKey('under-review-tag'),
                  label: '確認中',
                  background: AppColors.divider,
                ),
            ],
          ),
          if (post.underReview) ...[
            const SizedBox(height: 8),
            const Text(
              '通報があったため、いまは、ほかの人には表示されていません。運営が確認しています。',
              key: ValueKey('under-review-note'),
              style: TextStyle(fontSize: 12, height: 1.7),
            ),
          ],
          const SizedBox(height: 12),
          Text(post.body, style: const TextStyle(fontSize: 13.5, height: 1.6)),
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
                      label: !showPresetReactions && otherLabel != null
                          ? '$otherLabel ✓'
                          : '${ownCount != null ? 'わかる $ownCount' : 'わかる'}${reacted ? ' ✓' : ''}',
                      selected: showPresetReactions
                          ? reacted
                          : reactionId != null,
                      // 自分の投稿は、押せない。
                      onTap: post.isMine
                          ? null
                          : () {
                              // 一覧では、何か選んでいれば取り消す。詳細では、「わかる」だけを
                              // 切り替える(ほかの定型文からは、「わかる」に選び直す)。
                              if (reacted ||
                                  (!showPresetReactions &&
                                      reactionId != null)) {
                                changeReaction(context, ref, postId: post.id);
                              } else if (empathy != null) {
                                changeReaction(
                                  context,
                                  ref,
                                  postId: post.id,
                                  reactionTypeId: empathy.id,
                                );
                              } else if (!ref.read(isLoggedInProvider)) {
                                changeReaction(context, ref, postId: post.id);
                              }
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
                    if (showPresetReactions && !post.isMine)
                      _FooterChip(
                        icon: AppIcons.send,
                        selected: reactionId != null && !reacted,
                        onTap: () {
                          if (!ref.read(isLoggedInProvider)) {
                            pushFullWidth<void>(
                              context,
                              builder: (_) => const AuthPage(),
                            );
                            return;
                          }
                          showReactionPicker(context, post.id);
                        },
                        label: otherLabel != null ? '$otherLabel ✓' : '定型文を送る',
                        background: AppColors.secondary.withValues(alpha: 0.45),
                      ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => togglePostSaved(context, ref, post),
                tooltip: post.isSaved ? '保存を解除' : '保存する',
                icon: AppAsset(
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
  const _Tag({super.key, required this.label, required this.background});
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
            AppAsset(
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
