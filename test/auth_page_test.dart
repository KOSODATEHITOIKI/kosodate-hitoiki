import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kosodate_hitoiki/core/constants/app_theme.dart';
import 'package:kosodate_hitoiki/presentation/pages/auth/auth_page.dart';

void main() {
  testWidgets('ログインの入力検証とパスワード表示切替、未送信の案内', (tester) async {
    await tester.pumpWidget(
      MaterialApp(theme: AppTheme.light, home: const AuthPage()),
    );
    await tester.ensureVisible(find.byKey(const ValueKey('auth-submit')));
    await tester.tap(find.byKey(const ValueKey('auth-submit')));
    await tester.pumpAndSettle();
    expect(find.text('メールアドレスを確認してください。'), findsOneWidget);
    expect(find.text('パスワードを入力してください。'), findsOneWidget);
    await tester.enterText(
      find.byKey(const ValueKey('auth-email')),
      'a@example.com',
    );
    await tester.enterText(
      find.byKey(const ValueKey('auth-password')),
      'password123',
    );
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byTooltip('パスワードを表示'));
    await tester.tap(find.byTooltip('パスワードを表示'));
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<TextFormField>(find.byKey(const ValueKey('auth-password')))
          .controller!
          .text,
      'password123',
    );
    expect(find.byTooltip('パスワードを隠す'), findsOneWidget);
    await tester.ensureVisible(find.byKey(const ValueKey('auth-submit')));
    await tester.tap(find.byKey(const ValueKey('auth-submit')));
    await tester.pumpAndSettle();
    expect(find.text('ログインは準備中です'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets('小さい画面・文字拡大で登録と再設定へ移動できる', (tester) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: const TextScaler.linear(1.5)),
          child: child!,
        ),
        home: const AuthPage(),
      ),
    );
    await tester.ensureVisible(find.text('会員登録へ'));
    await tester.tap(find.text('会員登録へ'));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('auth-nickname')), findsOneWidget);
    expect(find.byType(CheckboxListTile), findsOneWidget);
    await tester.ensureVisible(find.text('ログインへ'));
    await tester.tap(find.text('ログインへ'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('パスワードを忘れた方'));
    await tester.tap(find.text('パスワードを忘れた方'));
    await tester.pumpAndSettle();
    expect(find.text('パスワード再設定'), findsOneWidget);
    expect(find.byKey(const ValueKey('auth-password')), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
