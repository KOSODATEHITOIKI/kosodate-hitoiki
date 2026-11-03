import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:kosodate_hitoiki/core/config/auth_config.dart';

/// 認証メールのリンクから戻るURLは、Supabaseの「Redirect URLs」・Androidのintent-filter・
/// iOSのURLスキームの3か所で同じにする。アプリ側の2か所が、定数とずれていないことを確かめる。
void main() {
  final uri = Uri.parse(authCallbackUrl);

  test('Androidのintent-filterが、同じスキームとホストを受け取る', () {
    final manifest = File(
      'android/app/src/main/AndroidManifest.xml',
    ).readAsStringSync();
    expect(
      manifest,
      contains('android:scheme="${uri.scheme}" android:host="${uri.host}"'),
    );
    // リンクはsupabase_flutterが処理する(Flutter標準の画面遷移への変換は切る)。
    expect(manifest, contains('flutter_deeplinking_enabled'));
  });

  test('iOSのURLスキームが、同じスキームを受け取る', () {
    final plist = File('ios/Runner/Info.plist').readAsStringSync();
    expect(plist, contains('<string>${uri.scheme}</string>'));
    expect(plist, contains('FlutterDeepLinkingEnabled'));
  });
}
