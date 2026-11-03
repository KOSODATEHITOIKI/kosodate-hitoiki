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
import 'desktop_home_panels.dart';
import 'desktop_sidebar.dart';

/// 画面下部タブ(ホーム/検索/書く/お知らせ/マイページ)の選択状態。
final bottomNavIndexProvider = StateProvider<int>((ref) => 0);

/// 「お知らせ」タブの位置(通知をタップしたとき、ここを開く)。
const notificationsTabIndex = 3;

/// 5タブ構成のナビゲーションシェル(docs/全体設計書.md 4.1参照)。
/// スマホは下のタブ。パソコン向けの広い画面(1024px以上)は、左メニューと中央の枠。
/// 広い画面では、投稿の詳細・設定などは、中央の枠の中で開き、左メニューは残す。
class MainNavigationShell extends ConsumerStatefulWidget {
  const MainNavigationShell({super.key});

  @override
  ConsumerState<MainNavigationShell> createState() =>
      _MainNavigationShellState();
}

class _MainNavigationShellState extends ConsumerState<MainNavigationShell> {
  /// 広い画面の、中央の枠の中の画面の切り替え。
  final _frameNavigatorKey = GlobalKey<NavigatorState>();

  /// 中央の枠の中に開いている画面の数(いちばん下のタブの画面は数えない)。
  final _frameDepth = ValueNotifier<int>(0);
  late final _frameObserver = _FrameDepthObserver(_frameDepth);

  @override
  void dispose() {
    _frameDepth.dispose();
    super.dispose();
  }

  /// 枠の中で開いている画面を閉じて、タブの最初の画面に戻す。
  void _closeFramePages() =>
      _frameNavigatorKey.currentState?.popUntil((route) => route.isFirst);

  void _go(int index) {
    _closeFramePages();
    ref.read(bottomNavIndexProvider.notifier).state = index;
  }

  @override
  Widget build(BuildContext context) {
    final currentIndex = ref.watch(bottomNavIndexProvider);
    // 通知のタップなど、外からタブが変わったときも、枠の中の画面は閉じる。
    ref.listen<int>(bottomNavIndexProvider, (_, _) => _closeFramePages());

    if (AppLayout.isDesktop(MediaQuery.sizeOf(context).width)) {
      final savedPosts = ref.watch(myPageSavedPostsProvider);
      // ホームで、幅が足りるときだけ、右に補足のカードを出す。
      final showSidePanel =
          currentIndex == 0 &&
          MediaQuery.sizeOf(context).width >= AppLayout.rightPanelMinWidth;
      final frame = Navigator(
        key: _frameNavigatorKey,
        observers: [_frameObserver],
        onGenerateRoute: (_) =>
            MaterialPageRoute<void>(builder: (_) => const _ShellPages()),
      );
      return Scaffold(
        // 戻る操作(ブラウザの戻る・端末の戻る)は、枠の中の画面から先に閉じる。
        body: ValueListenableBuilder<int>(
          valueListenable: _frameDepth,
          builder: (context, depth, child) => PopScope(
            canPop: depth == 0,
            onPopInvokedWithResult: (didPop, _) {
              if (!didPop) _frameNavigatorKey.currentState?.maybePop();
            },
            child: child!,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              DesktopSidebar(
                currentIndex: currentIndex,
                savedPosts: savedPosts,
                onHome: () => _go(0),
                onSearch: () => _go(1),
                onNotifications: () => _go(notificationsTabIndex),
                onMyPage: () {
                  ref.read(myPageSavedPostsProvider.notifier).state = false;
                  _go(4);
                },
                onSaved: () {
                  ref.read(myPageSavedPostsProvider.notifier).state = true;
                  _go(4);
                },
                onCompose: () => _go(2),
              ),
              Expanded(
                child: Align(
                  alignment: Alignment.topCenter,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: showSidePanel
                          ? AppLayout.centerMaxWidth +
                                AppLayout.panelGap +
                                AppLayout.rightPanelWidth
                          : AppLayout.centerMaxWidth,
                    ),
                    child: showSidePanel
                        ? Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Expanded(child: frame),
                              const SizedBox(width: AppLayout.panelGap),
                              SizedBox(
                                width: AppLayout.rightPanelWidth,
                                child: DesktopHomeSidePanel(
                                  openPage: (page) => _frameNavigatorKey
                                      .currentState
                                      ?.push<void>(
                                        MaterialPageRoute(builder: (_) => page),
                                      ),
                                ),
                              ),
                            ],
                          )
                        : frame,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      body: const _ShellPages(),
      bottomNavigationBar: NavigationBar(
        selectedIndex: currentIndex,
        onDestinationSelected: _go,
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

/// 5つのタブの画面。選ばれているタブを、ここで読む
/// (中央の枠の中の画面の切り替えは、親が作り直しても、この中身を使い続けるため)。
class _ShellPages extends ConsumerWidget {
  const _ShellPages();

  @override
  Widget build(BuildContext context, WidgetRef ref) => IndexedStack(
    index: ref.watch(bottomNavIndexProvider),
    children: [
      HomePage(
        onCompose: () => ref.read(bottomNavIndexProvider.notifier).state = 2,
      ),
      const SearchPage(),
      const ComposePage(),
      const NotificationsPage(),
      const MyPagePage(),
    ],
  );
}

/// 中央の枠の中に開いている画面の数を数える(戻る操作で、先に閉じるかを決めるため)。
class _FrameDepthObserver extends NavigatorObserver {
  _FrameDepthObserver(this._depth);

  final ValueNotifier<int> _depth;

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    // 最初の画面(タブ)は数えない。
    if (previousRoute != null) _depth.value++;
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    if (_depth.value > 0) _depth.value--;
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    if (_depth.value > 0) _depth.value--;
  }
}
