import '../../core/constants/app_icons.dart';
import '../../core/constants/child_age_range.dart';
import '../../domain/models/picked_avatar.dart';
import '../../domain/models/user_profile.dart';
import '../../domain/repositories/profile_repository.dart';

class MockProfileRepository implements ProfileRepository {
  static const _profiles = [
    UserProfile(
      id: 'sample-hana',
      nickname: 'はな',
      avatarAsset: AppAvatars.defaultTulip,
      bio: '慌ただしい毎日、\nここでひと息ついています。',
      childAgeBand: 'age_4_6',
    ),
    UserProfile(
      id: 'sample-komorebi',
      nickname: 'こもれび',
      avatarAsset: AppAvatars.defaultSprout,
      bio: '子育ての気持ちを、少しずつ。',
      childAgeBand: 'age_0_1',
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
  bool get isSample => true;

  /// サンプルでは、保存しない(画面確認用)。
  @override
  Future<void> updateProfile({
    String? bio,
    String? iconKey,
    ChildAgeRange? childAgeRange,
    bool clearChildAgeRange = false,
    bool confirmed = false,
  }) async {}

  @override
  Future<void> uploadAvatar(PickedAvatar avatar) async {}

  @override
  Future<void> changeNickname({
    required String nickname,
    bool confirmed = false,
  }) async {}

  @override
  Future<UserProfile?> fetchProfile(String userId) async =>
      _profiles.where((profile) => profile.id == userId).firstOrNull;
}
