import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kosodate_hitoiki/core/constants/app_theme.dart';
import 'package:kosodate_hitoiki/domain/models/blocked_user.dart';
import 'package:kosodate_hitoiki/domain/models/post.dart';
import 'package:kosodate_hitoiki/domain/models/reaction_type.dart';
import 'package:kosodate_hitoiki/domain/models/topic.dart';
import 'package:kosodate_hitoiki/domain/repositories/post_repository.dart';
import 'package:kosodate_hitoiki/presentation/pages/home/home_page.dart';
import 'package:kosodate_hitoiki/presentation/providers/post_providers.dart';

/// 実データ相当(サンプルではない)の投稿を返す偽のリポジトリ。
class _RealLikeRepository implements PostRepository {
  _RealLikeRepository(this.posts);
  final List<Post> posts;

  @override
  bool get isSample => false;

  @override
  Future<List<Topic>> fetchTopics() async => const [];

  @override
  Future<List<Post>> fetchFeed({int? topicId}) async => posts;

  @override
  Future<List<Post>> search({
    required String query,
    PostType? type,
    int? topicId,
  }) async => posts;

  @override
  Future<Post?> fetchPost(String postId) async => null;

  @override
  Future<void> updateReactionMode({
    required String postId,
    required ResponseMode mode,
    bool? commentsOpen,
  }) async {}

  @override
  Future<List<ReactionType>> fetchReactionTypes() async => const [];

  @override
  Future<Map<String, int>> fetchMyReactions() async => const {};

  @override
  Future<void> setReaction({
    required String postId,
    required int reactionTypeId,
  }) async {}

  @override
  Future<void> removeReaction(String postId) async {}

  @override
  Future<int> fetchReactionCount(String postId) async => 0;

  @override
  Future<List<BlockedUser>> fetchBlockedUsers() async => const [];

  @override
  Future<void> unblockUser(String userId) async {}

  @override
  Future<List<Post>> fetchMyPosts() async => const [];

  @override
  Future<List<Post>> fetchSavedPosts() async => const [];

  @override
  Future<CreatedPost> createPost({
    required PostType type,
    required ResponseMode responseMode,
    required String body,
    required String idempotencyKey,
    int? topicId,
    bool confirmed = false,
  }) => throw UnimplementedError();

  @override
  Future<EditResult> editPost({
    required String postId,
    required String body,
    bool confirmed = false,
  }) => throw UnimplementedError();

  @override
  Future<void> deletePost(String postId) => throw UnimplementedError();

  @override
  Future<void> hidePost(String postId) => throw UnimplementedError();

  @override
  Future<void> blockUser(String userId) => throw UnimplementedError();

  @override
  Future<void> toggleSaved(String postId) async {}
}

Future<void> pumpHome(WidgetTester tester, List<Post> posts) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        postRepositoryProvider.overrideWithValue(_RealLikeRepository(posts)),
      ],
      child: MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(body: HomePage(onCompose: () {})),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('実データでは、サンプル投稿の注記を出さず、投稿を表示する', (tester) async {
    await pumpHome(tester, [
      Post(
        id: 'p-1',
        authorId: '',
        authorName: 'はな',
        authorAvatarAsset: 'assets/avatars/avatar-default-sprout.png',
        createdAt: DateTime(2026, 10, 21),
        type: PostType.consult,
        responseMode: ResponseMode.advice,
        body: '夜泣きが続いています。',
        empathyCount: 0,
        commentCount: 2,
      ),
    ]);
    await tester.scrollUntilVisible(
      find.text('夜泣きが続いています。'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('夜泣きが続いています。'), findsOneWidget);
    expect(find.textContaining('サンプル投稿です'), findsNothing);
  });

  testWidgets('実データで投稿が0件のときは、「準備中」ではなく「まだ投稿がありません」', (tester) async {
    await pumpHome(tester, const []);
    await tester.scrollUntilVisible(
      find.text('まだ投稿がありません'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('まだ投稿がありません'), findsOneWidget);
    expect(find.text('投稿一覧は準備中です'), findsNothing);
    expect(find.textContaining('サンプル投稿です'), findsNothing);
  });
}
