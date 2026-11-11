import 'package:flutter/foundation.dart';

import 'auth_config.dart';
import 'flavor.dart';

/// Appleでサインインの設定(iOSとWeb。Androidは出さない)。どれも公開してよい値。
///
/// - iOS: iOS標準のAppleの画面を使う。Appleに対しては、Bundle IDで名乗る
/// - Web: Appleの公式の部品(Apple JS)で、ポップアップを出す。Apple Developerの
///   「サービスID」で名乗る(公開するドメインと戻り先を、サービスIDに登録しておく)
///
/// SupabaseのAppleの「Client IDs」には、ここのBundle ID・サービスIDを、すべて入れる
/// (受け取ったIDトークンの宛先が、どれかと合うかを、Supabaseが確かめる)。
class AppleSignInConfig {
  AppleSignInConfig._();

  /// iOSのBundle ID(`ios/Flutter/Dev.xcconfig`・`Prod.xcconfig`と同じ)。
  static const prodBundleId = 'com.kosodatehitoiki';
  static const devBundleId = 'com.kosodatehitoiki.dev';

  /// Web用のサービスID(Apple Developer → Identifiers → Services IDs)。
  static const prodServiceId = 'com.kosodatehitoiki.web';
  static const devServiceId = 'com.kosodatehitoiki.dev.web';

  /// この端末で、Appleに名乗るID。退会のとき、サーバーが、認可コードの交換に使う
  /// (コードは、このIDに対して発行される)。
  static String get clientId => kIsWeb
      ? switch (AppConfig.flavor) {
          Flavor.dev => devServiceId,
          Flavor.prod => prodServiceId,
        }
      : switch (AppConfig.flavor) {
          Flavor.dev => devBundleId,
          Flavor.prod => prodBundleId,
        };

  /// Webで、Appleの確認のあとに戻る先。サービスIDの「Return URLs」に登録する
  /// (ポップアップの形でも、登録と合わないと、Appleがエラーにする)。
  static Uri get webRedirectUri => Uri.parse(authCallbackUrl);

  /// Apple JSの読み込み先。CSPの`script-src`で、これだけを許可する
  /// (`deploy/web/_headers.template`)。
  static const scriptUrl =
      'https://appleid.cdn-apple.com/appleauth/static/jsapi/appleid/1/ja_JP/appleid.auth.js';
}
