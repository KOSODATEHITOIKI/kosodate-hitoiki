/// 投稿の話題(運営が用意した少数の種類。投稿に1つ付けられる(任意)。「その他」はなく、
/// 話題を付けないことで表す)。絞り込みとミュートにも使う。
class Topic {
  const Topic({required this.id, required this.label});

  final int id;

  /// 画面に出す文言(運営が直せる)。
  final String label;

  @override
  bool operator ==(Object other) =>
      other is Topic && other.id == id && other.label == label;

  @override
  int get hashCode => Object.hash(id, label);
}
