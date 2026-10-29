import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:kosodate_hitoiki/presentation/widgets/app_asset.dart';

import '../../../core/constants/app_brand.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_icons.dart';
import '../../../core/config/password_policy.dart';
import '../../../core/utils/accessibility.dart';
import '../../../core/constants/app_layout.dart';
import '../../widgets/desktop_hero_panel.dart';
import '../../providers/auth_provider.dart';
import '../../providers/captcha_provider.dart';
import '../../providers/profile_providers.dart';
import '../../widgets/turnstile/turnstile_field.dart';
import 'auth_messages.dart';
import 'auth_validators.dart';
import 'legal_consent.dart';
import 'ensure_profile.dart';

/// S-10。メール+パスワードの登録・ログインはSupabase Authに接続済み。
/// Googleは、認証画面(ブラウザ)からリンクでアプリへ戻って続ける(Supabase側のプロバイダ
/// 設定が必要)。Appleは、フェーズ2で追加する。パスワード再設定は、メールのリンクから
/// 戻って新しいパスワードを決める(new_password_page.dart)。
enum AuthMode { login, register, reset }

class AuthPage extends ConsumerStatefulWidget {
  const AuthPage({super.key, this.initialMode = AuthMode.login});
  final AuthMode initialMode;

  /// いま開いている認証画面の数。開いている間は、この画面が、ログイン後のプロフィールの
  /// 確認・作成を行う(アプリ全体の確認と重ならないようにする)。
  static int openCount = 0;
  @override
  ConsumerState<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends ConsumerState<AuthPage> {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _passwordConfirm = TextEditingController();
  final _nickname = TextEditingController();
  late AuthMode _mode = widget.initialMode;
  bool _obscure = true;
  bool _agreeTerms = false;
  bool _agreePrivacy = false;
  bool _confirmedAge = false;
  bool _busy = false;
  String? _error;

  /// 入力欄を一度離れた(または送信を試した)項目。赤い表示は、この項目が
  /// まだ間違っているときだけ出す。入力の途中では出さない。
  final _touched = <String>{};

  /// 登録・ログインを押したことがあるか。空欄を赤くするのは、押したあとだけ。
  bool _submitted = false;
  final _nicknameFocus = FocusNode();

  /// 確認の部品(Turnstile)。使う設定のときだけ、画面に出す。トークンは1回限りなので、
  /// 登録・ログインなどを試すたびに、やり直す([_resetCaptcha])。
  final _turnstileKey = GlobalKey<TurnstileFieldState>();
  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();
  final _passwordConfirmFocus = FocusNode();

  /// 登録後、確認メールの送信先(メール確認が必要な設定のとき)。
  String? _sentTo;

  /// 再設定メールの送信先。登録の有無にかかわらず、送信後は同じ画面を出す。
  String? _resetSentTo;

  /// Googleの認証画面(ブラウザ)を開いて、アプリへ戻るのを待っている間。
  bool _googleWaiting = false;

  /// 確認メールを再送できるまでの残り秒数。連続で押せないようにする。
  static const _resendCooldownSeconds = 60;
  int _resendWait = 0;
  bool _resending = false;
  Timer? _cooldownTimer;

  String get _title => switch (_mode) {
    AuthMode.login => 'ログイン',
    AuthMode.register => '会員登録',
    AuthMode.reset => 'パスワード再設定',
  };

  @override
  void initState() {
    super.initState();
    AuthPage.openCount++;
    for (final entry in {
      'nickname': _nicknameFocus,
      'email': _emailFocus,
      'password': _passwordFocus,
      'passwordConfirm': _passwordConfirmFocus,
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

  void _startCooldown() {
    _cooldownTimer?.cancel();
    setState(() => _resendWait = _resendCooldownSeconds);
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      setState(() => _resendWait = (_resendWait - 1).clamp(0, 9999));
      if (_resendWait == 0) timer.cancel();
    });
  }

  /// 「確認メールを送りました」の画面にする。登録済みのアドレスでも、同じ画面・
  /// 同じ待ち時間にする(登録の有無を、見え方から推測させない)。
  void _showSent(String email) {
    setState(() => _sentTo = email);
    _startCooldown();
  }

  /// 使い終わった確認のトークンを消して、新しい確認をやり直す。
  void _resetCaptcha() {
    if (ref.read(captchaEnabledProvider)) _turnstileKey.currentState?.reset();
  }

  void _snack(String message) => ScaffoldMessenger.of(
    context,
  ).showSnackBar(SnackBar(content: Text(message)));

  Future<void> _resend() async {
    final email = _sentTo;
    if (email == null || _resendWait > 0 || _resending) return;
    setState(() => _resending = true);
    try {
      await ref.read(authRepositoryProvider).resendSignupEmail(email);
      if (!mounted) return;
      _snack('確認メールをもう一度送りました。');
      _startCooldown();
    } catch (error) {
      if (mounted) _snack(authErrorMessage(error));
    } finally {
      if (mounted) setState(() => _resending = false);
      _resetCaptcha();
    }
  }

  @override
  void dispose() {
    AuthPage.openCount--;
    _cooldownTimer?.cancel();
    _nicknameFocus.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    _passwordConfirmFocus.dispose();
    _email.dispose();
    _password.dispose();
    _passwordConfirm.dispose();
    _nickname.dispose();
    super.dispose();
  }

  void _changeMode(AuthMode mode) {
    FocusScope.of(context).unfocus();
    _form.currentState?.reset();
    _password.clear();
    _passwordConfirm.clear();
    setState(() {
      _mode = mode;
      _obscure = true;
      _agreeTerms = false;
      _agreePrivacy = false;
      _confirmedAge = false;
      _error = null;
      _sentTo = null;
      _resetSentTo = null;
      _resendWait = 0;
      _touched.clear();
      _submitted = false;
    });
  }

  /// Googleで続ける。認証画面(ブラウザ)を開き、戻ってきたときのログイン状態の変化を
  /// [build]の`ref.listen`で受ける。同意・ニックネームは、初めての利用者だけ、
  /// ログイン後のプロフィール作成の画面で決める。
  Future<void> _google() async {
    if (_busy) return;
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final opened = await ref.read(authRepositoryProvider).signInWithGoogle();
      if (!mounted) return;
      setState(() {
        _googleWaiting = opened;
        if (!opened) _error = 'Googleの認証画面を開けませんでした。もう一度お試しください。';
      });
    } catch (error) {
      if (mounted) setState(() => _error = authErrorMessage(error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  /// Googleの認証から戻ったとき(ログイン状態の変化)。待っていないときは、何もしない。
  Future<void> _onAuthState(AsyncValue<AuthState> next) async {
    if (!_googleWaiting) return;
    if (next.hasError) {
      setState(() {
        _googleWaiting = false;
        _error = 'Googleでのログインを完了できませんでした。もう一度お試しください。';
      });
      return;
    }
    final state = next.valueOrNull;
    if (state?.event != AuthChangeEvent.signedIn || state?.session == null) {
      return;
    }
    setState(() {
      _googleWaiting = false;
      _busy = true;
      _error = null;
    });
    try {
      await _afterSignedInSafely(state!.session!.user);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _submit() async {
    setState(() {
      _submitted = true;
      _touched.addAll(['nickname', 'email', 'password', 'passwordConfirm']);
    });
    final valid = _form.currentState!.validate();
    if (!valid) return;
    FocusScope.of(context).unfocus();
    if (_mode == AuthMode.reset) {
      await _sendReset();
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
      _resetCaptcha();
    }
  }

  /// パスワード再設定のメール。登録の有無を明かさないよう、送信後は常に同じ画面を出す。
  /// 通信できなかったとき、送信回数の制限のとき、確認(ボット対策)に失敗したときだけ、
  /// そのことを伝える(確認の失敗は、メールが送られていないので、「送りました」とは見せない)。
  Future<void> _sendReset() async {
    final email = _email.text.trim();
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref.read(authRepositoryProvider).sendPasswordReset(email);
    } on AuthRetryableFetchException catch (error) {
      if (mounted) setState(() => _error = authErrorMessage(error));
      return;
    } on AuthException catch (error) {
      if (error.code == 'over_email_send_rate_limit' ||
          error.code == 'over_request_rate_limit' ||
          error.code == 'captcha_failed' ||
          error.code == 'captcha_required') {
        if (mounted) setState(() => _error = authErrorMessage(error));
        return;
      }
      // それ以外(未登録など)は、成功と同じに見せる。
    } catch (error) {
      if (mounted) setState(() => _error = authErrorMessage(error));
      return;
    } finally {
      if (mounted) setState(() => _busy = false);
      _resetCaptcha();
    }
    if (mounted) setState(() => _resetSentTo = email);
  }

  Future<void> _register() async {
    final email = _email.text.trim();
    final AuthResponse response;
    try {
      response = await ref
          .read(authRepositoryProvider)
          .signUpWithEmail(
            email: email,
            password: _password.text,
            // 確認メールのリンクを開いたあとにプロフィールを作るための控え。
            // 規約の版数は、プロフィール作成時に送る(同意の記録はサーバー側)。
            data: {'nickname': _nickname.text.trim(), 'terms_agreed': true},
          );
    } on AuthException catch (error) {
      // 登録済みのアドレスでも、成功と同じ画面にする。「すでに使われています」とは
      // 表示しない(利用の事実が漏れる)。
      if (error.code == 'user_already_exists' || error.code == 'email_exists') {
        if (mounted) _showSent(email);
        return;
      }
      rethrow;
    }
    if (!mounted) return;
    if (response.session == null) {
      // メール確認が必要な設定。リンクを開くまでログインできない。
      _showSent(email);
      return;
    }
    await _afterSignedInSafely(response.user);
  }

  Future<void> _login() async {
    final response = await ref
        .read(authRepositoryProvider)
        .signInWithEmail(email: _email.text.trim(), password: _password.text);
    if (!mounted) return;
    await _afterSignedInSafely(response.user);
  }

  /// ログイン自体はできたが、そのあとのプロフィールの確認・作成で失敗したとき。
  /// ログインしたまま「失敗」と見せないよう、ログアウトして、原因を伝える。
  Future<void> _afterSignedInSafely(User? user) async {
    try {
      await _afterSignedIn(user);
    } catch (error) {
      await ref.read(authRepositoryProvider).signOut();
      if (mounted) {
        setState(
          () => _error = withDevDetail(
            'ログインはできましたが、プロフィールの確認に失敗しました。もう一度お試しください。',
            error,
          ),
        );
      }
    }
  }

  /// ログイン後、プロフィールが未作成なら作る(控えがあれば自動、なければ入力画面)。
  /// 完了しなければ、中途半端な状態を残さないようログアウトする。
  Future<void> _afterSignedIn(User? user) async {
    if (user == null) return;
    // 待つ間に画面が閉じられても、プロフィールを取り直せるよう、先に取っておく。
    final container = ProviderScope.containerOf(context);
    final profiles = ref.read(profileRegistrationRepositoryProvider);
    final ready = await ensureProfile(
      context: context,
      profiles: profiles,
      user: user,
    );
    if (!ready) {
      await ref.read(authRepositoryProvider).signOut();
      return;
    }
    // ログイン時に読み込んだ自分のプロフィールは、作成前の(空の)ものかもしれない。取り直す。
    container.invalidate(myProfileProvider);
    if (mounted) Navigator.of(context).maybePop();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AsyncValue<AuthState>>(
      authStateChangesProvider,
      (_, next) => _onAuthState(next),
    );
    final resetSentTo = _resetSentTo;
    final sentTo = _sentTo;
    final Widget page;
    if (resetSentTo != null) {
      page = _resetSentPage();
    } else if (sentTo != null) {
      page = _checkEmailPage(sentTo);
    } else {
      page = _formPage();
    }
    // パソコン向けの広い画面は、左に絵の面、右にフォーム。
    if (!AppLayout.isDesktop(MediaQuery.sizeOf(context).width)) return page;
    return Scaffold(body: DesktopHeroSplit(right: page));
  }

  /// 登録後の「確認メールを送りました」。メール確認が必要な設定のときだけ表示する。
  /// 登録済みのアドレスでも、同じ画面を出す(登録の有無を推測させない)。
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
                const Text(
                  '確認メールを送りました。メール内のボタンを押して、確認を完了してください。',
                  style: TextStyle(height: 1.7),
                ),
                const SizedBox(height: 4),
                Text(
                  '送信先: $email',
                  style: const TextStyle(fontSize: 12, height: 1.7),
                ),
                const SizedBox(height: 20),
                const Text(
                  '届かないときは',
                  style: TextStyle(fontWeight: FontWeight.w700, height: 1.7),
                ),
                const SizedBox(height: 4),
                for (final line in const [
                  '迷惑メールフォルダーを確認する',
                  'メールアドレスの入力ミスがないか確認する',
                  'すでに登録済みの可能性があります。その場合は、ログイン、またはパスワードの再設定をお試しください。',
                ])
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('・', style: TextStyle(height: 1.7)),
                        Expanded(
                          child: Text(
                            line,
                            style: const TextStyle(fontSize: 13, height: 1.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 20),
                FilledButton(
                  key: const ValueKey('auth-to-login'),
                  onPressed: () => _changeMode(AuthMode.login),
                  child: const Text('ログインへ'),
                ),
                const SizedBox(height: 12),
                OutlinedButton(
                  key: const ValueKey('auth-to-reset'),
                  onPressed: () {
                    _changeMode(AuthMode.reset);
                    _email.text = email;
                  },
                  child: const Text('パスワードを再設定する'),
                ),
                const SizedBox(height: 12),
                if (ref.watch(captchaEnabledProvider)) ...[
                  TurnstileField(key: _turnstileKey),
                  const SizedBox(height: 12),
                ],
                OutlinedButton(
                  key: const ValueKey('auth-resend'),
                  onPressed:
                      _resendWait > 0 ||
                          _resending ||
                          (ref.watch(captchaEnabledProvider) &&
                              ref.watch(captchaTokenProvider) == null)
                      ? null
                      : _resend,
                  child: Text(
                    _resendWait > 0
                        ? '確認メールをもう一度送る(あと$_resendWait秒)'
                        : '確認メールをもう一度送る',
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );

  /// パスワード再設定メールの送信後。登録の有無を明かさない文面にする。
  Widget _resetSentPage() => Scaffold(
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
                  '再設定のご案内',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 16),
                const Text(
                  '登録されている場合は、再設定のメールを送りました。'
                  '届かない場合は、迷惑メールを確認するか、アドレスをご確認ください。',
                  key: ValueKey('auth-reset-sent'),
                  style: TextStyle(height: 1.7),
                ),
                const SizedBox(height: 24),
                FilledButton(
                  key: const ValueKey('auth-reset-to-login'),
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
                    // Appleでのログインは、フェーズ2で追加する(それまでは出さない)。
                    for (final provider in ['Google']) ...[
                      OutlinedButton.icon(
                        key: const ValueKey('auth-google'),
                        onPressed: _busy ? null : _google,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.textPrimary,
                          backgroundColor: AppColors.white,
                          minimumSize: const Size.fromHeight(52),
                          side: const BorderSide(color: AppColors.divider),
                        ),
                        // Googleの公式の「G」マーク(4色)。ひと目でGoogleと分かるよう、
                        // 画面の配色には合わせず、そのままの色で出す。
                        icon: const AppAsset(
                          AppIcons.googleG,
                          width: 20,
                          height: 20,
                          excludeFromSemantics: true,
                        ),
                        label: Text('$providerで続ける'),
                      ),
                      if (_googleWaiting)
                        const Padding(
                          padding: EdgeInsets.only(top: 8),
                          child: Text(
                            'ブラウザでGoogleの認証を進めてください。戻ってもログインできないときは、もう一度押してください。',
                            key: ValueKey('auth-google-waiting'),
                            style: TextStyle(fontSize: 12, height: 1.6),
                          ),
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
                        // 登録のときは、条件と、まだ足りないことを下に案内する。
                        helperText: _mode != AuthMode.register
                            ? null
                            : (_password.text.isEmpty
                                  ? PasswordPolicy.description
                                  : (passwordRegisterProblem(_password.text) ??
                                        '条件を満たしています。')),
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
                      validator: (value) => _check(
                        value ?? '',
                        _mode == AuthMode.register
                            ? passwordRegisterProblem
                            : passwordProblem,
                      ),
                    ),
                    if (_mode == AuthMode.register) ...[
                      const SizedBox(height: 16),
                      TextFormField(
                        key: const ValueKey('auth-password-confirm'),
                        controller: _passwordConfirm,
                        focusNode: _passwordConfirmFocus,
                        autovalidateMode: _autovalidate('passwordConfirm'),
                        onChanged: (_) => setState(() {}),
                        obscureText: _obscure,
                        autocorrect: false,
                        enableSuggestions: false,
                        decoration: InputDecoration(
                          labelText: 'パスワード(確認用)',
                          // 入力の途中は、赤くせず、合っているかだけを案内する。
                          helperText: _passwordConfirm.text.isEmpty
                              ? 'もう一度、同じパスワードを入力してください。'
                              : (_passwordConfirm.text == _password.text
                                    ? '一致しています。'
                                    : 'まだ一致していません。'),
                          prefixIcon: const Icon(Icons.lock_outline),
                        ),
                        validator: (value) => _check(
                          value ?? '',
                          (confirm) =>
                              passwordConfirmProblem(_password.text, confirm),
                        ),
                      ),
                    ],
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
                      ageConfirmed: _confirmedAge,
                      onTermsChanged: (value) =>
                          setState(() => _agreeTerms = value),
                      onPrivacyChanged: (value) =>
                          setState(() => _agreePrivacy = value),
                      onAgeChanged: (value) =>
                          setState(() => _confirmedAge = value),
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
                  // ボット対策の確認(使う設定のときだけ)。済むまで、先へは進めない。
                  if (ref.watch(captchaEnabledProvider)) ...[
                    TurnstileField(key: _turnstileKey),
                    const SizedBox(height: 12),
                  ],
                  FilledButton(
                    key: const ValueKey('auth-submit'),
                    // 登録は、利用規約とプライバシーポリシーの両方を読み、18歳以上の
                    // 確認にもチェックがついてから押せる。
                    onPressed:
                        _busy ||
                            (ref.watch(captchaEnabledProvider) &&
                                ref.watch(captchaTokenProvider) == null) ||
                            (_mode == AuthMode.register &&
                                !(_agreeTerms &&
                                    _agreePrivacy &&
                                    _confirmedAge))
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
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

/// 確定デザインS-10と同じ、ロゴ+大きな太陽を使う見出し。
class _AuthHeader extends StatelessWidget {
  const _AuthHeader({required this.title, required this.mode});
  final String title;
  final AuthMode mode;

  @override
  Widget build(BuildContext context) {
    final desktop = AppLayout.isDesktop(MediaQuery.sizeOf(context).width);
    final showDecoration = fitsDecoration(context) && !desktop;
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
            if (!desktop)
              Padding(
                padding: EdgeInsets.only(right: showDecoration ? 72 : 0),
                child: showDecoration
                    ? Semantics(
                        header: true,
                        label: 'ひと息',
                        child: Image.asset(
                          AppBrand.logo,
                          width: (MediaQuery.sizeOf(context).width * 0.36)
                              .clamp(110.0, 150.0),
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
            if (!desktop) const SizedBox(height: 12),
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
