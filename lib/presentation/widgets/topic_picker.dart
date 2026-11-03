import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kosodate_hitoiki/presentation/widgets/app_asset.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_icons.dart';
import '../../domain/models/topic.dart';
import '../providers/post_providers.dart';

/// 話題を選ぶ画面の結果。[topic]が`null`なら、選択を外す(話題なし・すべて)。
class TopicChoice {
  const TopicChoice(this.topic);
  final Topic? topic;
}

/// 話題選択のボトムシートを開く。閉じただけなら`null`、選んだら[TopicChoice]を返す。
Future<TopicChoice?> showTopicPicker(
  BuildContext context, {
  Topic? current,
  String title = '話題を選ぶ',
  String clearLabel = '選択を外す',
}) {
  return showModalBottomSheet<TopicChoice>(
    context: context,
    useSafeArea: true,
    isScrollControlled: true,
    backgroundColor: AppColors.background,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) =>
        _TopicSheet(current: current, title: title, clearLabel: clearLabel),
  );
}

class _TopicSheet extends ConsumerWidget {
  const _TopicSheet({
    required this.current,
    required this.title,
    required this.clearLabel,
  });

  final Topic? current;
  final String title;
  final String clearLabel;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final topics = ref.watch(topicsProvider);
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 16),
            topics.when(
              loading: () => const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (_, _) => Column(
                children: [
                  const Text(
                    '読み込めませんでした。',
                    key: ValueKey('topics-failed'),
                    style: TextStyle(fontSize: 14),
                  ),
                  TextButton(
                    key: const ValueKey('topics-retry'),
                    onPressed: () => ref.invalidate(topicsProvider),
                    child: const Text('再読み込み'),
                  ),
                ],
              ),
              data: (items) => Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final topic in items)
                    ChoiceChip(
                      key: ValueKey('topic-${topic.id}'),
                      label: Text(topic.label),
                      selected: current == topic,
                      onSelected: (_) =>
                          Navigator.of(context).pop(TopicChoice(topic)),
                      showCheckmark: false,
                      selectedColor: AppColors.secondary,
                      backgroundColor: AppColors.white,
                      shape: const StadiumBorder(),
                      side: BorderSide(
                        color: current == topic
                            ? Colors.transparent
                            : AppColors.divider,
                      ),
                    ),
                ],
              ),
            ),
            if (current != null) ...[
              const SizedBox(height: 16),
              TextButton(
                key: const ValueKey('topic-clear'),
                onPressed: () =>
                    Navigator.of(context).pop(const TopicChoice(null)),
                child: Text(clearLabel),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// 一覧・検索の「話題を選ぶ」行。選ぶと、その話題の投稿だけに絞り込む。
class TopicFilterRow extends ConsumerWidget {
  const TopicFilterRow({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  final Topic? selected;
  final ValueChanged<Topic?> onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    Future<void> open() async {
      final choice = await showTopicPicker(
        context,
        current: selected,
        title: '話題で絞り込む',
        clearLabel: 'すべての話題に戻す',
      );
      if (choice != null) onChanged(choice.topic);
    }

    return Material(
      color: AppColors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        key: const ValueKey('topic-filter'),
        onTap: open,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.divider),
          ),
          child: Row(
            children: [
              AppAsset(
                AppDecorations.leavesSprout,
                width: 36,
                height: 36,
                excludeFromSemantics: true,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  selected?.label ?? '話題を選ぶ',
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: selected == null
                        ? FontWeight.w400
                        : FontWeight.w700,
                  ),
                ),
              ),
              if (selected != null)
                IconButton(
                  key: const ValueKey('topic-filter-clear'),
                  tooltip: '話題の絞り込みを外す',
                  onPressed: () => onChanged(null),
                  icon: const Icon(Icons.close),
                  visualDensity: VisualDensity.compact,
                )
              else
                const Icon(Icons.keyboard_arrow_down),
            ],
          ),
        ),
      ),
    );
  }
}
