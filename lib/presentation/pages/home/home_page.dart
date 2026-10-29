import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kosodate_hitoiki/presentation/widgets/app_asset.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_brand.dart';
import '../../../core/constants/app_icons.dart';
import '../../../core/utils/accessibility.dart';
import '../../../domain/models/post.dart';
import '../../providers/post_providers.dart';
import '../../widgets/load_more_button.dart';
import '../../widgets/post_card.dart';
import '../../widgets/topic_picker.dart';
import '../support/support_resources_page.dart';

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
    // 投稿が増えても画面外のカードは構築しないよう、遅延構築のListViewにする。
    final items = <Widget>[
      const _HomeHeader(),
      Align(
        alignment: Alignment.centerRight,
        child: TextButton.icon(
          onPressed: () => Navigator.of(context).push<void>(
            MaterialPageRoute(builder: (_) => const SupportResourcesPage()),
          ),
          icon: const Icon(Icons.support_agent, size: 18),
          label: const Text('困ったときの相談先', style: TextStyle(fontSize: 12)),
        ),
      ),
      const SizedBox(height: 24),
      Center(
        child: FilledButton.icon(
          onPressed: widget.onCompose,
          style: FilledButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            shape: const StadiumBorder(),
          ),
          icon: AppAsset(
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
            style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700),
          ),
        ),
      ),
      const SizedBox(height: 24),
      TopicFilterRow(
        selected: ref.watch(feedTopicProvider),
        onChanged: (topic) =>
            ref.read(feedTopicProvider.notifier).state = topic,
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
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
            ),
        ],
      ),
      const SizedBox(height: 24),
      if (ref.watch(postsAreSampleProvider)) ...[
        const Text(
          'サンプル投稿です。保存状態はアプリ終了時にリセットされます。',
          style: TextStyle(fontSize: 11, height: 1.6),
        ),
        const SizedBox(height: 12),
      ],
      ..._buildFeed(),
    ];
    return SafeArea(
      bottom: false,
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
            itemCount: items.length,
            itemBuilder: (context, index) => items[index],
          ),
        ),
      ),
    );
  }

  Widget _illustration(String asset, double size) =>
      AppAsset(asset, width: size, height: size, excludeFromSemantics: true);

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
          return [
            _emptyFeedCard(
              ref.watch(postsAreSampleProvider)
                  ? '投稿一覧は準備中です'
                  : (ref.watch(feedTopicProvider) != null
                        ? 'この話題の投稿は、まだありません'
                        : 'まだ投稿がありません'),
            ),
            // 絞り込みで空でも、次のページに該当があるかもしれない。
            LoadMoreButton(provider: feedPostsProvider),
          ];
        }
        return [
          for (final post in filtered) ...[
            PostCard(post: post),
            const SizedBox(height: 12),
          ],
          LoadMoreButton(provider: feedPostsProvider),
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
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
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

/// 確定デザインS-02と同じ、大きな太陽+葉のアクセントを使う見出し。
class _HomeHeader extends StatelessWidget {
  const _HomeHeader();

  @override
  Widget build(BuildContext context) {
    final showDecoration = fitsDecoration(context);
    final logoWidth = (MediaQuery.sizeOf(context).width * 0.36).clamp(
      110.0,
      150.0,
    );
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
                child: AppAsset(
                  AppDecorations.cloudSoft,
                  width: 150,
                  height: 150,
                ),
              ),
            ),
          ),
          Positioned(
            top: -36,
            right: -50,
            child: ExcludeSemantics(
              child: AppAsset(
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
                          width: logoWidth,
                          // 原画像(1922px)を表示サイズでデコードして軽くする。
                          cacheWidth:
                              (logoWidth *
                                      MediaQuery.devicePixelRatioOf(context))
                                  .ceil(),
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
                          fontSize: 24,
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
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 16),
            const Text(
              'がんばるあなたの気持ちに、\nここでひと息つけますように。',
              style: TextStyle(fontSize: 12.5, height: 1.7),
            ),
          ],
        ),
      ],
    );
  }
}
