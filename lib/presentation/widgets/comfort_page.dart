import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_icons.dart';
import '../../core/utils/accessibility.dart';

/// タブ画面共通の装飾とスクロール領域。
class ComfortPage extends StatelessWidget {
  const ComfortPage({
    super.key,
    required this.title,
    required this.message,
    required this.children,
  });
  final String title;
  final String message;
  final List<Widget> children;
  @override
  Widget build(BuildContext context) => SafeArea(
    bottom: false,
    child: Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
          children: [
            _ComfortHeader(title: title, message: message),
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
  const _ComfortHeader({required this.title, required this.message});
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    final showDecoration = fitsDecoration(context);
    final leafSize = (MediaQuery.sizeOf(context).width * 0.25).clamp(90.0, 110.0);
    return Stack(
      clipBehavior: Clip.none,
      children: [
        if (showDecoration) SizedBox(height: 90 + leafSize),
        if (showDecoration) ...[
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
          Positioned(
            top: 90,
            right: -6,
            child: ExcludeSemantics(
              child: SvgPicture.asset(
                AppDecorations.leavesTall,
                width: leafSize,
                height: leafSize,
              ),
            ),
          ),
        ],
        Padding(
          padding: const EdgeInsets.only(right: 90),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Flexible(
                    child: Text(
                      title,
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  if (showDecoration) SizedBox(height: 90 + leafSize),
        if (showDecoration) ...[
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
              const SizedBox(height: 8),
              Text(
                message,
                style: const TextStyle(fontSize: 17, height: 1.7),
              ),
            ],
          ),
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
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 14, height: 1.7),
        ),
      ],
    ),
  );
}
