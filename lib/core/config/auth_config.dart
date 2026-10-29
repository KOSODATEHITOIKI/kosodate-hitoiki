import 'package:flutter/foundation.dart' show kIsWeb;

/// 認証メール(パスワード再設定など)のリンクから、アプリへ戻るためのURL。
///
/// アプリ(Android・iOS)は、独自スキームで戻る。次の3か所を、同じ値にそろえる。
/// - Supabaseの「Authentication > URL Configuration > Redirect URLs」
/// - Android: android/app/src/main/AndroidManifest.xml のintent-filter
/// - iOS: ios/Runner/Info.plist のCFBundleURLTypes
///
/// Webは、独自スキームが使えないので、いま開いているサイトのURL(例: `https://app.kosodate-hitoiki.com/`)
/// へ戻る。このURLも、SupabaseのRedirect URLsに入れておく(バックエンドのIssueで管理)。
final String authCallbackUrl = kIsWeb
    ? '${Uri.base.origin}/'
    : 'kosodatehitoiki://auth-callback';
