import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kosodate_hitoiki/core/constants/app_theme.dart';
import 'package:kosodate_hitoiki/presentation/pages/settings/settings_page.dart';
import 'package:kosodate_hitoiki/presentation/pages/settings/withdrawal_page.dart';
import 'package:kosodate_hitoiki/presentation/providers/auth_provider.dart';

void main() {
  for (final width in [320.0, 768.0]) {
    for (final scale in [1.0, 2.0]) {
      testWidgets('退会の説明・確認・利用継続 幅$width文字$scale', (tester) async {
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
              home: const SettingsPage(),
            ),
          ),
        );
        await tester.pumpAndSettle();
        await tester.scrollUntilVisible(
          find.text('退会'),
          180,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.pumpAndSettle();
        await tester.tap(find.text('退会'));
        await tester.pumpAndSettle();
        expect(find.byType(WithdrawalPage), findsOneWidget);
        await tester.scrollUntilVisible(
          find.text('退会の確認へ'),
          180,
          scrollable: find.byType(Scrollable).first,
        );
        expect(
          tester
              .widget<OutlinedButton>(
                find.widgetWithText(OutlinedButton, '退会の確認へ'),
              )
              .onPressed,
          isNull,
        );
        await tester.ensureVisible(find.byType(CheckboxListTile));
        await tester.pumpAndSettle();
        await tester.tap(find.byType(CheckboxListTile));
        await tester.pumpAndSettle();
        await tester.ensureVisible(find.text('退会の確認へ'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('退会の確認へ'));
        await tester.pumpAndSettle();
        expect(find.text('退会機能は準備中です'), findsOneWidget);
        await tester.tap(find.text('戻る'));
        await tester.pumpAndSettle();
        await tester.scrollUntilVisible(
          find.text('利用を続ける'),
          180,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.pumpAndSettle();
        await tester.tap(find.text('利用を続ける'));
        await tester.pumpAndSettle();
        expect(find.byType(WithdrawalPage), findsNothing);
        expect(find.byType(SettingsPage), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }
  }
  testWidgets('ゲストへの直接アクセスはログイン案内', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [isLoggedInProvider.overrideWithValue(false)],
        child: MaterialApp(theme: AppTheme.light, home: const WithdrawalPage()),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(CheckboxListTile), findsNothing);
    expect(find.text('退会の確認へ'), findsNothing);
    expect(find.text('ログイン'), findsOneWidget);
  });
}
