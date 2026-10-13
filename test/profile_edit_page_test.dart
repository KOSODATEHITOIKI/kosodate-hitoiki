import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kosodate_hitoiki/core/constants/app_theme.dart';
import 'package:kosodate_hitoiki/presentation/pages/profile/profile_edit_page.dart';

void main() {
  testWidgets('短い名前を拒否し、有効な入力は未保存の案内後も保持する', (tester) async {
    await tester.pumpWidget(
      MaterialApp(theme: AppTheme.light, home: const ProfileEditPage()),
    );
    final name = find.byKey(const ValueKey('profile-nickname'));
    final save = find.byKey(const ValueKey('profile-save'));
    await tester.scrollUntilVisible(
      name,
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.enterText(name, 'あ');
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      save,
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(save);
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsNothing);
    await tester.scrollUntilVisible(
      name,
      -200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    expect(find.text('ニックネームは2〜12文字で入力してください。'), findsOneWidget);
    await tester.enterText(name, 'こもれび');
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      save,
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(save);
    await tester.pumpAndSettle();
    expect(find.text('プロフィールの保存は準備中です'), findsOneWidget);
    await tester.tap(find.text('編集に戻る'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      name,
      -200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    expect(tester.widget<TextFormField>(name).controller!.text, 'こもれび');
    expect(tester.takeException(), isNull);
  });
}
