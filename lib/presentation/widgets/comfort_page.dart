import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_brand.dart';
import '../../core/constants/app_icons.dart';
import '../../core/utils/accessibility.dart';

/// タブ画面共通の装飾とスクロール領域。
class ComfortPage extends StatelessWidget {
  const ComfortPage({
    super.key,
    required this.title,
    required this.message,
    required this.children,
    this.useBrandLogo = false,
    this.headerIllustration,
    this.horizontalPadding = 20,
    this.messageFontSize = 14,
    this.subtitle,
  });
  final String title;
  final String message;
  final List<Widget> children;
  final bool useBrandLogo;
  final String? headerIllustration;
  final double horizontalPadding;
  final double messageFontSize;
  final String? subtitle;
  @override
  Widget build(BuildContext context) => SafeArea(
    bottom: false,
    child: Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600),
        child: ListView(
          padding: EdgeInsets.fromLTRB(
            horizontalPadding,
            20,
            horizontalPadding,
            32,
          ),
          children: [
            _ComfortHeader(
              title: title,
              message: message,
              useBrandLogo: useBrandLogo,
              illustration: headerIllustration,
              messageFontSize: messageFontSize,
              subtitle: subtitle,
            ),
            const SizedBox(height: 28),
            ...children,
          ],
        ),
      ),
    ),
  );
}

/// docs/design のS-02/S-04〜S-07/S-11共通の見出し(大きな太陽+葉のアクセント)。
class _ComfortHeader extends StatelessWidget {
  const _ComfortHeader({
    required this.title,
    required this.message,
    required this.useBrandLogo,
    this.illustration,
    required this.messageFontSize,
    this.subtitle,
  });
  final String title;
  final String message;
  final bool useBrandLogo;
  final String? illustration;
  final double messageFontSize;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final showDecoration = fitsDecoration(context);
    final illustrationSize = (MediaQuery.sizeOf(context).width * 0.6).clamp(
      180.0,
      240.0,
    );
    return Stack(
      clipBehavior: Clip.none,
      children: [
        if (showDecoration)
          SizedBox(
            height: illustration == null ? 154.0 : illustrationSize * 0.85,
          ),
        if (showDecoration && illustration != null)
          Positioned(
            top: -16,
            right: -20,
            child: ExcludeSemantics(
              child: IgnorePointer(
                child: SvgPicture.asset(
                  illustration!,
                  width: illustrationSize,
                  height: illustrationSize,
                ),
              ),
            ),
          ),
        if (showDecoration && illustration == null)
          Positioned(
            top: -36,
            right: -50,
            child: ExcludeSemantics(
              child: SvgPicture.asset(
                AppDecorations.sunSmiling,
                width: 190,
                height: 190,
              ),
            ),
          ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.only(
                right: useBrandLogo ? (showDecoration ? 72 : 0) : 90,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (useBrandLogo && showDecoration)
                    Flexible(
                      child: Semantics(
                        label: title,
                        header: true,
                        child: Image.asset(
                          AppBrand.logo,
                          width: (MediaQuery.sizeOf(context).width * 0.42)
                              .clamp(134.0, 180.0),
                          fit: BoxFit.contain,
                          alignment: Alignment.centerLeft,
                          excludeFromSemantics: true,
                        ),
                      ),
                    )
                  else
                    Flexible(
                      child: Text(
                        title,
                        style: const TextStyle(
                          fontSize: 27,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  if (showDecoration && !useBrandLogo) ...[
                    const SizedBox(width: 4),
                    SvgPicture.asset(
                      AppDecorations.leavesSprout,
                      width: 28,
                      height: 28,
                      excludeFromSemantics: true,
                      colorFilter: const ColorFilter.mode(
                        AppColors.secondary,
                        BlendMode.srcIn,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 8),
              Text(
                subtitle!,
                style: const TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
            const SizedBox(height: 16),
            Text(
              message,
              style: TextStyle(fontSize: messageFontSize, height: 1.7),
            ),
          ],
        ),
      ],
    );
  }
}

class ComfortNotice extends StatelessWidget {
  const ComfortNotice({
    super.key,
    required this.asset,
    required this.title,
    required this.message,
  });
  final String asset;
  final String title;
  final String message;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(24),
    decoration: BoxDecoration(
      color: AppColors.white,
      borderRadius: BorderRadius.circular(24),
    ),
    child: Column(
      children: [
        SvgPicture.asset(
          asset,
          width: 144,
          height: 144,
          excludeFromSemantics: true,
        ),
        const SizedBox(height: 16),
        Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 12.5, height: 1.7),
        ),
      ],
    ),
  );
}
