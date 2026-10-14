import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kosodate_hitoiki/core/constants/app_theme.dart';
import 'package:kosodate_hitoiki/presentation/pages/auth/auth_page.dart';
import 'package:kosodate_hitoiki/presentation/pages/report/report_page.dart';
import 'package:kosodate_hitoiki/presentation/providers/auth_provider.dart';

void main() {
  for (final width in [320.0, 768.0]) {
    for (final scale in [1.0, 2.0]) {
      testWidgets('通報フォーム幅$width・文字$scaleで理由・補足を確認できる', (tester) async {
        tester.view.physicalSize = Size(width, 800);
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
              home: const ReportPage(
                targetId: 'p1',
                targetType: ReportTargetType.post,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        await tester.scrollUntilVisible(
          find.text('通報内容を確認'),
          180,
          scrollable: find.byType(Scrollable).first,
        );
        expect(
          tester
              .widget<FilledButton>(
                find.widgetWithText(FilledButton, '通報内容を確認'),
              )
              .onPressed,
          isNull,
        );
        await tester.scrollUntilVisible(
          find.text('その他'),
          -180,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.tap(find.text('その他'));
        await tester.pumpAndSettle();
        await tester.scrollUntilVisible(
          find.byType(TextField),
          180,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.pumpAndSettle();
        await tester.enterText(find.byType(TextField), '補足のサンプル');
        FocusManager.instance.primaryFocus?.unfocus();
        await tester.pumpAndSettle();
        await tester.ensureVisible(find.text('通報内容を確認'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('通報内容を確認'));
        await tester.pumpAndSettle();
        expect(find.text('理由：その他'), findsOneWidget);
        expect(
          find.descendant(
            of: find.byType(AlertDialog),
            matching: find.text('補足のサンプル'),
          ),
          findsOneWidget,
        );
        expect(find.textContaining('現在は送信・記録されません。'), findsOneWidget);
        await tester.tap(find.text('入力に戻る'));
        await tester.pumpAndSettle();
        expect(
          tester.widget<TextField>(find.byType(TextField)).controller!.text,
          '補足のサンプル',
        );
        await tester.scrollUntilVisible(
          find.text('危険を感じる内容'),
          -180,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.tap(find.text('危険を感じる内容'));
        await tester.pumpAndSettle();
        expect(find.byType(TextField), findsNothing);
        expect(tester.takeException(), isNull);
      });
    }
  }
  testWidgets('直接開いてもゲストには通報理由や入力欄を出さない', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [isLoggedInProvider.overrideWithValue(false)],
        child: MaterialApp(
          theme: AppTheme.light,
          home: const ReportPage(
            targetId: 'c1',
            targetType: ReportTargetType.comment,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(RadioListTile<String>), findsNothing);
    expect(find.byType(TextField), findsNothing);
    await tester.ensureVisible(find.text('ログイン'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('ログイン'));
    await tester.pumpAndSettle();
    expect(find.byType(AuthPage), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.byType(ReportPage), findsOneWidget);
  });
}
