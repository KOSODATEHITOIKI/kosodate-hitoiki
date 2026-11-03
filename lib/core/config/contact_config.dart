/// 問い合わせ窓口(運営)。設定の「お問い合わせ」から、メールを開く。
class ContactConfig {
  ContactConfig._();

  static const email = 'contact@kosodate-hitoiki.com';

  /// 件名の初期値(運営が、アプリからの問い合わせと分かるように)。
  static const subject = '【ひと息】お問い合わせ';

  /// メールを開くリンク。
  static Uri get mailto => Uri(
    scheme: 'mailto',
    path: email,
    // 空白は「+」ではなく「%20」にする(メールアプリによって、「+」のまま出るため)。
    query: 'subject=${Uri.encodeComponent(subject)}',
  );
}
