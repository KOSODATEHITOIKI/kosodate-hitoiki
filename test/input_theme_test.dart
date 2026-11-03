import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kosodate_hitoiki/core/constants/app_colors.dart';
import 'package:kosodate_hitoiki/core/constants/app_theme.dart';

void main() {
  final theme = AppTheme.light;
  final decoration = theme.inputDecorationTheme;

  test('入力中(フォーカス)の枠と文字は、エラーに見えるコーラルにしない', () {
    final border = decoration.focusedBorder! as OutlineInputBorder;
    expect(border.borderSide.color, AppColors.textPrimary);
    expect(border.borderSide.color, isNot(AppColors.primary));

    final focusedLabel = WidgetStateProperty.resolveAs<TextStyle?>(
      decoration.floatingLabelStyle,
      {WidgetState.focused},
    );
    expect(focusedLabel?.color, AppColors.textPrimary);
  });

  test('入力欄の下の案内・エラーは、省略せず折り返して全部見せる', () {
    expect(decoration.helperMaxLines, greaterThan(1));
    expect(decoration.errorMaxLines, greaterThan(1));
  });

  testWidgets('長いメールの案内が、「…」で省略されず最後まで表示される', (tester) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    const message = '「@」のあとは、「example.com」のように「.」でつないで入力してください。';
    await tester.pumpWidget(
      MaterialApp(
        theme: theme,
        home: const Scaffold(
          body: Padding(
            padding: EdgeInsets.all(16),
            child: TextField(
              decoration: InputDecoration(
                labelText: 'メールアドレス',
                helperText: message,
              ),
            ),
          ),
        ),
      ),
    );
    // 1行に収まらない長さの文が、2行以上で表示されている(省略されていない)。
    final text = tester.widget<Text>(find.text(message));
    expect(text.maxLines, greaterThan(1));
    expect(tester.getSize(find.text(message)).height, greaterThan(30));
  });

  test('エラーのときは、枠も文字も赤のまま', () {
    final errorLabel = WidgetStateProperty.resolveAs<TextStyle?>(
      decoration.floatingLabelStyle,
      {WidgetState.focused, WidgetState.error},
    );
    expect(errorLabel?.color, theme.colorScheme.error);
    // エラー枠は、テーマ未指定でcolorScheme.error(赤)が使われる。
    expect(decoration.errorBorder, isNull);
  });
}
