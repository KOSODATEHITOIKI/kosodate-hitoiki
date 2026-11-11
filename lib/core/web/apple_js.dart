// Webで、Appleでサインインの公式の部品(Apple JS)を読み込む。アプリ(iOS)は、iOS標準の
// 画面を使うので、何もしない。
//
// 読み込みは、Appleの画面を出す画面(ログイン・退会)を開いたときだけ行う。ほかの画面では、
// Appleへ通信しない。ボタンを押してから読み込むと、待つ間に、ブラウザがポップアップを
// 止めることがあるため、画面を開いたときに、先に読み込んでおく([preloadAppleJs])。
export 'apple_js_stub.dart' if (dart.library.js_interop) 'apple_js_web.dart';
