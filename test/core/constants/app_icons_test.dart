import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kosodate_hitoiki/core/constants/app_icons.dart';
import 'package:kosodate_hitoiki/presentation/widgets/app_asset.dart';

void main() {
  testWidgets('各カテゴリの画像アセットが読み込める', (tester) async {
    const paths = [
      AppIcons.navHome,
      AppIcons.googleG,
      AppDecorations.sunSmiling,
      AppIllustrations.welcome,
      AppAvatars.defaultSprout,
      AppReactions.empathy,
    ];

    for (final path in paths) {
      await tester.pumpWidget(MaterialApp(home: AppAsset(path)));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull, reason: '$path の読み込みに失敗');
    }
  });
}
