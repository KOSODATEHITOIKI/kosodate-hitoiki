import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/constants/app_icons.dart';
import '../../domain/models/user_profile.dart';
import '../../domain/repositories/profile_repository.dart';

/// プロフィールの取得。自分のプロフィールは`profiles`(自己紹介・年齢帯を含む)、
/// ほかの人は`public_profiles`(ニックネーム・アイコンだけ)から読む。
/// 自己紹介・年齢帯は、初期版では本人と運営者のみが読める
/// (バックエンド 決定ログ 2026-09-30)。`public_profiles`は、自分と、公開中の投稿・
/// コメントの投稿者に限られるため、それ以外のIDは`null`になる。
class SupabaseProfileRepository implements ProfileRepository {
  SupabaseProfileRepository(this._client);

  final SupabaseClient _client;

  @override
  Future<UserProfile?> fetchProfile(String userId) async {
    final mine = _client.auth.currentUser?.id == userId;
    final row = mine
        ? await _client
              .from('profiles')
              .select('id,nickname,bio,child_age_range,icon_key')
              .eq('id', userId)
              .maybeSingle()
        : await _client
              .from('public_profiles')
              .select('id,nickname,icon_key')
              .eq('id', userId)
              .maybeSingle();
    return row == null ? null : profileFromRow(row);
  }

  /// APIの行をプロフィールにする。アップロード画像(`avatar_path`)は、段8で扱う。
  static UserProfile profileFromRow(Map<String, dynamic> row) => UserProfile(
    id: row['id'] as String,
    nickname: row['nickname'] as String? ?? '',
    avatarAsset: AppAvatars.forIconKey(row['icon_key'] as String?),
    bio: row['bio'] as String? ?? '',
    childAgeBand: row['child_age_range'] as String?,
  );
}
