import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_icons.dart';

import '../pages/compose/compose_page.dart';
import '../pages/home/home_page.dart';
import '../pages/mypage/mypage_page.dart';
import '../pages/notifications/notifications_page.dart';
import '../pages/search/search_page.dart';

/// 画面下部タブ(ホーム/検索/書く/お知らせ/マイページ)の選択状態。
final bottomNavIndexProvider = StateProvider<int>((ref) => 0);

/// 5タブ構成のナビゲーションシェル(docs/全体設計書.md 4.1参照)。
class MainNavigationShell extends ConsumerWidget {
  const MainNavigationShell({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentIndex = ref.watch(bottomNavIndexProvider);

    return Scaffold(
      body: IndexedStack(
        index: currentIndex,
        children: [
          HomePage(
            onCompose: () =>
                ref.read(bottomNavIndexProvider.notifier).state = 2,
          ),
          const SearchPage(),
          const ComposePage(),
          const NotificationsPage(),
          const MyPagePage(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: currentIndex,
        onDestinationSelected: (index) =>
            ref.read(bottomNavIndexProvider.notifier).state = index,
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

  static Widget _navIcon(String asset, Color color) => SvgPicture.asset(
    asset,
    width: 24,
    height: 24,
    excludeFromSemantics: true,
    colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
  );
}
