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
