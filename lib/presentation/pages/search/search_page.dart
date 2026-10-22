import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_brand.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_icons.dart';
import '../../../domain/models/post.dart';
import '../../providers/post_providers.dart';
import '../../widgets/comfort_page.dart';
import '../../widgets/mock_post_list.dart';
import '../../widgets/topic_picker.dart';

/// S-05。検索(Issue #10)はMockPostRepositoryで仮接続済み。
/// バックエンド実装後はpostRepositoryProviderの差し替えのみで切り替わる。
class SearchPage extends ConsumerStatefulWidget {
  const SearchPage({super.key});
  @override
  ConsumerState<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends ConsumerState<SearchPage> {
  final _controller = TextEditingController();

  static const _typeByLabel = {
    'ぐち': PostType.grumble,
    '相談': PostType.consult,
    'コツ・体験談': PostType.tips,
  };

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _controller.text = ref.read(searchQueryProvider).keyword;
  }

  @override
  Widget build(BuildContext context) {
    final query = ref.watch(searchQueryProvider);
    return ComfortPage(
      title: '検索',
      titleImage: AppBrand.titleSearch,
      message: '子育ての毎日に、\nひと息つける場所を。',
      children: [
        TextField(
          controller: _controller,
          textInputAction: TextInputAction.search,
          onChanged: (value) => ref.read(searchQueryProvider.notifier).state =
              query.copyWith(keyword: value),
          onSubmitted: (_) => FocusScope.of(context).unfocus(),
          decoration: InputDecoration(
            hintText: '気になる言葉で検索',
            labelText: 'キーワード',
            prefixIcon: const Icon(Icons.search),
            suffixIcon: _controller.text.isEmpty
                ? null
                : IconButton(
                    tooltip: '検索語を消す',
                    onPressed: () {
                      _controller.clear();
                      ref.read(searchQueryProvider.notifier).state = query
                          .copyWith(keyword: '');
                    },
                    icon: const Icon(Icons.cancel_outlined),
                  ),
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
                selected: (query.type?.label ?? 'すべて') == type,
                onSelected: (_) =>
                    ref.read(searchQueryProvider.notifier).state = query
                        .copyWith(
                          type: _typeByLabel[type],
                          clearType: type == 'すべて',
                        ),
                showCheckmark: false,
                selectedColor: AppColors.secondary,
                backgroundColor: AppColors.white,
                shape: const StadiumBorder(),
                side: BorderSide(
                  color: (query.type?.label ?? 'すべて') == type
                      ? Colors.transparent
                      : AppColors.divider,
                ),
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
              ),
          ],
        ),
        const SizedBox(height: 16),
        TopicFilterRow(
          selected: query.topic,
          onChanged: (topic) => ref.read(searchQueryProvider.notifier).state =
              query.copyWith(topic: topic, clearTopic: topic == null),
        ),
        const SizedBox(height: 24),
        const Wrap(
          spacing: 12,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(
              '検索結果',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            Text('・ 新着順', style: TextStyle(fontSize: 12.5)),
          ],
        ),
        const SizedBox(height: 16),
        MockPostList(
          posts: ref.watch(searchResultsProvider),
          emptyAsset: AppIllustrations.emptySearch,
          emptyTitle: '条件に合うサンプル投稿がありません',
          onRetry: () => ref.invalidate(searchResultsProvider),
        ),
      ],
    );
  }
}
