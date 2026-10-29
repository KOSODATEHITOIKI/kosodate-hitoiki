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
  /// バックエンドで、SupabaseのCAPTCHA保護を有効にするのと同時に、trueにする(運営と合わせる)。
  /// 有効にする前に出しても、利用者の手間が増えるだけなので、それまでは出さない。
  /// 手元の確認は、`--dart-define=TURNSTILE=true`で、出せる。
  static const enabled = bool.fromEnvironment('TURNSTILE');

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
