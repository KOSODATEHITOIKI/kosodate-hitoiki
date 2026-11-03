/// パスワードの条件。**devのSupabase Authの設定と同じ値**(2026-10-21に、
/// 弱いパスワードでの登録が断られる応答から確認した)。
///
/// 要件定義書ではパスワード条件は未決定(8.5)。決まって、またはバックエンドの
/// 設定が変わったら、ここと画面の案内を合わせる。条件を満たすかの最終判定は
/// Supabase Authが行い、この値は入力中に「足りないこと」を案内するためだけに使う。
class PasswordPolicy {
  PasswordPolicy._();

  static const minLength = 10;
  static final lower = RegExp('[a-z]');
  static final upper = RegExp('[A-Z]');
  static final digit = RegExp('[0-9]');

  /// 条件の説明(入力欄の下に常に出す)。
  static const description = '$minLength文字以上で、英大文字・英小文字・数字を、それぞれ1文字以上入れてください。';
}
