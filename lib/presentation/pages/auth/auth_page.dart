import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:kosodate_hitoiki/presentation/widgets/app_asset.dart';

import '../../../core/constants/app_brand.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_icons.dart';
import '../../../core/utils/accessibility.dart';
import '../../providers/auth_provider.dart';
import 'auth_messages.dart';
import 'auth_validators.dart';
import 'legal_consent.dart';
import 'profile_creation.dart';
import 'profile_setup_page.dart';

/// S-10。メール+パスワードの登録・ログインはSupabase Authに接続済み。
/// Google・Appleとパスワード再設定は、アプリへ戻るためのディープリンクの
/// 設定が済むまで未接続(バックエンド docs/Flutter結合ガイド.md 4節)。
enum AuthMode { login, register, reset }

class AuthPage extends ConsumerStatefulWidget {
  const AuthPage({super.key, this.initialMode = AuthMode.login});
  final AuthMode initialMode;
  @override
  ConsumerState<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends ConsumerState<AuthPage> {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _nickname = TextEditingController();
  late AuthMode _mode = widget.initialMode;
  bool _obscure = true;
  bool _agreeTerms = false;
  bool _agreePrivacy = false;
  bool _busy = false;
  String? _error;

  /// 入力欄を一度離れた(または送信を試した)項目。赤い表示は、この項目が
  /// まだ間違っているときだけ出す。入力の途中では出さない。
  final _touched = <String>{};

  /// 登録・ログインを押したことがあるか。空欄を赤くするのは、押したあとだけ。
  bool _submitted = false;
  final _nicknameFocus = FocusNode();
  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();

  /// 登録後、確認メールの送信先(メール確認が必要な設定のとき)。
  String? _sentTo;

  String get _title => switch (_mode) {
    AuthMode.login => 'ログイン',
    AuthMode.register => '会員登録',
    AuthMode.reset => 'パスワード再設定',
  };

  @override
  void initState() {
    super.initState();
    for (final entry in {
      'nickname': _nicknameFocus,
      'email': _emailFocus,
      'password': _passwordFocus,
    }.entries) {
      entry.value.addListener(() {
        if (!entry.value.hasFocus && mounted) {
          setState(() => _touched.add(entry.key));
        }
      });
    }
  }

  /// 赤いエラー表示にするか。離れた後、または送信を試した後に、まだ間違っている項目。
  AutovalidateMode _autovalidate(String field) =>
      _touched.contains(field) || _submitted
      ? AutovalidateMode.always
      : AutovalidateMode.disabled;

  /// 空欄は、押すまでは赤くしない(タップして離れただけでは「間違い」ではない)。
  /// 何か入力してあって間違っているときだけ、離れた時点で赤くする。
  String? _check(String value, String? Function(String) problem) =>
      value.isEmpty && !_submitted ? null : problem(value);

  @override
  void dispose() {
    _nicknameFocus.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
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
      _agreeTerms = false;
      _agreePrivacy = false;
      _error = null;
      _sentTo = null;
      _touched.clear();
      _submitted = false;
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

  Future<void> _submit() async {
    setState(() {
      _submitted = true;
      _touched.addAll(['nickname', 'email', 'password']);
    });
    final valid = _form.currentState!.validate();
    if (!valid) return;
    FocusScope.of(context).unfocus();
    if (_mode == AuthMode.reset) {
      _notice('パスワード再設定は準備中です', 'メール内のリンクからアプリへ戻る設定を準備しています。メールは送信されません。');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      if (_mode == AuthMode.register) {
        await _register();
      } else {
        await _login();
      }
    } catch (error) {
      if (mounted) setState(() => _error = authErrorMessage(error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _register() async {
    final email = _email.text.trim();
    final response = await ref
        .read(authRepositoryProvider)
        .signUpWithEmail(
          email: email,
          password: _password.text,
          // 確認メールのリンクを開いたあとにプロフィールを作るための控え。
          // 規約の版数は、プロフィール作成時に送る(同意の記録はサーバー側)。
          data: {'nickname': _nickname.text.trim(), 'terms_agreed': true},
        );
    if (!mounted) return;
    if (response.session == null) {
      // メール確認が必要な設定。リンクを開くまでログインできない。
      setState(() => _sentTo = email);
      return;
    }
    await _afterSignedIn(response.user);
  }

  Future<void> _login() async {
    final response = await ref
        .read(authRepositoryProvider)
        .signInWithEmail(email: _email.text.trim(), password: _password.text);
    if (!mounted) return;
    await _afterSignedIn(response.user);
  }

  /// ログイン後、プロフィールが未作成なら作る(控えがあれば自動、なければ入力画面)。
  /// 完了しなければ、中途半端な状態を残さないようログアウトする。
  Future<void> _afterSignedIn(User? user) async {
    if (user == null) return;
    final profiles = ref.read(profileRegistrationRepositoryProvider);
    if (!await profiles.hasProfile(user.id)) {
      if (!mounted) return;
      final metadata = user.userMetadata ?? const <String, dynamic>{};
      final nickname = (metadata['nickname'] as String?)?.trim() ?? '';
      final agreed = metadata['terms_agreed'] == true;
      String? failure = 'ニックネームを決めてください。';
      if (nickname.isNotEmpty && agreed) {
        failure = await createProfileWithConfirmation(
          context: context,
          repository: profiles,
          nickname: nickname,
        );
      }
      if (failure != null) {
        if (!mounted) return;
        final created = await Navigator.of(context).push<bool>(
          MaterialPageRoute(
            builder: (_) => ProfileSetupPage(initialNickname: nickname),
          ),
        );
        if (created != true) {
          await ref.read(authRepositoryProvider).signOut();
          return;
        }
      }
    }
    if (mounted) Navigator.of(context).maybePop();
  }

  @override
  Widget build(BuildContext context) {
    final sentTo = _sentTo;
    if (sentTo != null) return _checkEmailPage(sentTo);
    return _formPage();
  }

  /// 登録後の「確認メールを送りました」。メール確認が必要な設定のときだけ表示する。
  Widget _checkEmailPage(String email) => Scaffold(
    body: SafeArea(
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: BackButton(
                    onPressed: () => Navigator.of(context).maybePop(),
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  '確認メールを送りました',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 16),
                Text(
                  '$email に届いたメールのリンクを開いてから、ログインしてください。',
                  style: const TextStyle(height: 1.7),
                ),
                const SizedBox(height: 12),
                const Text(
                  'メールが届かないときは、迷惑メールフォルダも確認してください。',
                  style: TextStyle(fontSize: 12, height: 1.7),
                ),
                const SizedBox(height: 24),
                FilledButton(
                  key: const ValueKey('auth-to-login'),
                  onPressed: () => _changeMode(AuthMode.login),
                  child: const Text('ログインへ'),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );

  Widget _formPage() => Scaffold(
    body: SafeArea(
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
            child: Form(
              key: _form,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: BackButton(
                      onPressed: () => Navigator.of(context).maybePop(),
                    ),
                  ),
                  const SizedBox(height: 4),
                  _AuthHeader(title: _title, mode: _mode),
                  const SizedBox(height: 24),
                  if (_mode != AuthMode.reset) ...[
                    for (final provider in ['Apple', 'Google']) ...[
                      OutlinedButton.icon(
                        onPressed: () =>
                            _notice('$providerでの認証は準備中です', 'この画面では認証は行われません。'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.textPrimary,
                          backgroundColor: AppColors.white,
                          minimumSize: const Size.fromHeight(52),
                          side: const BorderSide(color: AppColors.divider),
                        ),
                        icon: Icon(
                          provider == 'Apple'
                              ? Icons.apple
                              : Icons.g_mobiledata,
                          size: provider == 'Apple' ? 20 : 26,
                        ),
                        label: Text('$providerで続ける'),
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
                      focusNode: _nicknameFocus,
                      maxLength: nicknameMaxLength,
                      textInputAction: TextInputAction.next,
                      autovalidateMode: _autovalidate('nickname'),
                      onChanged: (_) => setState(() {}),
                      decoration: InputDecoration(
                        labelText: 'ニックネーム',
                        // 入力の途中は、足りないことを赤くせずに下へ案内する。
                        helperText: _nickname.text.isEmpty
                            ? '$nicknameMinLength〜$nicknameMaxLength文字・本名は使わないでください。'
                            : (nicknameProblem(_nickname.text) ??
                                  '$nicknameMinLength〜$nicknameMaxLength文字・本名は使わないでください。'),
                        counterText: '',
                        prefixIcon: const Icon(Icons.person_outline),
                      ),
                      validator: (value) =>
                          _check(value ?? '', nicknameProblem),
                    ),
                    const SizedBox(height: 16),
                  ],
                  TextFormField(
                    key: const ValueKey('auth-email'),
                    controller: _email,
                    focusNode: _emailFocus,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    autocorrect: false,
                    autovalidateMode: _autovalidate('email'),
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      labelText: 'メールアドレス',
                      hintText: 'example@example.com',
                      helperText: _email.text.isNotEmpty
                          ? (emailProblem(_email.text) ??
                                (_mode == AuthMode.register
                                    ? '他の人には公開されません'
                                    : null))
                          : (_mode == AuthMode.register
                                ? '他の人には公開されません'
                                : null),
                      prefixIcon: const Icon(Icons.mail_outline),
                    ),
                    validator: (value) => _check(value ?? '', emailProblem),
                  ),
                  const SizedBox(height: 16),
                  if (_mode != AuthMode.reset) ...[
                    TextFormField(
                      key: const ValueKey('auth-password'),
                      controller: _password,
                      focusNode: _passwordFocus,
                      autovalidateMode: _autovalidate('password'),
                      onChanged: (_) => setState(() {}),
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
                          _check(value ?? '', passwordProblem),
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
                    LegalConsent(
                      termsAgreed: _agreeTerms,
                      privacyAgreed: _agreePrivacy,
                      onTermsChanged: (value) =>
                          setState(() => _agreeTerms = value),
                      onPrivacyChanged: (value) =>
                          setState(() => _agreePrivacy = value),
                    ),
                  ],
                  if (_error != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        _error!,
                        key: const ValueKey('auth-error'),
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                          fontSize: 13,
                          height: 1.6,
                        ),
                      ),
                    ),
                  const SizedBox(height: 16),
                  FilledButton(
                    key: const ValueKey('auth-submit'),
                    // 登録は、利用規約とプライバシーポリシーの両方を読んで
                    // チェックがついてから押せる。
                    onPressed:
                        _busy ||
                            (_mode == AuthMode.register &&
                                !(_agreeTerms && _agreePrivacy))
                        ? null
                        : _submit,
                    child: Text(
                      _busy
                          ? '通信しています…'
                          : switch (_mode) {
                              AuthMode.login => 'ログインする',
                              AuthMode.register => '登録する',
                              AuthMode.reset => '再設定メールを送る',
                            },
                    ),
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
                  if (_mode == AuthMode.reset) ...[
                    const SizedBox(height: 12),
                    const Text(
                      'パスワード再設定は準備中です。\n入力内容は送信されません。',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 12, height: 1.7),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

/// docs/design S-10と同じ、ロゴ+大きな太陽を使う見出し。
class _AuthHeader extends StatelessWidget {
  const _AuthHeader({required this.title, required this.mode});
  final String title;
  final AuthMode mode;

  @override
  Widget build(BuildContext context) {
    final showDecoration = fitsDecoration(context);
    return Stack(
      clipBehavior: Clip.none,
      children: [
        if (showDecoration) const SizedBox(height: 154),
        if (showDecoration) ...[
          Positioned(
            top: 30,
            right: -40,
            child: ExcludeSemantics(
              child: IgnorePointer(
                child: AppAsset(
                  AppDecorations.cloudSoft,
                  width: 150,
                  height: 150,
                ),
              ),
            ),
          ),
          Positioned(
            top: -36,
            right: -50,
            child: ExcludeSemantics(
              child: AppAsset(
                AppDecorations.sunSmiling,
                width: 190,
                height: 190,
              ),
            ),
          ),
        ],
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.only(right: showDecoration ? 72 : 0),
              child: showDecoration
                  ? Semantics(
                      header: true,
                      label: 'ひと息',
                      child: Image.asset(
                        AppBrand.logo,
                        width: (MediaQuery.sizeOf(context).width * 0.36).clamp(
                          110.0,
                          150.0,
                        ),
                        fit: BoxFit.contain,
                        alignment: Alignment.centerLeft,
                        excludeFromSemantics: true,
                      ),
                    )
                  : const Text(
                      'ひと息',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
            ),
            const SizedBox(height: 12),
            Text(switch (mode) {
              AuthMode.login => 'おかえりなさい。',
              AuthMode.register => 'がんばる毎日に、\nやさしいつながりを。',
              AuthMode.reset => '登録したメールアドレスを\n入力してください。',
            }, style: const TextStyle(fontSize: 14.5, height: 1.7)),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
            ),
          ],
        ),
      ],
    );
  }
}
