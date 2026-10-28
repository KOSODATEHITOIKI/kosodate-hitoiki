import 'flavor.dart';

/// 利用規約の版数(`profile-create`の`terms_version`)。
///
/// 版は、規約を公開した日付(規約を変えたら、新しい日付にする。同意の記録に残る)。
/// devは、仮の値を使う(本番の同意の記録に、仮の値が残らないように、分けている)。
class TermsConfig {
  TermsConfig._();

  static const devPlaceholderVersion = 'dev-draft';

  /// 本番の版(運営が決定。2026-10-28)。
  static const prodVersion = '2026-10-28';

  static String get version => switch (AppConfig.flavor) {
    Flavor.dev => devPlaceholderVersion,
    Flavor.prod => prodVersion,
  };
}
