import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/config/auth_config.dart';

/// メール/Google/Appleログインを扱う認証リポジトリ(決定: docs/全体設計書.md 2章 F-02)。
class AuthRepository {
  /// [captchaRequired]がtrueのとき、登録・ログイン・パスワード再設定(メール)に、確認の部品
  /// (Turnstile)のトークンを付ける。トークンは、呼ぶ瞬間に[takeCaptchaToken]で取り出す
  /// (1回限りなので、取り出したら、呼び出し側が消す)。
  /// トークンがないときは、通信せずに、失敗にする(トークンなしでは進めない)。
  AuthRepository(
    this._client, {
    this.captchaRequired = false,
    String? Function()? takeCaptchaToken,
  }) : _takeCaptchaToken = takeCaptchaToken;

  final SupabaseClient _client;
  final bool captchaRequired;
  final String? Function()? _takeCaptchaToken;

  /// 確認の部品のトークン。使わない設定のときは、null(何も付けない)。
  String? _captcha() {
    if (!captchaRequired) return null;
    final token = _takeCaptchaToken?.call();
    if (token == null || token.isEmpty) {
      throw const AuthException('確認が済んでいません。', code: 'captcha_required');
    }
    return token;
  }

  /// ログイン状態の変化(ログイン・ログアウト・トークン更新)。
  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;

  User? get currentUser => _client.auth.currentUser;

  Future<AuthResponse> signUpWithEmail({
    required String email,
    required String password,
    Map<String, dynamic>? data,
  }) {
    return _client.auth.signUp(
      email: email,
      password: password,
      data: data,
      captchaToken: _captcha(),
    );
  }

  Future<AuthResponse> signInWithEmail({
    required String email,
    required String password,
  }) {
    return _client.auth.signInWithPassword(
      email: email,
      password: password,
      captchaToken: _captcha(),
    );
  }

  /// 登録の確認メールを、もう一度送る。
  Future<ResendResponse> resendSignupEmail(String email) {
    return _client.auth.resend(
      type: OtpType.signup,
      email: email,
      captchaToken: _captcha(),
    );
  }

  /// パスワード再設定のメールを送る。登録の有無は、応答からも分からない(Supabaseの仕様)。
  /// メールのリンクは、アプリ([authCallbackUrl])へ戻る。
  Future<void> sendPasswordReset(String email) {
    return _client.auth.resetPasswordForEmail(
      email,
      redirectTo: authCallbackUrl,
      captchaToken: _captcha(),
    );
  }

  /// パスワード再設定の確認コード(メールに書かれた数字)を確認する。成功すると、再設定用の
  /// ログイン状態になり、続けて[updatePassword]で新しいパスワードを決められる。
  /// コードは、1回限り。ログには出さない(エラーにも、含めない)。
  Future<AuthResponse> verifyRecoveryCode({
    required String email,
    required String code,
  }) {
    return _client.auth.verifyOTP(
      email: email,
      token: code,
      type: OtpType.recovery,
    );
  }

  /// 新しいパスワードにする(確認コードの確認のあと、または、メールのリンクから戻った状態で呼ぶ)。
  Future<UserResponse> updatePassword(String newPassword) {
    return _client.auth.updateUser(UserAttributes(password: newPassword));
  }

  /// Googleの認証画面(ブラウザ)を開く。開けたら`true`。認証が済むと、リンク
  /// ([authCallbackUrl])でアプリへ戻り、ログイン状態の変化として届く。
  Future<bool> signInWithGoogle() {
    return _client.auth.signInWithOAuth(
      OAuthProvider.google,
      redirectTo: authCallbackUrl,
    );
  }

  /// フェーズ2で、画面に出して使う。
  Future<bool> signInWithApple() {
    return _client.auth.signInWithOAuth(
      OAuthProvider.apple,
      redirectTo: authCallbackUrl,
    );
  }

  Future<void> signOut() => _client.auth.signOut();

  /// この端末のログインだけを外す。サーバーへ問い合わせないので、アカウントを削除した
  /// あと(サーバー側のセッションがもうない)でも、確実に端末のログイン状態を消せる。
  Future<void> signOutLocal() =>
      _client.auth.signOut(scope: SignOutScope.local);
}
