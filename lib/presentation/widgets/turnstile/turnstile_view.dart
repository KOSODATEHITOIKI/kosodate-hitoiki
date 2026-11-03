// 確認の部品を表示する部品を、実行する環境で切り替える。
// Webは公式のスクリプト(turnstile_view_web.dart)、アプリはWebView(turnstile_view_mobile.dart)。
export 'turnstile_view_mobile.dart'
    if (dart.library.js_interop) 'turnstile_view_web.dart';
