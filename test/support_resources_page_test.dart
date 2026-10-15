import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kosodate_hitoiki/core/constants/app_theme.dart';
import 'package:kosodate_hitoiki/presentation/pages/settings/settings_page.dart';
import 'package:kosodate_hitoiki/presentation/pages/support/support_resources_page.dart';

void main() {
  for (final scale in [1.0, 2.0]) {
    testWidgets('ログインなし・320px文字$scaleで3つの公式URLを開く', (tester) async {
      tester.view.physicalSize = const Size(320, 700);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final opened = <Uri>[];
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: TextScaler.linear(scale)),
            child: child!,
          ),
          home: SupportResourcesPage(
            openLink: (uri) async {
              opened.add(uri);
              return true;
            },
          ),
        ),
      );
      await tester.pumpAndSettle();
      for (final title in [
        '親子のための相談LINEの公式ページ',
        'まもろうよ こころの公式ページ',
        '児童相談所虐待対応ダイヤル 189の公式ページ',
      ]) {
        await tester.scrollUntilVisible(
          find.text(title),
          160,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.pumpAndSettle();
        await tester.tap(find.text(title));
        await tester.pumpAndSettle();
      }
      expect(opened, [
        Uri.parse('https://www.cfa.go.jp/policies/jidougyakutai/oyako-line/'),
        Uri.parse('https://www.mhlw.go.jp/mamorouyokokoro/'),
        Uri.parse(
          'https://www.cfa.go.jp/policies/jidougyakutai/gyakutai-taiou-dial/',
        ),
      ]);
      expect(tester.takeException(), isNull);
    });
  }
  for (final throwsError in [false, true]) {
    testWidgets('公式ページの起動失敗時にURLを表示（例外=$throwsError）', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: SupportResourcesPage(
            openLink: (_) async {
              if (throwsError) throw StateError('no browser');
              return false;
            },
          ),
        ),
      );
      await tester.pumpAndSettle();
      final target = find.text('親子のための相談LINEの公式ページ');
      await tester.scrollUntilVisible(
        target,
        160,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      await tester.tap(target);
      await tester.pumpAndSettle();
      expect(find.text('公式ページを開けませんでした'), findsOneWidget);
      expect(find.byType(SelectableText), findsOneWidget);
      expect(
        tester.widget<SelectableText>(find.byType(SelectableText)).data,
        SupportResourcesPage.parentLineUrl.toString(),
      );
      expect(tester.takeException(), isNull);
    });
  }
  testWidgets('設定からログインなしで相談先を開き戻れる', (tester) async {
    await tester.pumpWidget(
      MaterialApp(theme: AppTheme.light, home: const SettingsPage()),
    );
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('困ったときの相談先'),
      160,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('困ったときの相談先'));
    await tester.pumpAndSettle();
    expect(find.byType(SupportResourcesPage), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.byType(SettingsPage), findsOneWidget);
  });
}
