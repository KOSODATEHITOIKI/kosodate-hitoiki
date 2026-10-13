import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_icons.dart';

/// S-02。投稿取得はIssue #7で接続する。
class HomePage extends StatefulWidget {
  const HomePage({super.key, required this.onCompose});
  final VoidCallback onCompose;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String _postType = 'すべて';

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'ひと息',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 2,
                    ),
                  ),
                  _illustration(AppDecorations.sunSmiling, 100),
                ],
              ),
              const SizedBox(height: 8),
              const Text(
                '今日も、おつかれさま。',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              const Text(
                'がんばるあなたの気持ちに、\nここでひと息つけますように。',
                style: TextStyle(fontSize: 16, height: 1.7),
              ),
              const SizedBox(height: 24),
              Center(
                child: FilledButton.icon(
                  onPressed: widget.onCompose,
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 16,
                    ),
                    shape: const StadiumBorder(),
                  ),
                  icon: SvgPicture.asset(
                    AppIcons.navCompose,
                    width: 24,
                    height: 24,
                    excludeFromSemantics: true,
                    colorFilter: const ColorFilter.mode(
                      AppColors.white,
                      BlendMode.srcIn,
                    ),
                  ),
                  label: const Text(
                    '気持ちを書く  ›',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.divider),
                ),
                child: Row(
                  children: [
                    _illustration(AppDecorations.leavesSprout, 36),
                    const SizedBox(width: 16),
                    const Expanded(
                      child: Text('話題を選ぶ', style: TextStyle(fontSize: 16)),
                    ),
                    IconButton(
                      tooltip: '話題の絞り込みは準備中です',
                      onPressed: () =>
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('話題の絞り込みは準備中です')),
                          ),
                      icon: const Icon(Icons.keyboard_arrow_down),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final type in ['すべて', 'ぐち', '相談', 'コツ・体験談'])
                    ChoiceChip(
                      label: Text(type),
                      selected: _postType == type,
                      onSelected: (_) => setState(() => _postType = type),
                      showCheckmark: false,
                      selectedColor: AppColors.primary,
                      backgroundColor: AppColors.white,
                      shape: const StadiumBorder(),
                      side: BorderSide(
                        color: _postType == type
                            ? Colors.transparent
                            : AppColors.divider,
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 8,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Column(
                  children: [
                    _illustration(AppIllustrations.emptyFeed, 160),
                    const SizedBox(height: 16),
                    const Text(
                      '投稿一覧は準備中です',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'ここに、みんなの気持ちが並びます。',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        height: 1.6,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _illustration(String asset, double size) => SvgPicture.asset(
    asset,
    width: size,
    height: size,
    excludeFromSemantics: true,
  );
}
