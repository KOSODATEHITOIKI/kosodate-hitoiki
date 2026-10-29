import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../constants/app_layout.dart';

/// パソコン向けの広い画面では、画面(投稿の詳細・設定など、あとから開く画面)を、
/// 中央の細い列に収める。画面の切り替えの動きは、もとの[inner]のまま。
/// 狭い画面(スマホ)では、何もしない。
/// パソコン向けの広い画面では、中身を、中央の細い列(背景は全面)に収める。
/// 狭い画面(スマホ)では、何もしない。
class DesktopCentered extends StatelessWidget {
  const DesktopCentered({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (!AppLayout.isDesktop(MediaQuery.sizeOf(context).width)) return child;
    return ColoredBox(
      color: AppColors.background,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: AppLayout.centerMaxWidth),
          child: child,
        ),
      ),
    );
  }
}

/// メインのシェルを開く画面の名前。これは、自分で幅を決めるので、中央の列には収めない。
const mainShellRouteName = 'main-shell';

/// 広い画面でも、画面いっぱいに使う画面(ログインなど)の経路の名前。
const fullWidthRouteName = 'full-width';

/// 広い画面でも、画面いっぱいに使う画面(ログインなど)を開く経路。
PageRoute<T> fullWidthRoute<T>({required WidgetBuilder builder}) =>
    MaterialPageRoute<T>(
      settings: const RouteSettings(name: fullWidthRouteName),
      builder: builder,
    );

/// あとから開く画面(投稿の詳細・設定など)を、広い画面では中央の列に収める[DesktopCentered]を、
/// 画面の切り替えの動き[inner]に重ねる。最初の画面(メインのシェル)は、自分で幅を決めるので除く。
class CenteredPageTransitionsBuilder extends PageTransitionsBuilder {
  const CenteredPageTransitionsBuilder(this.inner);

  final PageTransitionsBuilder inner;

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return inner.buildTransitions<T>(
      route,
      context,
      animation,
      secondaryAnimation,
      route.isFirst ||
              route.settings.name == mainShellRouteName ||
              route.settings.name == fullWidthRouteName
          ? child
          : DesktopCentered(child: child),
    );
  }
}
