import 'package:flutter/material.dart';

import '../constants/app_colors.dart';

/// 広い画面(パソコン・横向きのタブレットなど)では、中身を中央の細い列に収める。
/// 狭い画面(スマホ)では、何もしない。幅の上限だけを決め、高さや文字の大きさは変えない。
class WideScreenFrame extends StatelessWidget {
  const WideScreenFrame({super.key, required this.child});

  /// この幅より広いときだけ、列に収める。
  static const breakpoint = 640.0;

  /// 列の最大の幅。
  static const maxWidth = 560.0;

  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.sizeOf(context).width <= breakpoint) return child;
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
