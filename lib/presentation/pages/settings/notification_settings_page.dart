import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kosodate_hitoiki/presentation/widgets/app_asset.dart';
import '../../../core/constants/app_icons.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/comfort_page.dart';
import '../auth/auth_page.dart';

/// S-11通知設定のUI。実設定の取得・保存はIssue #60で接続する。
class NotificationSettingsPage extends ConsumerStatefulWidget {
  const NotificationSettingsPage({super.key});
  @override
  ConsumerState<NotificationSettingsPage> createState() =>
      _NotificationSettingsPageState();
}

class _NotificationSettingsPageState
    extends ConsumerState<NotificationSettingsPage> {
  bool _comments = true;
  bool _replies = true;
  bool _empathy = false;

  @override
  Widget build(BuildContext context) {
    final loggedIn = ref.watch(isLoggedInProvider);
    ref.listen<bool>(isLoggedInProvider, (_, next) {
      if (!next) {
        setState(() {
          _comments = true;
          _replies = true;
          _empathy = false;
        });
      }
    });
    return Scaffold(
      appBar: AppBar(title: const Text('通知設定')),
      body: !loggedIn
          ? ComfortPage(
              title: 'ログインして、\nひと息',
              message: '通知設定には、\n登録・ログインが必要です。',
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
              title: '通知設定',
              useBrandLogo: true,
              message: 'お知らせも、\nあなたのペースで。',
              children: [
                const Text(
                  '画面確認用のサンプル設定です。変更は保存されず、実際の通知には反映されません。',
                  style: TextStyle(fontSize: 12, height: 1.7),
                ),
                const SizedBox(height: 20),
                Card(
                  child: Column(
                    children: [
                      SwitchListTile(
                        secondary: AppAsset(
                          AppIcons.comment,
                          width: 28,
                          height: 28,
                          excludeFromSemantics: true,
                        ),
                        value: _comments,
                        onChanged: (value) => setState(() => _comments = value),
                        title: const Text(
                          'コメント',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        subtitle: Text(
                          'あなたの投稿へのコメントをお知らせします。\n${_comments ? '受け取る（サンプル）' : '受け取らない（サンプル）'}',
                          style: const TextStyle(fontSize: 12, height: 1.6),
                        ),
                      ),
                      const Divider(height: 1),
                      SwitchListTile(
                        value: _replies,
                        secondary: AppAsset(
                          AppIcons.reply,
                          width: 28,
                          height: 28,
                          excludeFromSemantics: true,
                        ),
                        onChanged: (value) => setState(() => _replies = value),
                        title: const Text(
                          '返信',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        subtitle: Text(
                          'あなたのコメントへの返信をお知らせします。\n${_replies ? '受け取る（サンプル）' : '受け取らない（サンプル）'}',
                          style: const TextStyle(fontSize: 12, height: 1.6),
                        ),
                      ),
                      const Divider(height: 1),
                      SwitchListTile(
                        secondary: AppAsset(
                          AppIcons.heart,
                          width: 28,
                          height: 28,
                          excludeFromSemantics: true,
                        ),
                        value: _empathy,
                        onChanged: (value) => setState(() => _empathy = value),
                        title: const Text(
                          '共感のまとめ',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        subtitle: Text(
                          '届いた共感をまとめてお知らせします。\n${_empathy ? '受け取る（サンプル）' : '受け取らない（サンプル）'}',
                          style: const TextStyle(fontSize: 12, height: 1.6),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Text(
                          '端末の通知設定',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          '通知を受け取るには、端末側でも通知の許可が必要です。',
                          style: TextStyle(fontSize: 12, height: 1.6),
                        ),
                        const SizedBox(height: 8),
                        OutlinedButton(
                          onPressed: () => showDialog<void>(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('端末設定への移動は準備中です'),
                              content: const Text(
                                '現在は端末の設定を開きません。端末連携の実装を準備しています。',
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.of(context).pop(),
                                  child: const Text('閉じる'),
                                ),
                              ],
                            ),
                          ),
                          child: const Text('設定を開く'),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  '運営からの連絡は、この切り替えの対象には含みません。',
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
