import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kosodate_hitoiki/app.dart';
import 'package:kosodate_hitoiki/core/constants/app_layout.dart';
import 'package:kosodate_hitoiki/presentation/providers/auth_provider.dart';
import 'package:kosodate_hitoiki/presentation/providers/my_page_providers.dart';
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

void main() {
  testWidgets('スマホ幅では、下のタブを出し、左メニューは出さない', (tester) async {
    await pumpShell(tester, const Size(390, 900));
    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.byType(DesktopSidebar), findsNothing);
  });

  testWidgets('パソコン向けの幅(1024px以上)では、左メニューを出し、下のタブは出さない', (tester) async {
    await pumpShell(tester, const Size(1280, 900));
    expect(find.byType(DesktopSidebar), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);
    // 左メニューの幅は決まった値。中央は、最大の幅を超えない。
    expect(
      tester.getSize(find.byType(DesktopSidebar)).width,
      AppLayout.sidebarWidth,
    );
    expect(
      tester.getSize(find.byType(IndexedStack)).width,
      lessThanOrEqualTo(AppLayout.centerMaxWidth),
    );
    for (final label in ['ホーム', '検索', 'お知らせ', 'マイページ', '保存した投稿', '気持ちを書く']) {
      expect(
        find.descendant(
          of: find.byType(DesktopSidebar),
          matching: find.text(label),
        ),
        findsOneWidget,
        reason: label,
      );
    }
  });

  testWidgets('左メニューで、各画面へ移れる。「保存した投稿」は、マイページの保存の一覧を開く', (tester) async {
    final container = await pumpShell(tester, const Size(1280, 900));
    int tab() => container.read(bottomNavIndexProvider);

    await tester.tap(find.byKey(const ValueKey('sidebar-search')));
    await tester.pumpAndSettle();
    expect(tab(), 1);

    await tester.tap(find.byKey(const ValueKey('sidebar-notifications')));
    await tester.pumpAndSettle();
    expect(tab(), notificationsTabIndex);

    await tester.tap(find.byKey(const ValueKey('sidebar-saved')));
    await tester.pumpAndSettle();
    expect(tab(), 4);
    expect(container.read(myPageSavedPostsProvider), isTrue);

    await tester.tap(find.byKey(const ValueKey('sidebar-mypage')));
    await tester.pumpAndSettle();
    expect(tab(), 4);
    expect(container.read(myPageSavedPostsProvider), isFalse);

    await tester.tap(find.byKey(const ValueKey('sidebar-compose')));
    await tester.pumpAndSettle();
    expect(tab(), 2);

    await tester.tap(find.byKey(const ValueKey('sidebar-home')));
    await tester.pumpAndSettle();
    expect(tab(), 0);
    expect(tester.takeException(), isNull);
  });
}
