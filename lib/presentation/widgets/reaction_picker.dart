import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kosodate_hitoiki/presentation/widgets/app_asset.dart';
import '../providers/auth_provider.dart';
import '../providers/post_providers.dart';
import '../providers/reaction_providers.dart';
import 'reaction_actions.dart';

/// 共感の定型文を選ぶ。1つ選べて、選び直すと前の選択が切り替わる。
Future<void> showReactionPicker(BuildContext context, String postId) =>
    showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      builder: (_) => _ReactionPicker(postId: postId),
    );

class _ReactionPicker extends ConsumerWidget {
  const _ReactionPicker({required this.postId});
  final String postId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!ref.watch(isLoggedInProvider)) {
      return const Padding(
        padding: EdgeInsets.all(24),
        child: Text('ログインが必要です。'),
      );
    }
    final sample = ref.watch(postsAreSampleProvider);
    final types = ref.watch(reactionTypesProvider);
    final selected = ref.watch(
      myReactionsProvider.select((reactions) => reactions[postId]),
    );

    Future<void> change(int? typeId) async {
      Navigator.of(context).pop();
      await changeReaction(
        context,
        ref,
        postId: postId,
        reactionTypeId: typeId,
      );
    }

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              '気持ちを届ける',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              '1つ選べます。選び直すと、前の選択が切り替わります。'
              '${sample ? '\nサンプル操作です。実際には送信されません。' : ''}',
              style: const TextStyle(fontSize: 12, height: 1.6),
            ),
            const SizedBox(height: 12),
            types.when(
              loading: () => const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (_, _) => Column(
                children: [
                  const Text(
                    '読み込めませんでした。',
                    key: ValueKey('reaction-types-failed'),
                    style: TextStyle(fontSize: 14),
                  ),
                  TextButton(
                    key: const ValueKey('reaction-types-retry'),
                    onPressed: () => ref.invalidate(reactionTypesProvider),
                    child: const Text('再読み込み'),
                  ),
                ],
              ),
              data: (items) => Column(
                children: [
                  for (final type in items)
                    ListTile(
                      key: ValueKey('reaction-${type.code}'),
                      selected: selected == type.id,
                      leading: AppAsset(
                        type.asset,
                        width: 36,
                        height: 36,
                        excludeFromSemantics: true,
                      ),
                      title: Text(
                        type.label,
                        style: const TextStyle(fontSize: 14),
                      ),
                      trailing: selected == type.id
                          ? const Icon(Icons.check)
                          : null,
                      onTap: () => change(type.id),
                    ),
                ],
              ),
            ),
            if (selected != null)
              TextButton(
                onPressed: () => change(null),
                child: const Text('共感を取り消す'),
              ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('閉じる'),
            ),
          ],
        ),
      ),
    );
  }
}
