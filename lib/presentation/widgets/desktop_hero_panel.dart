import 'package:flutter/material.dart';

import '../../core/constants/app_brand.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_icons.dart';
import 'app_asset.dart';

/// パソコン向けの広い画面の、ログイン・案内画面の左側の絵の面。
/// ロゴ・言葉・大きな太陽と、草と雲の飾り。操作はない(読み上げには、ロゴと言葉だけを出す)。
class DesktopHeroPanel extends StatelessWidget {
  const DesktopHeroPanel({super.key});

  @override
  Widget build(BuildContext context) => ColoredBox(
    color: AppColors.surface.withValues(alpha: 0.55),
    child: Stack(
      children: [
        // 下の雲と、左右の草(いちばん後ろ)。
        const Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: ExcludeSemantics(
            child: IgnorePointer(
              child: AppAsset(
                AppDecorations.cloudsBottom,
                excludeFromSemantics: true,
              ),
            ),
          ),
        ),
        const Positioned(
          left: 0,
          bottom: 0,
          child: ExcludeSemantics(
            child: IgnorePointer(
              child: SizedBox(
                width: 200,
                child: AppAsset(
                  AppDecorations.cornerLeavesLeft,
                  excludeFromSemantics: true,
                ),
              ),
            ),
          ),
        ),
        const Positioned(
          right: 0,
          bottom: 0,
          child: ExcludeSemantics(
            child: IgnorePointer(
              child: SizedBox(
                width: 200,
                child: AppAsset(
                  AppDecorations.cornerLeavesRight,
                  excludeFromSemantics: true,
                ),
              ),
            ),
          ),
        ),
        SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const AppAsset(
                    AppBrand.logo,
                    width: 220,
                    semanticsLabel: 'ひと息',
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    '言いづらいことも、\nここでひと息。',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 28,
                      height: 1.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    '子育ての気持ちを、\n安心して書ける場所です。',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14.5, height: 1.8),
                  ),
                  const SizedBox(height: 32),
                  const ExcludeSemantics(
                    child: AppAsset(
                      AppDecorations.sunSmiling,
                      width: 240,
                      height: 240,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    ),
  );
}

/// 広い画面の案内・ログイン画面の、左に絵の面、右に[right]の2分割。
/// 窓をどれだけ広げても、分割の全体は、最大の幅[maxWidth]で止めて、中央に置く
/// (幅が足りるときは、上下左右に余白をとって、角の丸いカードにする)。
class DesktopHeroSplit extends StatelessWidget {
  const DesktopHeroSplit({super.key, required this.right});

  /// 右側(約束・ボタンや、フォーム)。
  final Widget right;

  /// 2分割の全体の最大の幅。
  static const maxWidth = 1200.0;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final split = Row(
        children: [
          const Expanded(flex: 11, child: DesktopHeroPanel()),
          Expanded(flex: 9, child: right),
        ],
      );
      // 窓が最大の幅を超えるときだけ、余白のあるカードにする。
      final floating = constraints.maxWidth > maxWidth;
      return ColoredBox(
        color: AppColors.background,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: maxWidth),
            child: floating
                ? Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(32),
                      child: split,
                    ),
                  )
                : split,
          ),
        ),
      );
    },
  );
}
