import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kosodate_hitoiki/core/constants/app_layout.dart';
import 'package:kosodate_hitoiki/core/constants/app_theme.dart';
import 'package:kosodate_hitoiki/domain/models/topic.dart';
import 'package:kosodate_hitoiki/presentation/pages/support/support_resources_page.dart';
import 'package:kosodate_hitoiki/presentation/providers/auth_provider.dart';
import 'package:kosodate_hitoiki/presentation/providers/post_providers.dart';
import 'package:kosodate_hitoiki/presentation/widgets/desktop_home_panels.dart';
import 'package:kosodate_hitoiki/presentation/widgets/main_navigation_shell.dart';

import 'helpers/scripted_post_repository.dart';

Future<ProviderContainer> pumpShell(WidgetTester tester, Size size) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final repository = ScriptedPostRepository([])
    ..topics = const [
      Topic(id: 1, label: '睡眠・夜泣き'),
      Topic(id: 2, label: '食事・離乳食'),
    ];
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        isLoggedInProvider.overrideWithValue(false),
        postRepositoryProvider.overrideWithValue(repository),
      ],
      child: MaterialApp(
        theme: AppTheme.light,
        home: const MainNavigationShell(),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return ProviderScope.containerOf(tester.element(find.byType(MaterialApp)));
}

void main() {
  testWidgets('幅が足りる広い画面のホームには、大きな見出しと、右の補足のカードを出す', (tester) async {
    await pumpShell(tester, const Size(1500, 1200));
    expect(find.byType(DesktopHomeBanner), findsOneWidget);
    expect(find.byType(DesktopHomeSidePanel), findsOneWidget);
    expect(find.text('ここでは、あなたのペースで'), findsOneWidget);
    expect(find.text('話題から探す'), findsOneWidget);
    expect(find.text('安心して使うために'), findsOneWidget);
    // 右のカードの幅は決まった値。
    expect(
      tester.getSize(find.byType(DesktopHomeSidePanel)).width,
      AppLayout.rightPanelWidth,
    );
  });

  testWidgets('幅が足りないとき(1024〜1280px)は、右のカードを出さない', (tester) async {
    await pumpShell(tester, const Size(1100, 900));
    expect(find.byType(DesktopHomeBanner), findsOneWidget);
    expect(find.byType(DesktopHomeSidePanel), findsNothing);
  });

  testWidgets('スマホ幅では、大きな見出しも右のカードも出さない', (tester) async {
    await pumpShell(tester, const Size(390, 900));
    expect(find.byType(DesktopHomeBanner), findsNothing);
    expect(find.byType(DesktopHomeSidePanel), findsNothing);
  });

  testWidgets('右の「話題から探す」は、決まった順に並び、押すと絞り込み、もう一度で外す', (tester) async {
    final container = await pumpShell(tester, const Size(1500, 1200));
    final first = tester.getTopLeft(find.byKey(const ValueKey('side-topic-1')));
    final second = tester.getTopLeft(
      find.byKey(const ValueKey('side-topic-2')),
    );
    expect(first.dy, lessThan(second.dy));

    await tester.tap(find.byKey(const ValueKey('side-topic-2')));
    await tester.pumpAndSettle();
    expect(container.read(feedTopicProvider)?.id, 2);

    await tester.tap(find.byKey(const ValueKey('side-topic-2')));
    await tester.pumpAndSettle();
    expect(container.read(feedTopicProvider), isNull);
  });

  testWidgets('右の「困ったときの相談先」から、相談先の画面を開ける', (tester) async {
    await pumpShell(tester, const Size(1500, 1400));
    await tester.ensureVisible(find.byKey(const ValueKey('side-support')));
    await tester.tap(find.byKey(const ValueKey('side-support')));
    await tester.pumpAndSettle();
    expect(find.byType(SupportResourcesPage), findsOneWidget);
  });

  testWidgets('ホーム以外のタブでは、右のカードを出さない', (tester) async {
    final container = await pumpShell(tester, const Size(1500, 1200));
    container.read(bottomNavIndexProvider.notifier).state = 1;
    await tester.pumpAndSettle();
    expect(find.byType(DesktopHomeSidePanel), findsNothing);
  });
}
