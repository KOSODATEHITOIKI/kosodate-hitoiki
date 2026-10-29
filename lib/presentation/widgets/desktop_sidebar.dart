import 'package:flutter/material.dart';

import '../../core/constants/app_brand.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_icons.dart';
import '../../core/constants/app_layout.dart';
import 'app_asset.dart';

/// パソコン向けの広い画面の、左メニュー。ロゴ・各画面への移動・「気持ちを書く」。
class DesktopSidebar extends StatelessWidget {
  const DesktopSidebar({
    super.key,
    required this.currentIndex,
    required this.savedPosts,
    required this.onHome,
    required this.onSearch,
    required this.onNotifications,
    required this.onMyPage,
    required this.onSaved,
    required this.onCompose,
  });

  /// 選んでいるタブ(0ホーム・1検索・2書く・3お知らせ・4マイページ)。
  final int currentIndex;

  /// マイページで、保存した投稿を見ているか。
  final bool savedPosts;
  final VoidCallback onHome;
  final VoidCallback onSearch;
  final VoidCallback onNotifications;
  final VoidCallback onMyPage;
  final VoidCallback onSaved;
  final VoidCallback onCompose;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: AppLayout.sidebarWidth,
    child: DecoratedBox(
      decoration: const BoxDecoration(
        color: AppColors.background,
        border: Border(right: BorderSide(color: AppColors.divider)),
      ),
      child: Stack(
        children: [
          // 下の飾り(雲)。操作の邪魔にならないよう、いちばん後ろに置く。
          const Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: IgnorePointer(
              child: AppAsset(
                AppDecorations.cloudsBottom,
                excludeFromSemantics: true,
              ),
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(left: 8, bottom: 24),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: AppAsset(
                        AppBrand.logo,
                        height: 56,
                        semanticsLabel: 'ひと息',
                      ),
                    ),
                  ),
                  _Item(
                    key: const ValueKey('sidebar-home'),
                    icon: AppIcons.navHome,
                    label: 'ホーム',
                    selected: currentIndex == 0,
                    onTap: onHome,
                  ),
                  _Item(
                    key: const ValueKey('sidebar-search'),
                    icon: AppIcons.navSearch,
                    label: '検索',
                    selected: currentIndex == 1,
                    onTap: onSearch,
                  ),
                  _Item(
                    key: const ValueKey('sidebar-notifications'),
                    icon: AppIcons.navNotifications,
                    label: 'お知らせ',
                    selected: currentIndex == 3,
                    onTap: onNotifications,
                  ),
                  _Item(
                    key: const ValueKey('sidebar-mypage'),
                    icon: AppIcons.navMyPage,
                    label: 'マイページ',
                    selected: currentIndex == 4 && !savedPosts,
                    onTap: onMyPage,
                  ),
                  _Item(
                    key: const ValueKey('sidebar-saved'),
                    icon: AppIcons.bookmark,
                    label: '保存した投稿',
                    selected: currentIndex == 4 && savedPosts,
                    onTap: onSaved,
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Divider(height: 1),
                  ),
                  FilledButton.icon(
                    key: const ValueKey('sidebar-compose'),
                    onPressed: onCompose,
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(52),
                      shape: const StadiumBorder(),
                      textStyle: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    icon: const AppAsset(
                      AppIcons.navCompose,
                      width: 22,
                      height: 22,
                      excludeFromSemantics: true,
                      colorFilter: ColorFilter.mode(
                        AppColors.white,
                        BlendMode.srcIn,
                      ),
                    ),
                    label: const Text('気持ちを書く'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

class _Item extends StatelessWidget {
  const _Item({
    super.key,
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.primary : AppColors.textPrimary;
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Material(
        color: selected
            ? AppColors.primary.withValues(alpha: 0.12)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Semantics(
            selected: selected,
            button: true,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  AppAsset(
                    icon,
                    width: 24,
                    height: 24,
                    excludeFromSemantics: true,
                    colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      label,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: selected
                            ? FontWeight.w700
                            : FontWeight.w500,
                        color: color,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
