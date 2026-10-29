import 'package:flutter/material.dart';
import '../../../core/widgets/centered_page_transitions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kosodate_hitoiki/presentation/widgets/app_asset.dart';

import '../../../domain/models/blocked_user.dart';
import '../../providers/auth_provider.dart';
import '../../providers/post_providers.dart';
import '../../widgets/comfort_page.dart';
import '../auth/auth_page.dart';
import '../compose/post_messages.dart';

/// S-11。ブロック中の相手の一覧と、解除(`my_blocks`の取得、`blocks`の削除)。
/// ブロックや解除は、相手に通知されない。解除すると、相手の投稿・コメントが再び表示される。
class BlockManagementPage extends ConsumerStatefulWidget {
  const BlockManagementPage({super.key});

  @override
  ConsumerState<BlockManagementPage> createState() =>
      _BlockManagementPageState();
}

class _BlockManagementPageState extends ConsumerState<BlockManagementPage> {
  /// 解除の送信中(続けて押しても、二重に送らない)。
  bool _busy = false;

  Future<void> _unblock(BlockedUser user) async {
    if (_busy || !ref.read(isLoggedInProvider)) return;
    final sample = ref.read(postsAreSampleProvider);
    final name = user.nickname.isEmpty ? 'この相手' : '${user.nickname}さん';
    final accepted = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('$nameのブロックを解除しますか？'),
        content: SingleChildScrollView(
          child: Text(
            '解除すると、相手の投稿・コメントが再び表示されます。解除は相手に通知されません。'
            '${sample ? '\n\n現在はサンプルです。実際のブロック状態は変わりません。' : ''}',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('キャンセル'),
          ),
          FilledButton(
            key: const ValueKey('unblock-confirm'),
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(sample ? 'サンプルで解除' : '解除する'),
          ),
        ],
      ),
    );
    if (!mounted || accepted != true || !ref.read(isLoggedInProvider)) return;
    // 応答を待つ間に画面が閉じられても、取り直せるよう、先に取っておく。
    final container = ProviderScope.containerOf(context);
    final repository = ref.read(postRepositoryProvider);
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _busy = true);
    try {
      await repository.unblockUser(user.id);
    } catch (error) {
      messenger.showSnackBar(
        SnackBar(content: Text(postFailureMessage(error))),
      );
      if (mounted) setState(() => _busy = false);
      return;
    }
    // 解除した相手の投稿が、一覧・検索に戻る。
    container
      ..invalidate(blockedUsersProvider)
      ..invalidate(postDetailProvider)
      ..invalidate(feedPostsProvider)
      ..invalidate(searchResultsProvider)
      ..invalidate(myPostsProvider)
      ..invalidate(savedPostsProvider);
    messenger.showSnackBar(const SnackBar(content: Text('ブロックを解除しました')));
    if (mounted) setState(() => _busy = false);
  }

  @override
  Widget build(BuildContext context) {
    final loggedIn = ref.watch(isLoggedInProvider);
    final sample = ref.watch(postsAreSampleProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('ブロック管理')),
      body: !loggedIn
          ? ComfortPage(
              title: 'ログインして、\nひと息',
              message: 'ブロック管理には、\n登録・ログインが必要です。',
              children: [
                FilledButton(
                  onPressed: () => _auth(AuthMode.register),
                  child: const Text('会員登録'),
                ),
                const SizedBox(height: 8),
                OutlinedButton(
                  onPressed: () => _auth(AuthMode.login),
                  child: const Text('ログイン'),
                ),
              ],
            )
          : ComfortPage(
              title: 'ブロック管理',
              message: '安心して使えるように、\nブロックした相手を管理できます。',
              children: [
                if (sample) ...[
                  const Text(
                    'サンプルの一覧です。実際のブロック状態には反映されません。',
                    style: TextStyle(fontSize: 12, height: 1.7),
                  ),
                  const SizedBox(height: 16),
                ],
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Text(
                          'ブロック中の相手',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 16),
                        ref
                            .watch(blockedUsersProvider)
                            .when(
                              loading: () => const Padding(
                                padding: EdgeInsets.symmetric(vertical: 24),
                                child: Center(
                                  child: CircularProgressIndicator(),
                                ),
                              ),
                              error: (_, _) => Column(
                                children: [
                                  const Text(
                                    '読み込めませんでした。',
                                    key: ValueKey('blocks-load-failed'),
                                    style: TextStyle(fontSize: 14),
                                  ),
                                  TextButton(
                                    key: const ValueKey('blocks-retry'),
                                    onPressed: () =>
                                        ref.invalidate(blockedUsersProvider),
                                    child: const Text('再読み込み'),
                                  ),
                                ],
                              ),
                              data: (users) => users.isEmpty
                                  ? const Text(
                                      'ブロック中の相手はいません',
                                      key: ValueKey('blocks-empty'),
                                      style: TextStyle(fontSize: 14),
                                    )
                                  : Column(
                                      children: [
                                        for (final user in users)
                                          _BlockedRow(
                                            user: user,
                                            onUnblock: _busy
                                                ? null
                                                : () => _unblock(user),
                                          ),
                                      ],
                                    ),
                            ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'ブロック中は相手の投稿・コメントが表示されません。\nブロックや解除は相手に通知されません。',
                  style: TextStyle(fontSize: 12, height: 1.7),
                ),
              ],
            ),
    );
  }

  void _auth(AuthMode mode) => Navigator.of(context).push<void>(
    fullWidthRoute<void>(builder: (_) => AuthPage(initialMode: mode)),
  );
}

/// 一覧の1行。狭い画面・大きな文字では、名前と「解除」を縦に並べる。
class _BlockedRow extends StatelessWidget {
  const _BlockedRow({required this.user, required this.onUnblock});

  final BlockedUser user;
  final VoidCallback? onUnblock;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: LayoutBuilder(
      builder: (context, constraints) {
        final stacked =
            constraints.maxWidth < 280 ||
            MediaQuery.textScalerOf(context).scale(14) > 20;
        final identity = Row(
          children: [
            ClipOval(
              child: AppAsset(
                user.avatarAsset,
                width: 48,
                height: 48,
                excludeFromSemantics: true,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                user.nickname.isEmpty ? '(名前なし)' : user.nickname,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        );
        final button = FilledButton(
          key: ValueKey('unblock-${user.id}'),
          onPressed: onUnblock,
          child: const Text('解除'),
        );
        if (stacked) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              identity,
              const SizedBox(height: 12),
              Align(alignment: Alignment.centerRight, child: button),
            ],
          );
        }
        return Row(
          children: [
            Expanded(child: identity),
            const SizedBox(width: 12),
            button,
          ],
        );
      },
    ),
  );
}
