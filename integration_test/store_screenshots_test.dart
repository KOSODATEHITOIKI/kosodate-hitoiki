// ストア(App Store・Google Play)のスクリーンショットを撮るための操作。
//
// 本物のサーバーにはつながない。画面の確認用のデータ(lib/data/mock/)を、「サンプル」の
// 注記を出さない形で差し込み、ログインした状態で、画面を順に開く。本物の利用者の投稿は
// 写らず、サーバーにも撮影用のデータを残さない。
//
// 各画面で「SNAP:<名前>」を出力して数秒止まるので、そのあいだに、外から
// `xcrun simctl io <UDID> screenshot`で撮る(tool/ios_screenshots/shoot.sh)。
// 撮影の手順は docs/iOSリリース手順.md の「スクリーンショット」を参照。
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:kosodate_hitoiki/core/config/flavor.dart';
import 'package:kosodate_hitoiki/core/constants/app_theme.dart';
import 'package:kosodate_hitoiki/core/utils/accessibility.dart';
import 'package:kosodate_hitoiki/core/widgets/wide_screen_frame.dart';
import 'package:kosodate_hitoiki/data/mock/mock_comment_repository.dart';
import 'package:kosodate_hitoiki/data/mock/mock_mute_repository.dart';
import 'package:kosodate_hitoiki/data/mock/mock_notification_repository.dart';
import 'package:kosodate_hitoiki/data/mock/mock_post_repository.dart';
import 'package:kosodate_hitoiki/data/mock/mock_profile_repository.dart';
import 'package:kosodate_hitoiki/presentation/pages/post_detail/post_detail_page.dart';
import 'package:kosodate_hitoiki/presentation/pages/settings/mute_management_page.dart';
import 'package:kosodate_hitoiki/presentation/pages/support/support_resources_page.dart';
import 'package:kosodate_hitoiki/presentation/pages/welcome/welcome_page.dart';
import 'package:kosodate_hitoiki/presentation/providers/auth_provider.dart';
import 'package:kosodate_hitoiki/presentation/providers/comment_providers.dart';
import 'package:kosodate_hitoiki/presentation/providers/mute_providers.dart';
import 'package:kosodate_hitoiki/presentation/providers/notification_providers.dart';
import 'package:kosodate_hitoiki/presentation/providers/post_providers.dart';
import 'package:kosodate_hitoiki/presentation/providers/profile_providers.dart';
import 'package:kosodate_hitoiki/presentation/widgets/main_navigation_shell.dart';

/// 撮影のあいだ、止まる時間。
const _snapPause = Duration(seconds: 4);

/// 画面の確認用のデータを、「サンプル」の注記を出さずに使う(撮影だけ)。
class _StorePosts extends MockPostRepository {
  @override
  bool get isSample => false;
}

class _StoreComments extends MockCommentRepository {
  @override
  bool get isSample => false;
}

class _StoreProfiles extends MockProfileRepository {
  @override
  bool get isSample => false;
}

class _StoreNotifications extends MockNotificationRepository {
  @override
  bool get isSample => false;
}

class _StoreMutes extends MockMuteRepository {
  @override
  bool get isSample => false;
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  /// 実際の時間で待つ(アニメーションが続く画面では、pumpAndSettleが終わらないため)。
  Future<void> wait(WidgetTester tester, Duration duration) async {
    final end = DateTime.now().add(duration);
    while (DateTime.now().isBefore(end)) {
      await tester.pump();
      await Future<void>.delayed(const Duration(milliseconds: 100));
    }
  }

  Future<void> snap(WidgetTester tester, String name) async {
    await wait(tester, const Duration(milliseconds: 1200));
    // ignore: avoid_print
    print('SNAP:$name');
    await wait(tester, _snapPause);
  }

  /// アプリ本体(lib/app.dart)と同じ見た目の土台で、[home]を開く。
  Future<NavigatorState> open(
    WidgetTester tester,
    Widget home, {
    required bool loggedIn,
  }) async {
    final navigatorKey = GlobalKey<NavigatorState>();
    final posts = _StorePosts();
    await tester.pumpWidget(
      ProviderScope(
        key: UniqueKey(),
        overrides: [
          isLoggedInProvider.overrideWithValue(loggedIn),
          currentUserIdProvider.overrideWithValue(
            loggedIn ? 'sample-komorebi' : null,
          ),
          postRepositoryProvider.overrideWithValue(posts),
          commentRepositoryProvider.overrideWithValue(_StoreComments()),
          profileRepositoryProvider.overrideWithValue(_StoreProfiles()),
          notificationRepositoryProvider.overrideWithValue(
            _StoreNotifications(),
          ),
          muteRepositoryProvider.overrideWithValue(_StoreMutes()),
        ],
        child: MaterialApp(
          navigatorKey: navigatorKey,
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: responsiveTextScaler(context)),
            child: WideScreenFrame(child: child!),
          ),
          home: home,
        ),
      ),
    );
    await wait(tester, const Duration(seconds: 2));
    return navigatorKey.currentState!;
  }

  Future<void> push(
    WidgetTester tester,
    NavigatorState navigator,
    Widget page,
  ) async {
    navigator.push(MaterialPageRoute<void>(builder: (_) => page));
    await wait(tester, const Duration(seconds: 1));
  }

  Future<void> tapText(WidgetTester tester, String text) async {
    await tester.tap(find.text(text).last);
    await wait(tester, const Duration(seconds: 1));
  }

  testWidgets('ストアのスクリーンショット', (tester) async {
    AppConfig.setFlavor(Flavor.prod);

    // 1. 最初の案内(安心して使うための3つの約束)。
    await open(tester, const WelcomePage(), loggedIn: false);
    await snap(tester, '01_welcome');

    // 2. ホーム(ログインした状態)。
    final navigator = await open(
      tester,
      const MainNavigationShell(),
      loggedIn: true,
    );
    await snap(tester, '02_home');

    // 3. 投稿の詳細(コメント・返信)。
    final post = (await _StorePosts().fetchFeed()).firstWhere(
      (p) => p.id == 'p2',
    );
    await push(tester, navigator, PostDetailPage(post: post));
    await snap(tester, '03_detail');
    navigator.pop();
    await wait(tester, const Duration(seconds: 1));

    // 4. 投稿する(種類を選ぶ)。
    await tapText(tester, '書く');
    await snap(tester, '04_compose');
    if (navigator.canPop()) navigator.pop();
    await wait(tester, const Duration(seconds: 1));

    // 5. 検索。
    await tapText(tester, '検索');
    await snap(tester, '05_search');

    // 6. ミュート(見たくない話題・言葉)。
    await push(tester, navigator, const MuteManagementPage());
    await snap(tester, '06_mute');
    navigator.pop();

    // 7. 困ったときの相談先。
    await push(tester, navigator, const SupportResourcesPage());
    await snap(tester, '07_support');
  });
}
