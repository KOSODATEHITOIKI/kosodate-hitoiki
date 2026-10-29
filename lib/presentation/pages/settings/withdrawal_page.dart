import 'package:flutter/material.dart';
import '../../../core/widgets/centered_page_transitions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/api/api_exception.dart';
import '../../providers/account_providers.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/comfort_page.dart';
import '../auth/auth_page.dart';
import '../compose/post_messages.dart';

/// S-14。退会(アカウントの削除)。取消期間はなく、即時に削除する。
/// 「元に戻せません」と確認してから、退会API(`POST /functions/v1/account-delete`)を呼ぶ。
class WithdrawalPage extends ConsumerStatefulWidget {
  const WithdrawalPage({super.key});
  @override
  ConsumerState<WithdrawalPage> createState() => _WithdrawalPageState();
}

class _WithdrawalPageState extends ConsumerState<WithdrawalPage> {
  bool _confirmed = false;
  bool _busy = false;
  String? _error;

  /// 退会できた。端末のログイン状態を外すと、利用者IDがなくなるが、それは自分で
  /// 起こした変化なので、画面は閉じず、完了の画面を出す。
  bool _done = false;

  /// 再ログインへ進む途中。ログアウトで利用者IDが変わるが、閉じる操作は自分で行う。
  bool _leaving = false;

  /// 最後の確認。「元に戻せません」と伝え、「退会する」を押したときだけ実行する。
  Future<void> _confirm() async {
    if (!_confirmed || _busy || !ref.read(isLoggedInProvider)) return;
    if (ref.read(accountRepositoryProvider).isSample) {
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
      return;
    }
    final proceed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('本当に退会しますか？'),
        content: const Text('退会すると、アカウントと、投稿・コメント・返信・共感・保存がすべて削除されます。元に戻せません。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('やめる'),
          ),
          FilledButton(
            key: const ValueKey('withdraw-confirm'),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('退会する'),
          ),
        ],
      ),
    );
    if (proceed != true || !mounted) return;
    await _withdraw();
  }

  Future<void> _withdraw() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref.read(accountRepositoryProvider).deleteAccount();
    } on ApiException catch (error) {
      if (!mounted) return;
      final reason = error.details['reason'];
      if (reason == 'reauth_required') {
        setState(() => _busy = false);
        await _askRelogin();
        return;
      }
      setState(() {
        _busy = false;
        _error = reason == 'operator_registered'
            ? '運営者として登録されているため、退会できません。先に、運営者の登録を外してください。'
            : postFailureMessage(error);
      });
      return;
    } catch (error) {
      if (mounted) {
        setState(() {
          _busy = false;
          _error = postFailureMessage(error);
        });
      }
      return;
    }
    if (!mounted) return;
    // 完了の画面に切り替えてから、端末のログイン状態を外す(利用者IDの変化で閉じない)。
    setState(() {
      _done = true;
      _busy = false;
    });
    try {
      await ref.read(authRepositoryProvider).signOutLocal();
    } catch (_) {
      // 端末の状態を外せなくても、アカウントはもう削除されている。
    }
  }

  /// 本人確認のため、直近にログインし直してもらう(退会は、5分以内に作られたセッションだけ)。
  Future<void> _askRelogin() async {
    final relogin = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('もう一度ログインしてください'),
        content: const Text(
          '安全のため、退会は、ログインしてから間もないときだけできます。ログインし直してから、もう一度退会してください。',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('やめる'),
          ),
          FilledButton(
            key: const ValueKey('withdraw-relogin'),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('ログインし直す'),
          ),
        ],
      ),
    );
    if (relogin != true || !mounted) return;
    _leaving = true;
    final navigator = Navigator.of(context);
    try {
      await ref.read(authRepositoryProvider).signOut();
    } catch (_) {
      _leaving = false;
      if (mounted) setState(() => _error = 'ログアウトできませんでした。もう一度お試しください。');
      return;
    }
    navigator.popUntil((route) => route.isFirst);
    navigator.push<void>(
      fullWidthRoute<void>(builder: (_) => const AuthPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final loggedIn = ref.watch(isLoggedInProvider);
    ref.listen<bool>(isLoggedInProvider, (_, next) {
      if (!next) setState(() => _confirmed = false);
    });
    // 利用者が切り替わったら、この画面(と確認ダイアログ)を閉じる。閉じないと、別の
    // アカウントを退会させてしまう。退会の完了・再ログインへ進む途中の変化は、除く。
    ref.listen<String?>(currentUserIdProvider, (previous, next) {
      if (previous == next || _done || _leaving) return;
      final navigator = Navigator.of(context);
      final myRoute = ModalRoute.of(context);
      if (myRoute != null) {
        navigator.popUntil((route) => route == myRoute);
      }
      if (navigator.canPop()) navigator.pop();
    });
    if (_done) return _donePage();
    return PopScope(
      // 削除の処理中は、戻れない(結果を受け取れず、状態が分からなくなる)。
      canPop: !_busy,
      child: Scaffold(
        appBar: AppBar(title: const Text('退会')),
        body: !loggedIn ? _guest() : _form(),
      ),
    );
  }

  Widget _guest() => ComfortPage(
    title: 'ログインして、\nひと息',
    message: '退会の確認には、\nログインが必要です。',
    children: [
      OutlinedButton(
        onPressed: () => Navigator.of(
          context,
        ).push<void>(fullWidthRoute<void>(builder: (_) => const AuthPage())),
        child: const Text('ログイン'),
      ),
    ],
  );

  /// 退会できたあとの画面。アカウントは削除済みで、ログアウトした状態。
  Widget _donePage() => PopScope(
    canPop: false,
    onPopInvokedWithResult: (didPop, _) {
      if (!didPop) Navigator.of(context).popUntil((route) => route.isFirst);
    },
    child: Scaffold(
      appBar: AppBar(
        title: const Text('退会しました'),
        automaticallyImplyLeading: false,
      ),
      body: ComfortPage(
        title: '退会しました。',
        message: 'ご利用ありがとうございました。\nまたいつでも、新しく登録できます。',
        children: [
          const Text(
            'アカウントと、投稿・コメント・返信・共感・保存を削除しました。退会前のニックネームは30日間、他の人が使えません。',
            key: ValueKey('withdraw-done'),
            style: TextStyle(fontSize: 14, height: 1.7),
          ),
          const SizedBox(height: 16),
          FilledButton(
            key: const ValueKey('withdraw-home'),
            onPressed: () =>
                Navigator.of(context).popUntil((route) => route.isFirst),
            child: const Text('最初の画面へ'),
          ),
        ],
      ),
    ),
  );

  Widget _form() => ComfortPage(
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
                (
                  '一定期間、残る記録',
                  '次の記録は、退会のあとも、一定期間残ります。ニックネームの予約は30日(その間、他の人は使えません)、運営の対応や通報の記録は1年、バックアップは30日です。',
                ),
              ]) ...[
                Text(
                  item.$1,
                  style: const TextStyle(
                    fontSize: 14,
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
        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
      ),
      const SizedBox(height: 8),
      const Text(
        '再び利用するには、新しいアカウントの登録が必要です。\n退会前のニックネームは30日間、他の人が使えなくなります。',
        style: TextStyle(fontSize: 14, height: 1.7),
      ),
      const SizedBox(height: 16),
      CheckboxListTile(
        value: _confirmed,
        onChanged: _busy
            ? null
            : (value) => setState(() => _confirmed = value ?? false),
        controlAffinity: ListTileControlAffinity.leading,
        contentPadding: EdgeInsets.zero,
        title: const Text('削除される内容を確認しました', style: TextStyle(fontSize: 14)),
      ),
      if (_error != null)
        Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Text(
            _error!,
            key: const ValueKey('withdraw-error'),
            style: TextStyle(
              color: Theme.of(context).colorScheme.error,
              fontSize: 13,
              height: 1.6,
            ),
          ),
        ),
      const SizedBox(height: 12),
      OutlinedButton(
        key: const ValueKey('withdraw-start'),
        onPressed: _confirmed && !_busy ? _confirm : null,
        style: OutlinedButton.styleFrom(
          foregroundColor: Theme.of(context).colorScheme.error,
        ),
        child: Text(_busy ? '退会しています…' : '退会の確認へ'),
      ),
      const SizedBox(height: 8),
      FilledButton(
        onPressed: _busy ? null : () => Navigator.of(context).pop(),
        child: const Text('利用を続ける'),
      ),
      if (ref.watch(accountRepositoryProvider).isSample) ...[
        const SizedBox(height: 12),
        const Text(
          '退会機能は準備中です。現在はアカウントやデータを削除しません。',
          style: TextStyle(fontSize: 12, height: 1.7),
        ),
      ],
    ],
  );
}
