/// 認証メール(パスワード再設定など)のリンクから、アプリへ戻るためのURL。
///
/// 次の3か所を、同じ値にそろえる。
/// - Supabaseの「Authentication > URL Configuration > Redirect URLs」
/// - Android: android/app/src/main/AndroidManifest.xml のintent-filter
/// - iOS: ios/Runner/Info.plist のCFBundleURLTypes
const authCallbackUrl = 'kosodatehitoiki://auth-callback';
