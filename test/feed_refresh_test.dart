import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kosodate_hitoiki/core/constants/app_theme.dart';
import 'package:kosodate_hitoiki/domain/models/post.dart';
import 'package:kosodate_hitoiki/presentation/pages/home/home_page.dart';
import 'package:kosodate_hitoiki/presentation/providers/post_providers.dart';

import 'helpers/scripted_post_repository.dart';

Post _post(String id, String body, DateTime createdAt) => Post(
  id: id,
  authorId: 'other',
  authorName: 'はな',
  authorAvatarAsset: 'assets/avatars/avatar-default-sprout.png',
  createdAt: createdAt,
  type: PostType.grumble,
  responseMode: ResponseMode.listening,
  body: body,
  empathyCount: 0,
  commentCount: 0,
);

void main() {
  testWidgets('ホームを下に引っ張ると、一覧を読み直して、新しい投稿が出る', (tester) async {
    final repository = ScriptedPostRepository([])
      ..pagedPosts = [_post('old', 'まえの投稿', DateTime.utc(2026, 10, 29, 9))];
    await tester.pumpWidget(
      ProviderScope(
        overrides: [postRepositoryProvider.overrideWithValue(repository)],
        child: MaterialApp(
          theme: AppTheme.light,
          home: Scaffold(body: HomePage(onCompose: () {})),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('まえの投稿'), findsOneWidget);
    expect(find.text('あたらしい投稿'), findsNothing);
    expect(repository.feedBeforeCalls, hasLength(1));

    // 別の人が投稿した(画面を開いたまま)。
    repository.pagedPosts = [
      _post('new', 'あたらしい投稿', DateTime.utc(2026, 10, 29, 10)),
      ...repository.pagedPosts,
    ];
    await tester.fling(find.byType(ListView), const Offset(0, 400), 1000);
    await tester.pumpAndSettle();

    expect(repository.feedBeforeCalls, hasLength(2));
    expect(find.text('あたらしい投稿'), findsOneWidget);
  });

  testWidgets('投稿がなくて画面に収まるときも、引っ張って読み直せる', (tester) async {
    final repository = ScriptedPostRepository([]);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [postRepositoryProvider.overrideWithValue(repository)],
        child: MaterialApp(
          theme: AppTheme.light,
          home: Scaffold(body: HomePage(onCompose: () {})),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(repository.feedBeforeCalls, hasLength(1));

    await tester.fling(find.byType(ListView), const Offset(0, 400), 1000);
    await tester.pumpAndSettle();
    expect(repository.feedBeforeCalls, hasLength(2));
  });
}
