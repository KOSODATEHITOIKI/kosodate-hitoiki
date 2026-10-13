import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_icons.dart';
import '../../widgets/main_navigation_shell.dart';

/// S-01 はじめての案内。未登録でもホームの閲覧に進める。
class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key});

  void _browse(BuildContext context) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(builder: (_) => const MainNavigationShell()),
    );
  }

  // S-10の実装時に認証画面への遷移に差し替える。
  void _showAuthNotice(BuildContext context, String title) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('$titleは準備中です'),
        content: const Text('登録せずに投稿を読むことができます。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('閉じる'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              _browse(context);
            },
            child: const Text('登録せずに読む'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          const Positioned.fill(child: _WelcomeBackground()),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) => SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 480),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const _WelcomeHeader(),
                            const SizedBox(height: 24),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 20,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.white,
                                borderRadius: BorderRadius.circular(24),
                              ),
                              child: const Column(
                                children: [
                                  _Guideline(
                                    asset: AppDecorations.leavesSprout,
                                    background: AppColors.surface,
                                    title: '名前や個人情報は書かない',
                                    description:
                                        '安心して気持ちを話せるように、\n個人が特定される情報は書かないでください。',
                                  ),
                                  SizedBox(height: 24),
                                  _Guideline(
                                    asset: AppDecorations.heartWarm,
                                    background: AppColors.accentPink,
                                    title: '気持ちを否定しない',
                                    description: 'どんな気持ちも、否定せずに\n受けとめ合いましょう。',
                                  ),
                                  SizedBox(height: 24),
                                  _Guideline(
                                    asset: AppDecorations.sunSmiling,
                                    background: AppColors.surface,
                                    title: '自分のペースで大丈夫',
                                    description:
                                        '見るだけでも、書くのは後でも。\nあなたのペースで使えます。',
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 24),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  DecoratedBox(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(40),
                                      boxShadow: [
                                        BoxShadow(
                                          color: AppColors.textPrimary
                                              .withValues(alpha: 0.08),
                                          blurRadius: 16,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: FilledButton(
                                      style: FilledButton.styleFrom(
                                        minimumSize: const Size.fromHeight(60),
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 24,
                                          vertical: 16,
                                        ),
                                        shape: const StadiumBorder(),
                                      ),
                                      onPressed: () =>
                                          _showAuthNotice(context, '会員登録'),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          const Flexible(
                                            child: Text(
                                              '登録してはじめる',
                                              textAlign: TextAlign.center,
                                              style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 16),
                                          SvgPicture.asset(
                                            AppIcons.next,
                                            width: 24,
                                            height: 24,
                                            excludeFromSemantics: true,
                                            colorFilter: const ColorFilter.mode(
                                              AppColors.white,
                                              BlendMode.srcIn,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  FilledButton(
                                    style: FilledButton.styleFrom(
                                      backgroundColor: AppColors.secondary,
                                      foregroundColor: AppColors.textPrimary,
                                      minimumSize: const Size.fromHeight(48),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 12,
                                      ),
                                      shape: const StadiumBorder(),
                                    ),
                                    onPressed: () => _browse(context),
                                    child: const Text(
                                      '登録せずに読む',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  Center(
                                    child: TextButton(
                                      onPressed: () =>
                                          _showAuthNotice(context, 'ログイン'),
                                      style: TextButton.styleFrom(
                                        foregroundColor: AppColors.textPrimary,
                                      ),
                                      child: const Text(
                                        'ログイン',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w700,
                                          decoration: TextDecoration.underline,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _WelcomeHeader extends StatelessWidget {
  const _WelcomeHeader();

  @override
  Widget build(BuildContext context) {
    final showDecoration = MediaQuery.textScalerOf(context).scale(1) <= 1.3;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        if (showDecoration)
          Positioned(
            top: -58,
            right: -50,
            child: ExcludeSemantics(
              child: SvgPicture.asset(
                AppDecorations.sunSmiling,
                width: 230,
                height: 230,
              ),
            ),
          ),
        Padding(
          padding: EdgeInsets.zero,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Flexible(
                    child: Text(
                      'ひと息',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                  if (showDecoration)
                    SvgPicture.asset(
                      AppDecorations.leavesSprout,
                      width: 38,
                      height: 38,
                      excludeFromSemantics: true,
                      colorFilter: const ColorFilter.mode(
                        AppColors.secondary,
                        BlendMode.srcIn,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 24),
              const Text(
                '言いづらいことも、\nここでひと息。',
                style: TextStyle(
                  fontSize: 24,
                  height: 1.4,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                '子育ての気持ちを、\n安心して書ける場所です。',
                style: TextStyle(fontSize: 16, height: 1.65),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Guideline extends StatelessWidget {
  const _Guideline({
    required this.asset,
    required this.background,
    required this.title,
    required this.description,
  });

  final String asset;
  final Color background;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 54,
          height: 54,
          decoration: BoxDecoration(color: background, shape: BoxShape.circle),
          child: SvgPicture.asset(asset, excludeFromSemantics: true),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                description,
                style: const TextStyle(
                  fontSize: 16,
                  height: 1.7,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _WelcomeBackground extends StatelessWidget {
  const _WelcomeBackground();

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: IgnorePointer(
        child: Stack(
          clipBehavior: Clip.hardEdge,
          children: [
            Positioned(top: 120, right: -105, child: _cloud(300)),
            Positioned(top: 200, left: -150, child: _cloud(280)),
            Positioned(bottom: -120, left: -120, child: _cloud(360)),
            Positioned(bottom: -110, right: -115, child: _cloud(360)),
            Positioned(
              bottom: -10,
              left: -12,
              child: SvgPicture.asset(
                AppDecorations.leavesSprout,
                width: 110,
                height: 110,
              ),
            ),
            Positioned(
              bottom: -12,
              right: -4,
              child: SvgPicture.asset(
                AppDecorations.leavesSprout,
                width: 120,
                height: 120,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _cloud(double size) =>
      SvgPicture.asset(AppDecorations.cloudSoft, width: size, height: size);
}
