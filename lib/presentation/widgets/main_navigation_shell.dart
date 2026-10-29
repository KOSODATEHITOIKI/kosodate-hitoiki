import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kosodate_hitoiki/presentation/widgets/app_asset.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_icons.dart';
import '../../core/constants/app_layout.dart';

import '../pages/compose/compose_page.dart';
import '../pages/home/home_page.dart';
import '../pages/mypage/mypage_page.dart';
import '../pages/notifications/notifications_page.dart';
import '../pages/search/search_page.dart';
import '../providers/my_page_providers.dart';
import 'desktop_sidebar.dart';

/// 画面下部タブ(ホーム/検索/書く/お知らせ/マイページ)の選択状態。
final bottomNavIndexProvider = StateProvider<int>((ref) => 0);

/// 「お知らせ」タブの位置(通知をタップしたとき、ここを開く)。
const notificationsTabIndex = 3;

/// 5タブ構成のナビゲーションシェル(docs/全体設計書.md 4.1参照)。
/// スマホは下のタブ。パソコン向けの広い画面(1024px以上)は、左メニューと中央の列。
class MainNavigationShell extends ConsumerWidget {
  const MainNavigationShell({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentIndex = ref.watch(bottomNavIndexProvider);
    void go(int index) =>
        ref.read(bottomNavIndexProvider.notifier).state = index;

    final pages = IndexedStack(
      index: currentIndex,
      children: [
        HomePage(onCompose: () => go(2)),
        const SearchPage(),
        const ComposePage(),
        const NotificationsPage(),
        const MyPagePage(),
      ],
    );

    if (AppLayout.isDesktop(MediaQuery.sizeOf(context).width)) {
      final savedPosts = ref.watch(myPageSavedPostsProvider);
      return Scaffold(
        body: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DesktopSidebar(
              currentIndex: currentIndex,
              savedPosts: savedPosts,
              onHome: () => go(0),
              onSearch: () => go(1),
              onNotifications: () => go(notificationsTabIndex),
              onMyPage: () {
                ref.read(myPageSavedPostsProvider.notifier).state = false;
                go(4);
              },
              onSaved: () {
                ref.read(myPageSavedPostsProvider.notifier).state = true;
                go(4);
              },
              onCompose: () => go(2),
            ),
            Expanded(
              child: Align(
                alignment: Alignment.topCenter,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: AppLayout.centerMaxWidth,
                  ),
                  child: pages,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      body: pages,
      bottomNavigationBar: NavigationBar(
        selectedIndex: currentIndex,
        onDestinationSelected: go,
        destinations: [
          for (final destination in const [
            (AppIcons.navHome, 'ホーム'),
            (AppIcons.navSearch, '検索'),
            (AppIcons.navCompose, '書く'),
            (AppIcons.navNotifications, 'お知らせ'),
            (AppIcons.navMyPage, 'マイページ'),
          ])
            NavigationDestination(
              icon: _navIcon(destination.$1, AppColors.textSecondary),
              selectedIcon: _navIcon(destination.$1, AppColors.primary),
              label: destination.$2,
            ),
        ],
      ),
    );
  }

  static Widget _navIcon(String asset, Color color) => AppAsset(
    asset,
    width: 24,
    height: 24,
    excludeFromSemantics: true,
    colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
  );
}
