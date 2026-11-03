// Webで、絵文字のフォントを、同じサイトから読み込む。アプリ(Android・iOS)は、端末の絵文字を使うので何もしない。
// Webは、同梱のフォントに無い文字を、Flutterが外部(fonts.gstatic.com)へ取りに行くが、
// CSPで外部のフォントは許可しない。そのため、使う絵文字だけに絞ったフォントを、web/fonts/に置く。
export 'web_emoji_font_stub.dart'
    if (dart.library.js_interop) 'web_emoji_font_web.dart';
