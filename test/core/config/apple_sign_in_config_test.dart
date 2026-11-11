import 'package:flutter_test/flutter_test.dart';
import 'package:kosodate_hitoiki/core/config/apple_sign_in_config.dart';
import 'package:kosodate_hitoiki/core/config/flavor.dart';

void main() {
  tearDown(() => AppConfig.setFlavor(Flavor.dev));

  test('アプリ(iOS)では、Bundle IDで名乗る(xcconfigと同じ値)', () {
    AppConfig.setFlavor(Flavor.dev);
    expect(AppleSignInConfig.clientId, 'com.kosodatehitoiki.dev');
    AppConfig.setFlavor(Flavor.prod);
    expect(AppleSignInConfig.clientId, 'com.kosodatehitoiki');
  });

  test('Apple JSは、Appleの公式の配信元からだけ読み込む(CSPで許可する先と同じ)', () {
    final url = Uri.parse(AppleSignInConfig.scriptUrl);
    expect(url.scheme, 'https');
    expect(url.host, 'appleid.cdn-apple.com');
  });
}
