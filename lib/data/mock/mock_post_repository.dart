import '../../core/constants/app_icons.dart';
import '../../domain/models/post.dart';
import '../../domain/repositories/post_repository.dart';

/// 画面確認・結合用のモック実装。docs/design/S-02・S-05のサンプル文言を使用。
/// バックエンド(Issue #7等)が用意でき次第、Supabase実装に差し替える。
class MockPostRepository implements PostRepository {
  MockPostRepository() : _posts = List.of(_seed);

  final List<Post> _posts;

  static final DateTime _now = DateTime.now();

  static final List<Post> _seed = [
    Post(
      id: 'p1',
      authorName: 'こもれび',
      authorAvatarAsset: AppAvatars.defaultSprout,
      createdAt: _now.subtract(const Duration(minutes: 5)),
      type: PostType.grumble,
      responseMode: ResponseMode.listening,
      body: '寝かしつけに1時間。\n私も今日はもう閉店したい。',
      empathyCount: 12,
      commentCount: 0,
      isMine: true,
    ),
    Post(
      id: 'p2',
      authorName: 'はな',
      authorAvatarAsset: AppAvatars.defaultTulip,
      createdAt: _now.subtract(const Duration(minutes: 20)),
      type: PostType.consult,
      responseMode: ResponseMode.advice,
      body: 'ごはんを食べない日、\nみんなはどうしてる？',
      empathyCount: 12,
      commentCount: 3,
      isSaved: true,
    ),
    Post(
      id: 'p3',
      authorName: 'みみ',
      authorAvatarAsset: AppAvatars.defaultLittleBird,
      createdAt: _now.subtract(const Duration(minutes: 10)),
      type: PostType.tips,
      responseMode: ResponseMode.advice,
      body:
          '夜泣きが落ち着いた方法をシェアします。\n'
          '生後8か月ごろから続いた夜泣きで、毎晩つらかったのですが、'
          '生活リズムを整えたら少しずつよくなりました。うちでやってよかったことを'
          'まとめてみます。',
      empathyCount: 9,
      commentCount: 5,
      isSaved: true,
    ),
    Post(
      id: 'p4',
      authorName: 'はるママ',
      authorAvatarAsset: AppAvatars.defaultSun,
      createdAt: _now.subtract(const Duration(hours: 1)),
      type: PostType.grumble,
      responseMode: ResponseMode.advice,
      body:
          'また夜泣きで全然寝られない…\n'
          '昨晩も夜泣きで何度も起きてしまい、もう限界です…。'
          'みなさんはどうやって乗り越えていますか？ちょっと聞いてほしいです。',
      empathyCount: 6,
      commentCount: 2,
    ),
    Post(
      id: 'p5',
      authorName: 'こもれび',
      authorAvatarAsset: AppAvatars.defaultSprout,
      createdAt: _now.subtract(const Duration(days: 1)),
      type: PostType.tips,
      responseMode: ResponseMode.listening,
      body: '離乳食を嫌がる時期、無理せず好きなものだけにしたら\n私の気持ちもラクになりました。',
      empathyCount: 8,
      commentCount: 0,
      isMine: true,
    ),
  ];

  @override
  Future<List<Post>> fetchFeed() async {
    final posts = List.of(_posts)
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return posts;
  }

  @override
  Future<List<Post>> search({required String query, PostType? type}) async {
    final trimmed = query.trim();
    return _posts.where((post) {
      final matchesQuery = trimmed.isEmpty || post.body.contains(trimmed);
      final matchesType = type == null || post.type == type;
      return matchesQuery && matchesType;
    }).toList()..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  @override
  Future<List<Post>> fetchMyPosts() async {
    return _posts.where((post) => post.isMine).toList();
  }

  @override
  Future<List<Post>> fetchSavedPosts() async {
    return _posts.where((post) => post.isSaved).toList();
  }

  @override
  Future<void> toggleSaved(String postId) async {
    final index = _posts.indexWhere((post) => post.id == postId);
    if (index == -1) {
      return;
    }
    _posts[index] = _posts[index].copyWith(isSaved: !_posts[index].isSaved);
  }
}
