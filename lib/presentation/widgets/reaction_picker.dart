import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../providers/auth_provider.dart';
import '../providers/mock_reaction_providers.dart';

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
    final selected = ref.watch(mockReactionsProvider)[postId];
    void select(MockReaction? reaction) {
      if (!ref.read(isLoggedInProvider)) return;
      ref.read(mockReactionAuthGuardProvider);
      final next = {...ref.read(mockReactionsProvider)};
      if (reaction == null) {
        next.remove(postId);
      } else {
        next[postId] = reaction;
      }
      ref.read(mockReactionsProvider.notifier).state = next;
      Navigator.of(context).pop();
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
            const Text(
              '1つ選べます。選び直すと、前の選択が切り替わります。\nサンプル操作です。実際には送信されません。',
              style: TextStyle(fontSize: 12, height: 1.6),
            ),
            const SizedBox(height: 12),
            for (final reaction in MockReaction.values)
              ListTile(
                selected: selected == reaction,
                leading: SvgPicture.asset(
                  reaction.asset,
                  width: 36,
                  height: 36,
                  excludeFromSemantics: true,
                ),
                title: Text(
                  reaction.label,
                  style: const TextStyle(fontSize: 14),
                ),
                trailing: selected == reaction ? const Icon(Icons.check) : null,
                onTap: () => select(reaction),
              ),
            if (selected != null)
              TextButton(
                onPressed: () => select(null),
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
