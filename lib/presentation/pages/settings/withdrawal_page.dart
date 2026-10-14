import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/comfort_page.dart';
import '../auth/auth_page.dart';

/// S-14。説明・確認のみ。アカウントやデータを削除しない。
class WithdrawalPage extends ConsumerStatefulWidget {
  const WithdrawalPage({super.key});
  @override
  ConsumerState<WithdrawalPage> createState() => _WithdrawalPageState();
}

class _WithdrawalPageState extends ConsumerState<WithdrawalPage> {
  bool _confirmed = false;

  void _confirm() {
    if (!_confirmed || !ref.read(isLoggedInProvider)) return;
    showDialog<void>(
      context: context,
      builder: (context) => Consumer(
        builder: (context, dialogRef, _) => AlertDialog(
          title: Text(
            dialogRef.watch(isLoggedInProvider) ? '退会機能は準備中です' : 'ログインが必要です',
          ),
          content: const Text('アカウントやデータは削除されません。\n退会処理の接続を準備しています。'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('戻る'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final loggedIn = ref.watch(isLoggedInProvider);
    ref.listen<bool>(isLoggedInProvider, (_, next) {
      if (!next) setState(() => _confirmed = false);
    });
    return Scaffold(
      appBar: AppBar(title: const Text('退会')),
      body: !loggedIn
          ? ComfortPage(
              title: 'ログインして、ひと息',
              message: '退会の確認には、\nログインが必要です。',
              children: [
                OutlinedButton(
                  onPressed: () => Navigator.of(context).push<void>(
                    MaterialPageRoute(builder: (_) => const AuthPage()),
                  ),
                  child: const Text('ログイン'),
                ),
              ],
            )
          : ComfortPage(
              title: '退会する前に\nご確認ください',
              message: '退会すると、以下のデータが\nすべて削除されます。',
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        for (final item in const [
                          ('アカウントとプロフィール', '登録したアカウント情報とプロフィールが削除されます。'),
                          ('あなたの投稿・コメント・返信', 'これまでに投稿した内容、コメント、返信が削除されます。'),
                          ('共感・保存した投稿', '共感や保存の情報が削除されます。他の人が書いた投稿自体は削除されません。'),
                        ]) ...[
                          Text(
                            item.$1,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            item.$2,
                            style: const TextStyle(fontSize: 14, height: 1.7),
                          ),
                          const SizedBox(height: 16),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  '退会すると元に戻せません。',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                const Text(
                  '再び利用するには、新しいアカウントの登録が必要です。\n退会前のニックネームは30日間、他の人が使えなくなります。',
                  style: TextStyle(fontSize: 14, height: 1.7),
                ),
                const SizedBox(height: 16),
                CheckboxListTile(
                  value: _confirmed,
                  onChanged: (value) =>
                      setState(() => _confirmed = value ?? false),
                  controlAffinity: ListTileControlAffinity.leading,
                  contentPadding: EdgeInsets.zero,
                  title: const Text(
                    '削除される内容を確認しました',
                    style: TextStyle(fontSize: 14),
                  ),
                ),
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: _confirmed ? _confirm : null,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Theme.of(context).colorScheme.error,
                  ),
                  child: const Text('退会の確認へ'),
                ),
                const SizedBox(height: 8),
                FilledButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('利用を続ける'),
                ),
                const SizedBox(height: 12),
                const Text(
                  '退会機能は準備中です。現在はアカウントやデータを削除しません。',
                  style: TextStyle(fontSize: 12, height: 1.7),
                ),
              ],
            ),
    );
  }
}
