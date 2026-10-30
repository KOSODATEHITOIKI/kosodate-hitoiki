import 'package:flutter_test/flutter_test.dart';
import 'package:kosodate_hitoiki/core/config/turnstile_config.dart';

void main() {
  test('普通にビルドすれば(オプションなし)、確認の部品(Turnstile)は、有効', () {
    // `--dart-define=TURNSTILE=false`を付けたときだけ、無効になる。このテストを、
    // そのオプションなしで走らせると、既定が有効であることを確かめられる。
    expect(
      const bool.fromEnvironment('TURNSTILE', defaultValue: true),
      TurnstileConfig.enabled,
    );
  });

  test('テストでは、本物の確認の部品を出さない設定に固定している', () {
    expect(TurnstileConfig.enabledOverride, isFalse);
  });
}
