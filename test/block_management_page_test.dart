import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kosodate_hitoiki/core/constants/app_theme.dart';
import 'package:kosodate_hitoiki/presentation/pages/settings/settings_page.dart';
import 'package:kosodate_hitoiki/presentation/pages/settings/block_management_page.dart';
import 'package:kosodate_hitoiki/presentation/providers/auth_provider.dart';

Future<void> tapVisible(WidgetTester tester, String label) async {
  await tester.scrollUntilVisible(
    find.text(label),
    160,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.pumpAndSettle();
  await tester.tap(find.text(label));
  await tester.pumpAndSettle();
}

void main() {
  for (final scale in [1.0, 2.0]) {
    testWidgets('320px文字$scale倍で解除の取消・確認・空表示・復帰', (tester) async {
      tester.view.physicalSize = const Size(320, 700);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [isLoggedInProvider.overrideWithValue(true)],
          child: MaterialApp(
            theme: AppTheme.light,
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(textScaler: TextScaler.linear(scale)),
              child: child!,
            ),
            home: const SettingsPage(),
          ),
        ),
      );
      await tapVisible(tester, 'ブロック管理');
      expect(find.byType(BlockManagementPage), findsOneWidget);
      await tapVisible(tester, '解除');
      await tester.tap(find.text('キャンセル'));
      await tester.pumpAndSettle();
      expect(find.text('あおぞら'), findsOneWidget);
      await tapVisible(tester, '解除');
      await tester.tap(find.text('サンプルで解除'));
      await tester.pumpAndSettle();
      expect(find.text('ブロック中の相手はいません'), findsOneWidget);
      expect(find.text('あおぞら'), findsNothing);
      await tapVisible(tester, 'サンプルを戻す');
      expect(find.text('あおぞら'), findsOneWidget);
      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(find.byType(SettingsPage), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
  testWidgets('直接開いてもゲストには一覧を表示しない', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [isLoggedInProvider.overrideWithValue(false)],
        child: MaterialApp(
          theme: AppTheme.light,
          home: const BlockManagementPage(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('あおぞら'), findsNothing);
    expect(find.text('解除'), findsNothing);
    expect(find.text('ログイン'), findsOneWidget);
  });
}
