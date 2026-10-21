import 'flavor.dart';

/// 利用規約の版数(`profile-create`の`terms_version`)。
///
/// 規約の本文・版数の付け方は未決定(Notion要件定義書6.4・バックエンド未決事項)。
/// そのため、devだけ仮の値を返す。prodは決まるまで例外にして、
/// 仮の値で同意を記録したまま公開することを防ぐ。
class TermsConfig {
  TermsConfig._();

  static const devPlaceholderVersion = 'dev-draft';

  static String get version => switch (AppConfig.flavor) {
    Flavor.dev => devPlaceholderVersion,
    Flavor.prod => throw StateError('prodの利用規約の版数が未決定です(terms.dart)'),
  };
}
