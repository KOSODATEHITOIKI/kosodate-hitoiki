import '../../core/constants/app_icons.dart';
import '../../domain/models/post.dart';
import '../../domain/repositories/post_repository.dart';

/// 画面確認・結合用のモック実装。docs/design/S-02・S-05のサンプル文言を使用。
/// バックエンド(Issue #7等)が用意でき次第、Supabase実装に差し替える。
class MockPostRepository implements PostRepository {
  MockPostRepository() : _posts = List.of(_seed);

  final List<Post> _posts;

  @override
  bool get isSample => true;

  static final DateTime _now = DateTime.now();

  static final List<Post> _seed = [
    Post(
      id: 'p1',
      authorId: 'sample-komorebi',
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
      authorId: 'sample-hana',
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
      authorId: 'sample-mimi',
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
      authorId: 'sample-haru',
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
      authorId: 'sample-komorebi',
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
  Future<Post?> fetchPost(String postId) async =>
      _posts.where((post) => post.id == postId).firstOrNull;

  @override
  Future<List<Post>> fetchMyPosts() async {
    return _posts.where((post) => post.isMine).toList();
  }

  @override
  Future<List<Post>> fetchSavedPosts() async {
    return _posts.where((post) => post.isSaved).toList();
  }

  @override
  Future<CreatedPost> createPost({
    required PostType type,
    required ResponseMode responseMode,
    required String body,
    required String idempotencyKey,
    bool confirmed = false,
  }) async {
    final now = DateTime.now();
    final id = 'mine-${_posts.length + 1}';
    _posts.insert(
      0,
      Post(
        id: id,
        authorId: 'sample-komorebi',
        authorName: 'こもれび',
        authorAvatarAsset: AppAvatars.defaultSprout,
        createdAt: now,
        type: type,
        responseMode: responseMode,
        body: body.trim(),
        empathyCount: 0,
        commentCount: 0,
        isMine: true,
      ),
    );
    return CreatedPost(id: id, createdAt: now);
  }

  @override
  Future<EditResult> editPost({
    required String postId,
    required String body,
    bool confirmed = false,
  }) async {
    final index = _posts.indexWhere((post) => post.id == postId);
    if (index != -1) {
      final old = _posts[index];
      _posts[index] = Post(
        id: old.id,
        authorId: old.authorId,
        authorName: old.authorName,
        authorAvatarAsset: old.authorAvatarAsset,
        createdAt: old.createdAt,
        type: old.type,
        responseMode: old.responseMode,
        body: body.trim(),
        empathyCount: old.empathyCount,
        commentCount: old.commentCount,
        isMine: old.isMine,
        isSaved: old.isSaved,
        commentsOpen: old.commentsOpen,
      );
    }
    return EditResult(editedAt: DateTime.now());
  }

  @override
  Future<void> deletePost(String postId) async {
    _posts.removeWhere((post) => post.id == postId);
  }

  /// サンプルでは、保存しない(画面は、画面内のプレビューだけで変える)。
  @override
  Future<void> updateReactionMode({
    required String postId,
    required ResponseMode mode,
    bool? commentsOpen,
  }) async {}

  @override
  Future<void> hidePost(String postId) async {
    _posts.removeWhere((post) => post.id == postId);
  }

  @override
  Future<void> blockUser(String userId) async {
    _posts.removeWhere((post) => post.authorId == userId);
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
