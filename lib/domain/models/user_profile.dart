/// 公開プロフィール。メールや過去の投稿は含めない。
class UserProfile {
  const UserProfile({
    required this.id,
    required this.nickname,
    required this.avatarAsset,
    this.bio = '',
    this.childAgeBand,
  });
  final String id;
  final String nickname;
  final String avatarAsset;
  final String bio;
  final String? childAgeBand;
}
