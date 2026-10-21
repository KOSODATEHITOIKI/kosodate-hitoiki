import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/password_policy.dart';
import '../../providers/auth_provider.dart';
import 'auth_messages.dart';
import 'auth_validators.dart';

/// 新しいパスワードを決める画面。パスワード再設定のメールのリンクから戻ったときに開く
/// (戻った時点で、再設定用のログイン状態になっている)。
/// パスワードの条件は、登録のときと同じ(password_policy.dart)。最終判定はSupabase Auth。
class NewPasswordPage extends ConsumerStatefulWidget {
  const NewPasswordPage({super.key});

  @override
  ConsumerState<NewPasswordPage> createState() => _NewPasswordPageState();
}

class _NewPasswordPageState extends ConsumerState<NewPasswordPage> {
  final _form = GlobalKey<FormState>();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool _obscure = true;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_busy) return;
    FocusManager.instance.primaryFocus?.unfocus();
    if (!(_form.currentState?.validate() ?? false)) return;
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref.read(authRepositoryProvider).updatePassword(_password.text);
    } catch (error) {
      if (mounted) {
        setState(() {
          _busy = false;
          _error = authErrorMessage(error);
        });
      }
      return;
    }
    messenger.showSnackBar(const SnackBar(content: Text('パスワードを変更しました')));
    // 再設定のリンクから戻った状態で、ログイン済み。最初の画面(ホーム)へ戻る。
    navigator.popUntil((route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) => PopScope(
    // 送信中は戻れない(途中で閉じて、変更できたか分からなくならないように)。
    canPop: !_busy,
    child: Scaffold(
      appBar: AppBar(title: const Text('新しいパスワード')),
      body: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Form(
              key: _form,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
                children: [
                  const Text(
                    '新しいパスワードを\n決めてください。',
                    key: ValueKey('new-password-title'),
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 24),
                  TextFormField(
                    key: const ValueKey('new-password'),
                    controller: _password,
                    onChanged: (_) => setState(() {}),
                    obscureText: _obscure,
                    autocorrect: false,
                    enableSuggestions: false,
                    enabled: !_busy,
                    decoration: InputDecoration(
                      labelText: '新しいパスワード',
                      helperText: _password.text.isEmpty
                          ? PasswordPolicy.description
                          : (passwordRegisterProblem(_password.text) ??
                                '条件を満たしています。'),
                      helperMaxLines: 3,
                      errorMaxLines: 3,
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        tooltip: _obscure ? 'パスワードを表示' : 'パスワードを隠す',
                        onPressed: () => setState(() => _obscure = !_obscure),
                        icon: Icon(
                          _obscure
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                        ),
                      ),
                    ),
                    validator: (value) => passwordRegisterProblem(value ?? ''),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    key: const ValueKey('new-password-confirm'),
                    controller: _confirm,
                    onChanged: (_) => setState(() {}),
                    obscureText: _obscure,
                    autocorrect: false,
                    enableSuggestions: false,
                    enabled: !_busy,
                    decoration: InputDecoration(
                      labelText: '新しいパスワード(確認用)',
                      helperText: _confirm.text.isEmpty
                          ? 'もう一度、同じパスワードを入力してください。'
                          : (_confirm.text == _password.text
                                ? '一致しています。'
                                : 'まだ一致していません。'),
                      prefixIcon: const Icon(Icons.lock_outline),
                    ),
                    validator: (value) =>
                        passwordConfirmProblem(_password.text, value ?? ''),
                  ),
                  if (_error != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Text(
                        _error!,
                        key: const ValueKey('new-password-error'),
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                          fontSize: 13,
                          height: 1.6,
                        ),
                      ),
                    ),
                  const SizedBox(height: 20),
                  FilledButton(
                    key: const ValueKey('new-password-submit'),
                    onPressed: _busy ? null : _submit,
                    child: Text(_busy ? '通信しています…' : 'パスワードを変更する'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
