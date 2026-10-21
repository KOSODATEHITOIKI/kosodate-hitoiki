/// ブロック中の相手(解除の画面用)。表示に必要な名前と画像だけを持つ。
class BlockedUser {
  const BlockedUser({
    required this.id,
    required this.nickname,
    required this.avatarAsset,
  });

  final String id;
  final String nickname;
  final String avatarAsset;
}
