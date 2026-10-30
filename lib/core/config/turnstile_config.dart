import 'flavor.dart';

/// ボット対策(Cloudflare Turnstile)の設定。
///
/// Site Keyは公開してよい鍵(画面に出す部品が使う)。Secret Keyは、このリポジトリには
/// 置かない(運営がSupabaseの画面に直接入れる)。
class TurnstileConfig {
  TurnstileConfig._();

  /// 開発用のSite Key。許可しているホスト名は、localhost・127.0.0.1。
  static const devSiteKey = '0x4AAAAAAFrELPuF-3fdSzUq';

  /// 本番用のSite Key。許可しているホスト名は、app.kosodate-hitoiki.com だけ。
  static const prodSiteKey = '0x4AAAAAAFrDuR9-TM9gTh6K';

  /// 登録・ログイン・パスワード再設定で、確認の部品(Turnstile)を出して、トークンを送るか。
  ///
  /// 既定は`true`(普通にビルドすれば、確認の部品が出る)。サーバーのCAPTCHA保護が有効な環境では、
  /// トークンが無いと、メールの登録・ログイン・再設定が失敗するため。
  /// 保護が無効な環境(本番を有効にする前など)で出したくないときだけ、
  /// `--dart-define=TURNSTILE=false`でビルドする。
  static const enabled = bool.fromEnvironment('TURNSTILE', defaultValue: true);

  /// `enabled`の代わりに使う値(nullなら`enabled`)。実際のビルドでは、設定しない。
  /// テストが、本物の確認の部品(WebView)を出さないために、`false`にする(test/flutter_test_config.dart)。
  static bool? enabledOverride;

  static String get siteKey => switch (AppConfig.flavor) {
    Flavor.dev => devSiteKey,
    Flavor.prod => prodSiteKey,
  };

  /// アプリ(WebView)で、部品を開くときの「ページの出どころ」。Site Keyが許可している
  /// ホスト名にそろえる(違うと、確認が通らない)。
  static String get appBaseUrl => switch (AppConfig.flavor) {
    Flavor.dev => 'http://localhost/',
    Flavor.prod => 'https://app.kosodate-hitoiki.com/',
  };

  /// 部品の読み込み先。これ以外には、通信しない。
  static const scriptUrl =
      'https://challenges.cloudflare.com/turnstile/v0/api.js?render=explicit';
  static const allowedHost = 'challenges.cloudflare.com';
}
