import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kosodate_hitoiki/core/constants/app_theme.dart';
import 'package:kosodate_hitoiki/data/mock/mock_post_repository.dart';
import 'package:kosodate_hitoiki/presentation/providers/auth_provider.dart';
import 'package:kosodate_hitoiki/presentation/providers/mock_reaction_providers.dart';
import 'package:kosodate_hitoiki/presentation/widgets/post_card.dart';
import 'package:kosodate_hitoiki/presentation/pages/auth/auth_page.dart';

void main() {
  testWidgets('共感を選択・詳細と同期・取り消し・ログアウトでリセット', (tester) async {
    final login = StateProvider<bool>((ref) => true);
    final container = ProviderContainer(
      overrides: [isLoggedInProvider.overrideWith((ref) => ref.watch(login))],
    );
    addTearDown(container.dispose);
    final post = (await MockPostRepository().fetchFeed()).firstWhere(
      (post) => post.id == 'p2',
    );
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: AppTheme.light,
          home: Scaffold(
            body: SingleChildScrollView(child: PostCard(post: post)),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('わかる'));
    await tester.pumpAndSettle();
    expect(find.text('わかる ✓'), findsOneWidget);
    expect(container.read(mockEmpathyProvider), {'p2'});
    await tester.tap(find.text('投稿の詳細を見る'));
    await tester.pumpAndSettle();
    expect(find.text('わかる ✓'), findsOneWidget);
    await tester.tap(find.text('わかる ✓'));
    await tester.pumpAndSettle();
    expect(container.read(mockEmpathyProvider), isEmpty);
    await tester.tap(find.text('わかる'));
    await tester.pumpAndSettle();
    container.read(login.notifier).state = false;
    await tester.pumpAndSettle();
    expect(container.read(mockEmpathyProvider), isEmpty);
    expect(find.text('わかる ✓'), findsNothing);
    expect(tester.takeException(), isNull);
  });
  testWidgets('ゲストは共感せずログインへ進む', (tester) async {
    final post = (await MockPostRepository().fetchFeed()).firstWhere(
      (post) => post.id == 'p2',
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [isLoggedInProvider.overrideWithValue(false)],
        child: MaterialApp(
          theme: AppTheme.light,
          home: Scaffold(body: PostCard(post: post)),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('わかる'));
    await tester.pumpAndSettle();
    expect(find.byType(AuthPage), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.text('わかる ✓'), findsNothing);
  });
}
