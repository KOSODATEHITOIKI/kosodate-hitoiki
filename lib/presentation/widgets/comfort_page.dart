import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_icons.dart';

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
            Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                SvgPicture.asset(
                  AppDecorations.sunSmiling,
                  width: 96,
                  height: 96,
                  excludeFromSemantics: true,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(message, style: const TextStyle(fontSize: 17, height: 1.7)),
            const SizedBox(height: 28),
            ...children,
          ],
        ),
      ),
    ),
  );
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
