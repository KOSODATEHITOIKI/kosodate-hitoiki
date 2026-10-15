import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../core/constants/app_icons.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/comfort_page.dart';
import '../auth/auth_page.dart';

/// S-11。画面確認用のサンプル。取得・解除・投稿除外はIssue #24で接続する。
class BlockManagementPage extends ConsumerStatefulWidget {
  const BlockManagementPage({super.key});

  @override
  ConsumerState<BlockManagementPage> createState() =>
      _BlockManagementPageState();
}

class _BlockManagementPageState extends ConsumerState<BlockManagementPage> {
  bool _blocked = true;

  Future<void> _unblock() async {
    if (!ref.read(isLoggedInProvider)) return;
    final accepted = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('あおぞらさんのブロックを解除しますか？'),
        content: const SingleChildScrollView(
          child: Text(
            '解除すると、相手の投稿・コメントが再び表示されます。解除は相手に通知されません。\n\n現在はサンプルです。実際のブロック状態は変わらず、この画面の一覧だけから取り除きます。',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('キャンセル'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('サンプルで解除'),
          ),
        ],
      ),
    );
    if (!mounted || accepted != true || !ref.read(isLoggedInProvider)) return;
    setState(() => _blocked = false);
  }

  @override
  Widget build(BuildContext context) {
    final loggedIn = ref.watch(isLoggedInProvider);
    ref.listen<bool>(isLoggedInProvider, (_, next) {
      if (!next) setState(() => _blocked = true);
    });
    return Scaffold(
      appBar: AppBar(title: const Text('ブロック管理')),
      body: !loggedIn
          ? ComfortPage(
              title: 'ログインして、ひと息',
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
                const Text(
                  'サンプルの一覧です。実際のブロック状態には反映されません。',
                  style: TextStyle(fontSize: 12, height: 1.7),
                ),
                const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Text(
                          'ブロック中の相手',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 16),
                        if (_blocked)
                          LayoutBuilder(
                            builder: (context, constraints) {
                              final stacked =
                                  constraints.maxWidth < 280 ||
                                  MediaQuery.textScalerOf(context).scale(14) >
                                      20;
                              final identity = Row(
                                children: [
                                  SvgPicture.asset(
                                    AppAvatars.defaultBlueFlowers,
                                    width: 48,
                                    height: 48,
                                    excludeFromSemantics: true,
                                  ),
                                  const SizedBox(width: 12),
                                  const Expanded(
                                    child: Text(
                                      'あおぞら',
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ],
                              );
                              final button = FilledButton(
                                onPressed: _unblock,
                                child: const Text('解除'),
                              );
                              if (stacked) {
                                return Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    identity,
                                    const SizedBox(height: 12),
                                    Align(
                                      alignment: Alignment.centerRight,
                                      child: button,
                                    ),
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
                          )
                        else ...[
                          const Text(
                            'ブロック中の相手はいません',
                            style: TextStyle(fontSize: 14),
                          ),
                          const SizedBox(height: 8),
                          TextButton(
                            onPressed: () => setState(() => _blocked = true),
                            child: const Text('サンプルを戻す'),
                          ),
                        ],
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

  void _auth(AuthMode mode) => Navigator.of(
    context,
  ).push<void>(MaterialPageRoute(builder: (_) => AuthPage(initialMode: mode)));
}
