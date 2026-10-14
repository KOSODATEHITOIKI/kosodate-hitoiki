import '../../core/constants/app_icons.dart';
import '../../domain/models/user_profile.dart';
import '../../domain/repositories/profile_repository.dart';

/// 年齢帯は画面確認用のサンプル。選択肢の確定仕様ではない。
class MockProfileRepository implements ProfileRepository {
  static const _profiles = [
    UserProfile(
      id: 'sample-hana',
      nickname: 'はな',
      avatarAsset: AppAvatars.defaultTulip,
      bio: '慌ただしい毎日、\nここでひと息ついています。',
      childAgeBand: '未就学児',
    ),
    UserProfile(
      id: 'sample-komorebi',
      nickname: 'こもれび',
      avatarAsset: AppAvatars.defaultSprout,
      bio: '子育ての気持ちを、少しずつ。',
      childAgeBand: '乳児',
    ),
    UserProfile(
      id: 'sample-mimi',
      nickname: 'みみ',
      avatarAsset: AppAvatars.defaultLittleBird,
      bio: 'コツや体験談を分かち合えたらうれしいです。',
    ),
    UserProfile(
      id: 'sample-haru',
      nickname: 'はるママ',
      avatarAsset: AppAvatars.defaultSun,
    ),
  ];

  @override
  Future<UserProfile?> fetchProfile(String userId) async =>
      _profiles.where((profile) => profile.id == userId).firstOrNull;
}
