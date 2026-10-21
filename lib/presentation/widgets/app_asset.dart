import 'package:flutter/widgets.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// アプリ同梱の画像アセットを表示する。拡張子で描画方法を切り替える。
///
/// - `.svg`: アイコンなど軽いベクター画像。`flutter_svg`で描画する。
/// - `.png`: 水彩風イラストなどパス数の多い画像。SVGのまま出すと解析・描画が
///   重いため、事前にラスタライズしたPNGを使う(`tool/rasterize_heavy_svgs_test.dart`)。
class AppAsset extends StatelessWidget {
  const AppAsset(
    this.asset, {
    super.key,
    this.width,
    this.height,
    this.excludeFromSemantics = false,
    this.semanticsLabel,
    this.colorFilter,
  });

  final String asset;
  final double? width;
  final double? height;
  final bool excludeFromSemantics;
  final String? semanticsLabel;

  /// SVGにのみ適用する。PNGは色を変えない前提。
  final ColorFilter? colorFilter;

  @override
  Widget build(BuildContext context) {
    if (asset.endsWith('.svg')) {
      return SvgPicture.asset(
        asset,
        width: width,
        height: height,
        excludeFromSemantics: excludeFromSemantics,
        semanticsLabel: semanticsLabel,
        colorFilter: colorFilter,
      );
    }
    // 表示サイズを超える解像度でデコードしない(メモリとデコード時間の節約)。
    final pixelRatio = MediaQuery.devicePixelRatioOf(context);
    return Image.asset(
      asset,
      width: width,
      height: height,
      cacheWidth: width == null ? null : (width! * pixelRatio).ceil(),
      excludeFromSemantics: excludeFromSemantics,
      semanticLabel: semanticsLabel,
      filterQuality: FilterQuality.medium,
    );
  }
}
