import 'package:supabase_flutter/supabase_flutter.dart';

import 'flavor.dart';

/// Supabaseクライアントの初期化。接続先は[AppConfig.flavor]で切り替える。
///
/// キーは「公開用キー(publishable key／旧anon key)」であり、クライアントアプリに
/// 同梱される前提の公開情報(秘匿すべきAPIキーではない)。実際のアクセス制御は
/// Supabase側のRLS(行単位の権限)で行う(docs/全体設計書.md 7章)。
/// secret／service_role相当の特権キーはクライアントアプリには一切含めず、
/// kosodate-hitoiki-backend側でのみ扱う。
class SupabaseConfig {
  SupabaseConfig._();

  /// prodのSupabaseプロジェクトは未作成(2026-10-21時点)。作成後に差し替える。
  static const _prodPlaceholderUrl = 'https://your-project.supabase.co';

  static String get _url => switch (AppConfig.flavor) {
    Flavor.dev => 'https://djbizophhqtlqmlabhdo.supabase.co',
    Flavor.prod => _prodPlaceholderUrl,
  };

  /// アップロードされたアカウント画像の公開URL(Storageの`avatars`バケット)。
  /// [avatarPath]はAPIの`avatar_path`(`<user_id>/<id>.png`)。
  static String avatarUrl(String avatarPath) =>
      '$_url/storage/v1/object/public/avatars/$avatarPath';

  static String get _publishableKey => switch (AppConfig.flavor) {
    Flavor.dev => 'sb_publishable_e9JHW9PnR1fb3qNVQVkwsQ_30-GHwsk',
    Flavor.prod => 'your-publishable-key',
  };

  static Future<void> initialize() async {
    if (_url == _prodPlaceholderUrl) {
      throw StateError('prodのSupabase接続先が未設定です(supabase_config.dart)');
    }
    await Supabase.initialize(
      url: _url,
      // supabase_flutterのパラメーター名は旧称のanonKey。publishable keyもここに渡す。
      // ignore: deprecated_member_use
      anonKey: _publishableKey,
    );
  }
}
