import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:kosodate_hitoiki/app.dart';

void main() {
  testWidgets('ボトムナビゲーションの5タブが表示される', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: App()));
    await tester.ensureVisible(find.text('登録せずに読む'));
    await tester.tap(find.text('登録せずに読む'));
    await tester.pumpAndSettle();

    final navBar = find.byType(NavigationBar);
    expect(navBar, findsOneWidget);

    for (final label in ['ホーム', '検索', '書く', 'お知らせ', 'マイページ']) {
      expect(
        find.descendant(of: navBar, matching: find.text(label)),
        findsOneWidget,
      );
    }
  });

  testWidgets('ホームの投稿ボタンから書くタブへ移動できる', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: App()));
    await tester.ensureVisible(find.text('登録せずに読む'));
    await tester.tap(find.text('登録せずに読む'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('気持ちを書く  ›'));
    await tester.pumpAndSettle();

    expect(
      tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex,
      2,
    );
    expect(find.text('投稿作成(未実装)'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
