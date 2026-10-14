import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_icons.dart';
import '../../domain/models/post.dart';

/// 投稿一覧・検索結果・マイページ共通の投稿カード(docs/design S-02・S-05参照)。
class PostCard extends StatelessWidget {
  const PostCard({super.key, required this.post, this.onToggleSaved});

  final Post post;
  final VoidCallback? onToggleSaved;

  @override
  Widget build(BuildContext context) => Container(
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
                  Text(
                    post.authorName,
                    style: const TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
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
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            _Tag(label: post.type.label, background: AppColors.secondary),
            _Tag(
              label: post.responseMode.label,
              background: AppColors.accentPink,
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(post.body, style: const TextStyle(fontSize: 14.5, height: 1.6)),
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
                    label: post.isMine ? 'わかる ${post.empathyCount}' : 'わかる',
                  ),
                  if (post.responseMode == ResponseMode.advice)
                    _FooterChip(
                      icon: AppIcons.comment,
                      label: post.commentCount > 0
                          ? 'コメント ${post.commentCount}'
                          : 'コメントする',
                    )
                  else
                    _FooterChip(icon: AppIcons.send, label: '定型文を送る'),
                ],
              ),
            ),
            IconButton(
              onPressed: onToggleSaved,
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
  const _FooterChip({required this.icon, required this.label});
  final String icon;
  final String label;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    decoration: BoxDecoration(
      color: AppColors.surface,
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
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
          ),
        ),
      ],
    ),
  );
}
