import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/config/apple_sign_in_config.dart';
import '../../core/config/auth_config.dart';
import '../../core/web/apple_js.dart';

/// Appleの画面を出して、認証情報を受け取る処理(`SignInWithApple.getAppleIDCredential`)。
typedef AppleCredentialGetter =
    Future<AuthorizationCredentialAppleID> Function({
      required List<AppleIDAuthorizationScopes> scopes,
      String? nonce,
    });

/// この端末で、Appleでサインインを出すか。iOSのアプリ(審査ガイドライン4.8)と、Web
/// (iPhoneでAppleで登録した人が、Webでも使えるように。Issue #185)。Androidは出さない。
bool get appleSignInSupported =>
    kIsWeb || defaultTargetPlatform == TargetPlatform.iOS;

/// Appleで登録した(Appleの認証が紐づいた)アカウントか。退会のときに、Appleとの連携の
/// 解除が要るかを決める。
bool usesAppleSignIn(User? user) {
  if (user == null) return false;
  if (user.identities?.any((i) => i.provider == 'apple') ?? false) return true;
  final providers = user.appMetadata['providers'];
  return providers is List && providers.contains('apple');
}

/// メール/Google/Appleログインを扱う認証リポジトリ(決定: docs/全体設計書.md 2章 F-02)。
class AuthRepository {
  /// [captchaRequired]がtrueのとき、登録・ログイン・パスワード再設定(メール)に、確認の部品
  /// (Turnstile)のトークンを付ける。トークンは、呼ぶ瞬間に[takeCaptchaToken]で取り出す
  /// (1回限りなので、取り出したら、呼び出し側が消す)。
  /// トークンがないときは、通信せずに、失敗にする(トークンなしでは進めない)。
  ///
  /// [getAppleCredential]は、Appleの画面を出す処理(テストで差し替える)。
  AuthRepository(
    this._client, {
    this.captchaRequired = false,
    String? Function()? takeCaptchaToken,
    AppleCredentialGetter? getAppleCredential,
  }) : _takeCaptchaToken = takeCaptchaToken,
       _getAppleCredential = getAppleCredential ?? _defaultGetAppleCredential;

  final SupabaseClient _client;
  final bool captchaRequired;
  final String? Function()? _takeCaptchaToken;
  final AppleCredentialGetter _getAppleCredential;

  /// Appleの画面を出す。Webは、Apple JSのポップアップで、サービスIDで名乗る。
  ///
  /// Webでは、ボタンを押した処理の中から、待たずにポップアップを開く(待つと、ブラウザが
  /// ポップアップを止めることがある)。そのため、Apple JSを読み込み済みなら、すぐに呼ぶ。
  /// 読み込みが済んでいないときだけ、待ってから呼ぶ。
  static Future<AuthorizationCredentialAppleID> _defaultGetAppleCredential({
    required List<AppleIDAuthorizationScopes> scopes,
    String? nonce,
  }) {
    if (!kIsWeb) {
      return SignInWithApple.getAppleIDCredential(scopes: scopes, nonce: nonce);
    }
    Future<AuthorizationCredentialAppleID> open() =>
        SignInWithApple.getAppleIDCredential(
          scopes: scopes,
          nonce: nonce,
          webAuthenticationOptions: WebAuthenticationOptions(
            clientId: AppleSignInConfig.clientId,
            redirectUri: AppleSignInConfig.webRedirectUri,
          ),
        );
    if (appleJsLoaded) return open();
    return preloadAppleJs().then((_) => open());
  }

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

  /// Appleでサインインする(iOS・Web)。Appleの画面(iOSは標準の画面、Webはポップアップ)で
  /// 受け取ったIDトークンを、Supabaseに渡してログインする(Supabaseのページへは移らない)。
  /// 利用者が画面を閉じたら、`null`。
  ///
  /// IDトークンの使い回しを防ぐため、毎回ランダムな値(nonce)を作り、Appleには
  /// そのハッシュを、Supabaseには元の値を渡す(Supabaseが、2つが合うかを確かめる)。
  Future<AuthResponse?> signInWithApple() async {
    final rawNonce = _client.auth.generateRawNonce();
    final credential = await _appleCredential(
      scopes: const [AppleIDAuthorizationScopes.email],
      nonce: sha256.convert(utf8.encode(rawNonce)).toString(),
    );
    if (credential == null) return null;
    final idToken = credential.identityToken;
    if (idToken == null) {
      throw const AuthException('Appleの確認ができませんでした。', code: 'apple_no_token');
    }
    return _client.auth.signInWithIdToken(
      provider: OAuthProvider.apple,
      idToken: idToken,
      nonce: rawNonce,
    );
  }

  /// 退会の直前に、もう一度Appleで確認して、新しい「認可コード」を受け取る(iOS・Web)。
  /// サーバー(`account-delete`)が、このコードと[AppleSignInConfig.clientId]で、
  /// Appleとの連携を解除する
  /// (審査ガイドライン5.1.1(v))。利用者が画面を閉じたら、`null`。コードは、ログに出さない。
  Future<String?> appleAuthorizationCode() async {
    final credential = await _appleCredential(scopes: const []);
    return credential?.authorizationCode;
  }

  /// Appleの画面を出す。利用者が閉じたときは、`null`(失敗ではない)。
  Future<AuthorizationCredentialAppleID?> _appleCredential({
    required List<AppleIDAuthorizationScopes> scopes,
    String? nonce,
  }) async {
    try {
      return await _getAppleCredential(scopes: scopes, nonce: nonce);
    } on SignInWithAppleAuthorizationException catch (error) {
      if (error.code == AuthorizationErrorCode.canceled) return null;
      rethrow;
    } on SignInWithAppleCredentialsException catch (error) {
      // Web(Apple JS)は、閉じたことを、エラーの名前で返す。
      if (_webCanceled.any(error.message.contains)) return null;
      rethrow;
    }
  }

  /// Apple JSが、利用者が閉じた・やめたときに返すエラーの名前。
  static const _webCanceled = [
    'popup_closed_by_user',
    'user_cancelled_authorize',
  ];

  /// 退会のとき、認可コードと一緒にサーバーへ送る、Appleに名乗ったID。
  String get appleClientId => AppleSignInConfig.clientId;

  /// Appleの画面を出す準備(Webで、Apple JSを先に読み込む)。アプリでは、何もしない。
  /// 読み込めなくても、ここでは失敗にしない(押したときに、もう一度読み込む)。
  Future<void> prepareAppleSignIn() async {
    if (!kIsWeb) return;
    try {
      await preloadAppleJs();
    } catch (_) {}
  }

  Future<void> signOut() => _client.auth.signOut();

  /// この端末のログインだけを外す。サーバーへ問い合わせないので、アカウントを削除した
  /// あと(サーバー側のセッションがもうない)でも、確実に端末のログイン状態を消せる。
  Future<void> signOutLocal() =>
      _client.auth.signOut(scope: SignOutScope.local);
}
