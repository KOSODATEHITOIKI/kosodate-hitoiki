import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/config/auth_config.dart';

/// メール/Google/Appleログインを扱う認証リポジトリ(決定: docs/全体設計書.md 2章 F-02)。
class AuthRepository {
  AuthRepository(this._client);

  final SupabaseClient _client;

  /// ログイン状態の変化(ログイン・ログアウト・トークン更新)。
  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;

  User? get currentUser => _client.auth.currentUser;

  Future<AuthResponse> signUpWithEmail({
    required String email,
    required String password,
    Map<String, dynamic>? data,
  }) {
    return _client.auth.signUp(email: email, password: password, data: data);
  }

  Future<AuthResponse> signInWithEmail({
    required String email,
    required String password,
  }) {
    return _client.auth.signInWithPassword(email: email, password: password);
  }

  /// 登録の確認メールを、もう一度送る。
  Future<ResendResponse> resendSignupEmail(String email) {
    return _client.auth.resend(type: OtpType.signup, email: email);
  }

  /// パスワード再設定のメールを送る。登録の有無は、応答からも分からない(Supabaseの仕様)。
  /// メールのリンクは、アプリ([authCallbackUrl])へ戻る。
  Future<void> sendPasswordReset(String email) {
    return _client.auth.resetPasswordForEmail(
      email,
      redirectTo: authCallbackUrl,
    );
  }

  /// 新しいパスワードにする(メールのリンクから戻った状態で呼ぶ)。
  Future<UserResponse> updatePassword(String newPassword) {
    return _client.auth.updateUser(UserAttributes(password: newPassword));
  }

  Future<bool> signInWithGoogle() {
    return _client.auth.signInWithOAuth(OAuthProvider.google);
  }

  Future<bool> signInWithApple() {
    return _client.auth.signInWithOAuth(OAuthProvider.apple);
  }

  Future<void> signOut() => _client.auth.signOut();

  /// この端末のログインだけを外す。サーバーへ問い合わせないので、アカウントを削除した
  /// あと(サーバー側のセッションがもうない)でも、確実に端末のログイン状態を消せる。
  Future<void> signOutLocal() =>
      _client.auth.signOut(scope: SignOutScope.local);
}
