import 'package:flutter_test/flutter_test.dart';
import 'package:kosodate_hitoiki/core/config/flavor.dart';
import 'package:kosodate_hitoiki/core/config/terms.dart';

void main() {
  tearDown(() => AppConfig.setFlavor(Flavor.dev));

  test('本番の版は、運営が決めた日付。devは、仮の値(本番の記録に、仮の値が残らない)', () {
    AppConfig.setFlavor(Flavor.prod);
    expect(TermsConfig.version, '2026-10-28');
    AppConfig.setFlavor(Flavor.dev);
    expect(TermsConfig.version, 'dev-draft');
  });
}
