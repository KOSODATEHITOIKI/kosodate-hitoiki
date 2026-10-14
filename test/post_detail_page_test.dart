import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kosodate_hitoiki/core/constants/app_theme.dart';
import 'package:kosodate_hitoiki/data/mock/mock_post_repository.dart';
import 'package:kosodate_hitoiki/presentation/pages/auth/auth_page.dart';
import 'package:kosodate_hitoiki/presentation/pages/post_detail/post_detail_page.dart';
import 'package:kosodate_hitoiki/presentation/providers/auth_provider.dart';
import 'package:kosodate_hitoiki/presentation/providers/post_providers.dart';
import 'package:kosodate_hitoiki/presentation/widgets/post_card.dart';

void main() {
  for (final width in [320.0, 768.0]) {
    for (final scale in [1.0, 2.0]) {
      testWidgets('幅$width・文字倍率$scaleで本文からログインし投稿に戻れる', (tester) async {
        tester.view.physicalSize = Size(width, 800);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final repository = MockPostRepository();
        final post = (await repository.fetchFeed()).first;
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              isLoggedInProvider.overrideWithValue(false),
              postRepositoryProvider.overrideWithValue(repository),
            ],
            child: MaterialApp(
              theme: AppTheme.light,
              builder: (context, child) => MediaQuery(
                data: MediaQuery.of(
                  context,
                ).copyWith(textScaler: TextScaler.linear(scale)),
                child: child!,
              ),
              home: Scaffold(
                body: SingleChildScrollView(child: PostCard(post: post)),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        await tester.ensureVisible(find.text('投稿の詳細を見る'));
        await tester.tap(find.text('投稿の詳細を見る'));
        await tester.pumpAndSettle();
        expect(find.byType(PostDetailPage), findsOneWidget);
        expect(find.text(post.body), findsOneWidget);
        expect(find.text('続きは、ログインしてから'), findsOneWidget);
        await tester.ensureVisible(find.text('ログイン'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('ログイン'));
        await tester.pumpAndSettle();
        expect(find.byType(AuthPage), findsOneWidget);
        await tester.pageBack();
        await tester.pumpAndSettle();
        expect(find.byType(PostDetailPage), findsOneWidget);
        await tester.ensureVisible(find.byTooltip('保存する'));
        await tester.pumpAndSettle();
        await tester.tap(find.byTooltip('保存する'));
        await tester.pumpAndSettle();
        expect(find.byTooltip('保存を解除'), findsOneWidget);
        expect(
          (await repository.fetchSavedPosts()).any(
            (item) => item.id == post.id,
          ),
          isTrue,
        );
        expect(tester.takeException(), isNull);
      });
    }
  }

  testWidgets('ログイン済みでもただ聞いてほしい投稿にはコメント入力を出さない', (tester) async {
    final post = (await MockPostRepository().fetchFeed()).first;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [isLoggedInProvider.overrideWithValue(true)],
        child: MaterialApp(
          theme: AppTheme.light,
          home: PostDetailPage(post: post),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('ただ聞いてほしい気持ちです'), findsOneWidget);
    expect(find.byType(TextField), findsNothing);
    expect(find.text('会員登録'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
