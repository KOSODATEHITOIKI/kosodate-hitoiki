import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_icons.dart';
import '../../domain/models/topic.dart';
import '../pages/settings/settings_page.dart';
import '../pages/support/support_resources_page.dart';
import '../providers/post_providers.dart';
import 'app_asset.dart';

/// パソコン向けの広い画面の、ホームの上の大きな見出しの帯。
/// 太陽・雲・草の絵の上に、あいさつを置く。
class DesktopHomeBanner extends StatelessWidget {
  const DesktopHomeBanner({super.key});

  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(24),
    child: DecoratedBox(
      decoration: const BoxDecoration(color: AppColors.surface),
      child: SizedBox(
        height: 188,
        child: Stack(
          children: [
            const Positioned(
              right: -24,
              bottom: -28,
              child: ExcludeSemantics(
                child: IgnorePointer(
                  child: AppAsset(AppDecorations.cloudSoft, width: 260),
                ),
              ),
            ),
            const Positioned(
              left: 0,
              bottom: 0,
              child: ExcludeSemantics(
                child: IgnorePointer(
                  child: AppAsset(AppDecorations.cornerLeavesLeft, width: 120),
                ),
              ),
            ),
            const Positioned(
              right: 8,
              top: -8,
              child: ExcludeSemantics(
                child: AppAsset(AppDecorations.sunSmiling, width: 190),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(112, 32, 200, 24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Semantics(
                    header: true,
                    child: const Text(
                      '今日も、おつかれさま。',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        height: 1.4,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'がんばるあなたの気持ちに、\nここでひと息つけますように。',
                    style: TextStyle(fontSize: 14, height: 1.8),
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

/// パソコン向けの広い画面の、ホームの右の補足のカード(3枚)。
/// 「話題から探す」は、人気順ではなく、運営が用意した話題を決まった順で並べる。
class DesktopHomeSidePanel extends ConsumerWidget {
  const DesktopHomeSidePanel({super.key, required this.openPage});

  /// 利用ガイド・相談先の画面を開く(中央の枠の中で開くため、呼び出し側が決める)。
  final void Function(Widget page) openPage;

  /// 右のカードに並べる話題の最大の数。
  static const maxTopics = 6;

  @override
  Widget build(BuildContext context, WidgetRef ref) => SingleChildScrollView(
    padding: const EdgeInsets.only(top: 20, bottom: 32),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _PaceCard(),
        const SizedBox(height: 16),
        _TopicsCard(
          selected: ref.watch(feedTopicProvider),
          onSelected: (topic) =>
              ref.read(feedTopicProvider.notifier).state = topic,
          topics: ref.watch(topicsProvider),
        ),
        const SizedBox(height: 16),
        _SafetyCard(
          onGuide: () => openPage(const UsageGuidePage()),
          onSupport: () => openPage(const SupportResourcesPage()),
        ),
      ],
    ),
  );
}

class _Card extends StatelessWidget {
  const _Card({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: AppColors.white,
      borderRadius: BorderRadius.circular(24),
    ),
    child: child,
  );
}

class _PaceCard extends StatelessWidget {
  const _PaceCard();

  @override
  Widget build(BuildContext context) => _Card(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Center(
          child: ExcludeSemantics(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                AppAsset(AppDecorations.leavesSprout, width: 72, height: 72),
                SizedBox(width: 8),
                AppAsset(AppDecorations.sunSimple, width: 72, height: 72),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Semantics(
          header: true,
          child: const Text(
            'ここでは、あなたのペースで',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          '読むだけでも、大丈夫。\n気持ちを書いても、\nほかの人の声を読んでも。\nここは、がんばるあなたが\nひと息つける場所です。',
          style: TextStyle(fontSize: 13, height: 1.8),
        ),
      ],
    ),
  );
}

class _TopicsCard extends StatelessWidget {
  const _TopicsCard({
    required this.selected,
    required this.onSelected,
    required this.topics,
  });

  final Topic? selected;
  final ValueChanged<Topic?> onSelected;
  final AsyncValue<List<Topic>> topics;

  @override
  Widget build(BuildContext context) => _Card(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
          header: true,
          child: const Text(
            '話題から探す',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
          ),
        ),
        const SizedBox(height: 12),
        // 読み込めない・まだのときは、何も出さない(上の「話題を選ぶ」から選べる)。
        ...topics.maybeWhen(
          data: (list) => [
            for (final topic in list.take(DesktopHomeSidePanel.maxTopics))
              _Row(
                key: ValueKey('side-topic-${topic.id}'),
                icon: AppDecorations.leavesSprout,
                label: topic.label,
                selected: selected == topic,
                // もう一度押すと、絞り込みを外す。
                onTap: () => onSelected(selected == topic ? null : topic),
              ),
          ],
          orElse: () => const <Widget>[],
        ),
      ],
    ),
  );
}

class _SafetyCard extends StatelessWidget {
  const _SafetyCard({required this.onGuide, required this.onSupport});

  final VoidCallback onGuide;
  final VoidCallback onSupport;

  @override
  Widget build(BuildContext context) => _Card(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
          header: true,
          child: const Text(
            '安心して使うために',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
          ),
        ),
        const SizedBox(height: 12),
        _Row(
          key: const ValueKey('side-guide'),
          icon: AppDecorations.heartWarm,
          label: '利用ガイド',
          onTap: onGuide,
        ),
        _Row(
          key: const ValueKey('side-support'),
          icon: AppIcons.safetySupport,
          label: '困ったときの相談先',
          onTap: onSupport,
        ),
      ],
    ),
  );
}

class _Row extends StatelessWidget {
  const _Row({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.selected = false,
  });

  final String icon;
  final String label;
  final VoidCallback onTap;
  final bool selected;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Material(
      color: selected ? AppColors.secondary : AppColors.background,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Semantics(
          button: true,
          selected: selected,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            child: Row(
              children: [
                AppAsset(
                  icon,
                  width: 28,
                  height: 28,
                  excludeFromSemantics: true,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    label,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const Icon(Icons.chevron_right, size: 20),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
