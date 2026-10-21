import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kosodate_hitoiki/presentation/providers/auth_provider.dart';
import 'package:kosodate_hitoiki/core/constants/app_theme.dart';
import 'package:kosodate_hitoiki/presentation/pages/auth/legal_document_page.dart';
import 'package:kosodate_hitoiki/presentation/pages/settings/settings_page.dart';

void main() {
  testWidgets('利用ガイドを開いて戻り、退会はゲストにログイン案内を表示する', (tester) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [isLoggedInProvider.overrideWithValue(false)],
        child: MaterialApp(
          theme: AppTheme.light,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: const TextScaler.linear(1.5)),
            child: child!,
          ),
          home: const SettingsPage(),
        ),
      ),
    );
    await tester.scrollUntilVisible(
      find.text('利用ガイド'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('利用ガイド'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('利用ガイド'));
    await tester.pumpAndSettle();
    expect(find.byType(UsageGuidePage), findsOneWidget);
    expect(find.text('名前や個人情報は書かない'), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('退会'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('退会'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('退会'));
    await tester.pumpAndSettle();
    expect(find.text('ログイン'), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.byType(SettingsPage), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  for (final title in ['利用規約', 'プライバシーポリシー']) {
    testWidgets('$titleを開いて読める(同意の操作は出さない)', (tester) async {
      tester.view.physicalSize = const Size(390, 1600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [isLoggedInProvider.overrideWithValue(false)],
          child: MaterialApp(theme: AppTheme.light, home: const SettingsPage()),
        ),
      );
      await tester.ensureVisible(find.text(title));
      await tester.pumpAndSettle();
      // 残る「準備中」は、お問い合わせだけ。
      expect(find.text('準備中'), findsOneWidget);
      await tester.tap(find.text(title));
      await tester.pumpAndSettle();
      expect(find.byType(LegalDocumentPage), findsOneWidget);
      expect(find.byKey(const ValueKey('legal-done')), findsNothing);
      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(find.byType(SettingsPage), findsOneWidget);
    });
  }
}
