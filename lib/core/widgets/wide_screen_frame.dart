import 'package:flutter/material.dart';

import '../constants/app_colors.dart';

/// 少し広い画面(横向きのスマホ・縦向きのタブレットなど)では、中身を中央の細い列に収める。
/// 狭い画面(スマホ)と、パソコン向けの広い画面(1024px以上)では、何もしない。幅の上限だけを決め、高さや文字の大きさは変えない。
class WideScreenFrame extends StatelessWidget {
  const WideScreenFrame({super.key, required this.child});

  /// この幅より広いときだけ、列に収める。
  static const breakpoint = 640.0;

  /// この幅以上は、パソコン向け(左メニューと、中央・右の3列)。ここでは列に収めず、
  /// 画面側(メインのシェル)が幅を決める。
  static const desktopBreakpoint = 1024.0;

  /// 列の最大の幅。
  static const maxWidth = 560.0;

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width <= breakpoint || width >= desktopBreakpoint) return child;
    return ColoredBox(
      color: AppColors.background,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: maxWidth),
          child: child,
        ),
      ),
    );
  }
}
