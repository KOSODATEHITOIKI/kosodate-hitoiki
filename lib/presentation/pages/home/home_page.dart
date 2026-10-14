import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_brand.dart';
import '../../../core/constants/app_icons.dart';
import '../../../core/utils/accessibility.dart';
import '../../../domain/models/post.dart';
import '../../providers/post_providers.dart';
import '../../widgets/post_card.dart';

/// S-02。投稿取得(Issue #7)はMockPostRepositoryで仮接続済み。
/// バックエンド実装後はpostRepositoryProviderの差し替えのみで切り替わる。
class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key, required this.onCompose});
  final VoidCallback onCompose;

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  String _postType = 'すべて';

  static const _typeByLabel = {
    'ぐち': PostType.grumble,
    '相談': PostType.consult,
    'コツ・体験談': PostType.tips,
  };

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
            children: [
              const _HomeHeader(),
              const SizedBox(height: 24),
              _ComposeBackdrop(
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
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
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
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text('話題を選ぶ', style: TextStyle(fontSize: 13.5)),
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
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final type in ['すべて', 'ぐち', '相談', 'コツ・体験談'])
                    ChoiceChip(
                      label: Text(type, maxLines: 1, softWrap: false),
                      labelStyle: const TextStyle(fontSize: 12),
                      labelPadding: const EdgeInsets.symmetric(horizontal: 6),
                      selected: _postType == type,
                      onSelected: (_) => setState(() => _postType = type),
                      showCheckmark: false,
                      selectedColor: AppColors.secondary,
                      backgroundColor: AppColors.white,
                      shape: const StadiumBorder(),
                      side: BorderSide(
                        color: _postType == type
                            ? Colors.transparent
                            : AppColors.divider,
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 4,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 24),
              const Text(
                'サンプル投稿です。保存状態はアプリ終了時にリセットされます。',
                style: TextStyle(fontSize: 11, height: 1.6),
              ),
              const SizedBox(height: 12),
              ..._buildFeed(),
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

  List<Widget> _buildFeed() {
    final feed = ref.watch(feedPostsProvider);
    return feed.when(
      loading: () => const [
        Padding(
          padding: EdgeInsets.symmetric(vertical: 32),
          child: Center(child: CircularProgressIndicator()),
        ),
      ],
      error: (error, stackTrace) => [_emptyFeedCard('投稿の取得に失敗しました')],
      data: (posts) {
        final filtered = _postType == 'すべて'
            ? posts
            : posts
                  .where((post) => post.type == _typeByLabel[_postType])
                  .toList();
        if (filtered.isEmpty) {
          return [_emptyFeedCard('投稿一覧は準備中です')];
        }
        return [
          for (final post in filtered) ...[
            PostCard(
              post: post,
              onToggleSaved: () => ref
                  .read(postRepositoryProvider)
                  .toggleSaved(post.id)
                  .then((_) {
                    if (!mounted) return;
                    ref.invalidate(feedPostsProvider);
                    ref.invalidate(searchResultsProvider);
                    ref.invalidate(myPostsProvider);
                    ref.invalidate(savedPostsProvider);
                  }),
            ),
            const SizedBox(height: 12),
          ],
        ];
      },
    );
  }

  Widget _emptyFeedCard(String title) => Container(
    padding: const EdgeInsets.all(24),
    decoration: BoxDecoration(
      color: AppColors.white,
      borderRadius: BorderRadius.circular(24),
    ),
    child: Column(
      children: [
        _illustration(AppIllustrations.emptyFeed, 160),
        const SizedBox(height: 16),
        Text(
          title,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        const Text(
          'ここに、みんなの気持ちが並びます。',
          textAlign: TextAlign.center,
          style: TextStyle(color: AppColors.textSecondary, height: 1.6),
        ),
      ],
    ),
  );
}

/// ボタンの背後に草と雲を配置し、操作・読み上げを遮らない。
class _ComposeBackdrop extends StatelessWidget {
  const _ComposeBackdrop({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final showDecoration = fitsDecoration(context);
      final cloudSize = (constraints.maxWidth * 0.52).clamp(140.0, 230.0);
      return Stack(
        clipBehavior: Clip.hardEdge,
        children: [
          if (showDecoration)
            Positioned.fill(
              child: ExcludeSemantics(
                child: IgnorePointer(
                  child: Stack(
                    children: [
                      Positioned(
                        left: -cloudSize * 0.35,
                        bottom: -cloudSize * 0.4,
                        child: _whiteCloud(cloudSize),
                      ),
                      Positioned(
                        right: -cloudSize * 0.25,
                        bottom: -cloudSize * 0.35,
                        child: _whiteCloud(cloudSize),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Center(child: child),
          ),
        ],
      );
    },
  );

  Widget _whiteCloud(double size) => ColorFiltered(
    colorFilter: ColorFilter.mode(
      AppColors.white.withValues(alpha: 0.7),
      BlendMode.srcATop,
    ),
    child: SvgPicture.asset(
      AppDecorations.cloudSoft,
      width: size,
      height: size,
    ),
  );
}

/// docs/design S-02と同じ、大きな太陽+葉のアクセントを使う見出し。
class _HomeHeader extends StatelessWidget {
  const _HomeHeader();

  @override
  Widget build(BuildContext context) {
    final showDecoration = fitsDecoration(context);
    return Stack(
      clipBehavior: Clip.none,
      children: [
        if (showDecoration) const SizedBox(height: 154),
        if (showDecoration) ...[
          Positioned(
            top: 30,
            right: -40,
            child: ExcludeSemantics(
              child: IgnorePointer(
                child: ColorFiltered(
                  colorFilter: ColorFilter.mode(
                    AppColors.white.withValues(alpha: 0.7),
                    BlendMode.srcATop,
                  ),
                  child: SvgPicture.asset(
                    AppDecorations.cloudSoft,
                    width: 150,
                    height: 150,
                  ),
                ),
              ),
            ),
          ),
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
        ],
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.only(right: showDecoration ? 72 : 0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (showDecoration)
                    Flexible(
                      child: Semantics(
                        label: 'ひと息',
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
                    const Flexible(
                      child: Text(
                        'ひと息',
                        style: TextStyle(
                          fontSize: 27,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 2,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              '今日も、おつかれさま。',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 16),
            const Text(
              'がんばるあなたの気持ちに、\nここでひと息つけますように。',
              style: TextStyle(fontSize: 13.5, height: 1.7),
            ),
          ],
        ),
      ],
    );
  }
}
