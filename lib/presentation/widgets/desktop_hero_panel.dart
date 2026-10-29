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
