import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kosodate_hitoiki/app.dart';
import 'package:kosodate_hitoiki/core/constants/app_layout.dart';
import 'package:kosodate_hitoiki/presentation/pages/auth/auth_page.dart';
import 'package:kosodate_hitoiki/presentation/pages/support/support_resources_page.dart';
import 'package:kosodate_hitoiki/presentation/providers/auth_provider.dart';
import 'package:kosodate_hitoiki/presentation/widgets/desktop_sidebar.dart';
import 'package:kosodate_hitoiki/presentation/widgets/main_navigation_shell.dart';

Future<ProviderContainer> pumpShell(WidgetTester tester, Size size) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [isLoggedInProvider.overrideWithValue(false)],
      child: const App(),
    ),
  );
  final container = ProviderScope.containerOf(
    tester.element(find.byType(MaterialApp)),
  );
  await tester.ensureVisible(find.text('登録せずに読む'));
  await tester.tap(find.text('登録せずに読む'));
  await tester.pumpAndSettle();
  return container;
}

Future<void> openSupport(WidgetTester tester) async {
  await tester.ensureVisible(find.byKey(const ValueKey('side-support')));
  await tester.tap(find.byKey(const ValueKey('side-support')));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('広い画面で開いた画面は、中央の枠の中に出て、左メニューが残る', (tester) async {
    await pumpShell(tester, const Size(1500, 1400));
    await openSupport(tester);

    expect(find.byType(SupportResourcesPage), findsOneWidget);
    expect(find.byType(DesktopSidebar), findsOneWidget);
    // 開いた画面は、左メニューの右側の、中央の枠に収まる。
    final page = tester.getRect(find.byType(SupportResourcesPage));
    expect(page.left, greaterThanOrEqualTo(AppLayout.sidebarWidth));
    expect(tester.takeException(), isNull);
  });

  testWidgets('戻る操作は、枠の中の画面を先に閉じる(アプリは閉じない)', (tester) async {
    await pumpShell(tester, const Size(1500, 1400));
    await openSupport(tester);
    expect(find.byType(SupportResourcesPage), findsOneWidget);

    final handled = await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(handled, isTrue);
    expect(find.byType(SupportResourcesPage), findsNothing);
    // ホーム(左メニュー付き)に戻っている。
    expect(find.byType(DesktopSidebar), findsOneWidget);
    expect(find.byType(MainNavigationShell), findsOneWidget);
  });

  testWidgets('左メニューを押すと、枠の中で開いていた画面を閉じて、そのタブに移る', (tester) async {
    final container = await pumpShell(tester, const Size(1500, 1400));
    await openSupport(tester);
    expect(find.byType(SupportResourcesPage), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('sidebar-search')));
    await tester.pumpAndSettle();
    expect(find.byType(SupportResourcesPage), findsNothing);
    expect(container.read(bottomNavIndexProvider), 1);
  });

  testWidgets('外からタブが変わっても(通知のタップなど)、枠の中の画面を閉じる', (tester) async {
    final container = await pumpShell(tester, const Size(1500, 1400));
    await openSupport(tester);

    container.read(bottomNavIndexProvider.notifier).state =
        notificationsTabIndex;
    await tester.pumpAndSettle();
    expect(find.byType(SupportResourcesPage), findsNothing);
  });

  testWidgets('ログインは、枠の外(窓いっぱい)で開く。左メニューは隠れる', (tester) async {
    await pumpShell(tester, const Size(1500, 1000));
    await tester.tap(find.byKey(const ValueKey('sidebar-mypage')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('登録・ログイン'));
    await tester.pumpAndSettle();

    expect(find.byType(AuthPage), findsOneWidget);
    // 窓の幅いっぱいを使う(中央の細い枠には収まらない)。
    expect(
      tester.getSize(find.byType(AuthPage)).width,
      greaterThan(AppLayout.centerMaxWidth),
    );
    expect(find.byType(DesktopSidebar), findsNothing);
  });
}
