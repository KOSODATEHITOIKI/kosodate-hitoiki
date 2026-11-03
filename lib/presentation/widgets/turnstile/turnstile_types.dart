import 'package:flutter/widgets.dart';

/// 確認の部品(Cloudflare Turnstile)を表示する部品を作る関数。
/// アプリはWebView、Webは公式のスクリプトで表示する(テストでは差し替える)。
///
/// - [onToken]: 確認が済んで、トークンを受け取った。トークンは、ログに出さない。
/// - [onExpired]: トークンの期限が切れた(使えない)。
/// - [onError]: 部品を読み込めない・確認できない(通信の失敗、ブロックなど)。
typedef TurnstileViewBuilder =
    Widget Function({
      Key? key,
      required String siteKey,
      required ValueChanged<String> onToken,
      required VoidCallback onExpired,
      required VoidCallback onError,
    });
