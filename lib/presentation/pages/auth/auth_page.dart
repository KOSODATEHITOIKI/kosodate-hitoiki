import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_icons.dart';

/// S-10。フォームと画面遷移のみ。認証・メール送信は未接続。
enum AuthMode { login, register, reset }

class AuthPage extends StatefulWidget {
  const AuthPage({super.key, this.initialMode = AuthMode.login});
  final AuthMode initialMode;
  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _nickname = TextEditingController();
  late AuthMode _mode = widget.initialMode;
  bool _obscure = true;
  bool _agree = false;
  String? _agreementError;

  String get _title => switch (_mode) {
    AuthMode.login => 'ログイン',
    AuthMode.register => '会員登録',
    AuthMode.reset => 'パスワード再設定',
  };

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _nickname.dispose();
    super.dispose();
  }

  void _changeMode(AuthMode mode) {
    FocusScope.of(context).unfocus();
    _form.currentState?.reset();
    _password.clear();
    setState(() {
      _mode = mode;
      _obscure = true;
      _agree = false;
      _agreementError = null;
    });
  }

  void _notice(String title, String message) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('閉じる'),
          ),
        ],
      ),
    );
  }

  void _submit() {
    final valid = _form.currentState!.validate();
    setState(
      () => _agreementError = _mode == AuthMode.register && !_agree
          ? '利用規約・プライバシーポリシーへの同意を確認してください。'
          : null,
    );
    if (!valid || _agreementError != null) return;
    FocusScope.of(context).unfocus();
    _notice('$_titleは準備中です', '入力内容は送信されません。アカウントの作成・ログイン・メール送信は行われません。');
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(_title)),
    body: SafeArea(
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
            child: Form(
              key: _form,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'ひと息',
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      SvgPicture.asset(
                        AppDecorations.sunSmiling,
                        width: 96,
                        height: 96,
                        excludeFromSemantics: true,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(switch (_mode) {
                    AuthMode.login => 'おかえりなさい。',
                    AuthMode.register => 'がんばる毎日に、やさしいつながりを。',
                    AuthMode.reset => '登録したメールアドレスを入力してください。',
                  }, style: const TextStyle(fontSize: 18, height: 1.7)),
                  const SizedBox(height: 24),
                  if (_mode != AuthMode.reset) ...[
                    for (final provider in ['Apple', 'Google']) ...[
                      OutlinedButton(
                        onPressed: () =>
                            _notice('$providerでの認証は準備中です', 'この画面では認証は行われません。'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.textPrimary,
                          backgroundColor: AppColors.white,
                          minimumSize: const Size.fromHeight(52),
                          side: const BorderSide(color: AppColors.divider),
                        ),
                        child: Text('$providerで続ける'),
                      ),
                      const SizedBox(height: 12),
                    ],
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Row(
                        children: [
                          Expanded(child: Divider()),
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 16),
                            child: Text('またはメールで'),
                          ),
                          Expanded(child: Divider()),
                        ],
                      ),
                    ),
                  ],
                  if (_mode == AuthMode.register) ...[
                    TextFormField(
                      key: const ValueKey('auth-nickname'),
                      controller: _nickname,
                      maxLength: 12,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: 'ニックネーム',
                        helperText: '2〜12文字・本名は使わないでください。',
                      ),
                      validator: (value) =>
                          (value ?? '').trim().characters.length < 2
                          ? '2〜12文字で入力してください。'
                          : null,
                    ),
                    const SizedBox(height: 16),
                  ],
                  TextFormField(
                    key: const ValueKey('auth-email'),
                    controller: _email,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    autocorrect: false,
                    decoration: const InputDecoration(
                      labelText: 'メールアドレス',
                      hintText: 'example@example.com',
                      prefixIcon: Icon(Icons.mail_outline),
                    ),
                    validator: (value) =>
                        RegExp(
                          r'^[^\s@]+@[^\s@]+\.[^\s@]+$',
                        ).hasMatch((value ?? '').trim())
                        ? null
                        : 'メールアドレスを確認してください。',
                  ),
                  const SizedBox(height: 16),
                  if (_mode != AuthMode.reset) ...[
                    TextFormField(
                      key: const ValueKey('auth-password'),
                      controller: _password,
                      obscureText: _obscure,
                      autocorrect: false,
                      enableSuggestions: false,
                      decoration: InputDecoration(
                        labelText: 'パスワード',
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
                      validator: (value) =>
                          (value ?? '').isEmpty ? 'パスワードを入力してください。' : null,
                    ),
                    const SizedBox(height: 12),
                  ],
                  if (_mode == AuthMode.login)
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () => _changeMode(AuthMode.reset),
                        child: const Text('パスワードを忘れた方'),
                      ),
                    ),
                  if (_mode == AuthMode.register) ...[
                    Wrap(
                      spacing: 8,
                      children: [
                        for (final title in ['利用規約', 'プライバシーポリシー'])
                          TextButton(
                            onPressed: () => _notice(
                              '$titleは準備中です',
                              '本文の公開を準備しています。現在は会員登録できません。',
                            ),
                            child: Text(title),
                          ),
                      ],
                    ),
                    CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      controlAffinity: ListTileControlAffinity.leading,
                      value: _agree,
                      onChanged: (value) => setState(() {
                        _agree = value ?? false;
                        _agreementError = null;
                      }),
                      title: const Text(
                        '利用規約・プライバシーポリシーに同意する',
                        style: TextStyle(fontSize: 14),
                      ),
                    ),
                    if (_agreementError != null)
                      Text(
                        _agreementError!,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                          fontSize: 13,
                        ),
                      ),
                  ],
                  const SizedBox(height: 16),
                  FilledButton(
                    key: const ValueKey('auth-submit'),
                    onPressed: _submit,
                    child: Text(switch (_mode) {
                      AuthMode.login => 'ログインする',
                      AuthMode.register => '登録する',
                      AuthMode.reset => '再設定メールを送る',
                    }),
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () => _changeMode(
                      _mode == AuthMode.login
                          ? AuthMode.register
                          : AuthMode.login,
                    ),
                    child: Text(_mode == AuthMode.login ? '会員登録へ' : 'ログインへ'),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    '認証機能は準備中です。\n入力内容は送信・保存されません。',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, height: 1.7),
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
