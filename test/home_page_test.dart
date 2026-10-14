import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kosodate_hitoiki/core/constants/app_colors.dart';
import 'package:kosodate_hitoiki/core/constants/app_theme.dart';
import 'package:kosodate_hitoiki/presentation/pages/home/home_page.dart';

void main() {
  for (final width in [320.0, 390.0, 768.0]) {
    for (final scale in [1.0, 2.0]) {
      testWidgets('ホーム幅$width・文字倍率$scaleで絞り込みと投稿ボタンを操作できる', (tester) async {
        tester.view.physicalSize = Size(width, 800);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        var composeCount = 0;
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.light,
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(textScaler: TextScaler.linear(scale)),
              child: child!,
            ),
            home: Scaffold(body: HomePage(onCompose: () => composeCount++)),
          ),
        );
        await tester.pumpAndSettle();
        await tester.scrollUntilVisible(
          find.widgetWithText(ChoiceChip, '相談'),
          150,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.pumpAndSettle();
        await tester.ensureVisible(find.widgetWithText(ChoiceChip, '相談'));
        await tester.pumpAndSettle();
        await tester.tap(find.widgetWithText(ChoiceChip, '相談'));
        await tester.pumpAndSettle();
        final chip = tester.widget<ChoiceChip>(
          find.widgetWithText(ChoiceChip, '相談'),
        );
        expect(chip.selected, isTrue);
        expect(chip.selectedColor, AppColors.secondary);
        await tester.scrollUntilVisible(
          find.text('気持ちを書く  ›'),
          -150,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.pumpAndSettle();
        await tester.ensureVisible(find.text('気持ちを書く  ›'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('気持ちを書く  ›'));
        expect(composeCount, 1);
        expect(tester.takeException(), isNull);
      });
    }
  }
}
