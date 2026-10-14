import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kosodate_hitoiki/core/constants/app_theme.dart';
import 'package:kosodate_hitoiki/data/mock/mock_post_repository.dart';
import 'package:kosodate_hitoiki/presentation/providers/auth_provider.dart';
import 'package:kosodate_hitoiki/presentation/providers/mock_reaction_providers.dart';
import 'package:kosodate_hitoiki/presentation/widgets/post_card.dart';

void main() {
  for (final scale in [1.0, 2.0]) {
    testWidgets('定型文を詳細で選択・共感へ切替・取り消し（320px文字$scale）', (tester) async {
      tester.view.physicalSize = const Size(320, 700);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final container = ProviderContainer(
        overrides: [isLoggedInProvider.overrideWithValue(true)],
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
      expect(find.text('定型文を送る'), findsNothing);
      await tester.ensureVisible(find.text('投稿の詳細を見る'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('投稿の詳細を見る'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('定型文を送る'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('定型文を送る'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('おつかれさま'));
      await tester.pumpAndSettle();
      expect(container.read(mockReactionsProvider), {
        'p2': MockReaction.breakTime,
      });
      expect(find.text('おつかれさま ✓'), findsOneWidget);
      await tester.ensureVisible(find.text('わかる'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('わかる'));
      await tester.pumpAndSettle();
      expect(container.read(mockReactionsProvider), {
        'p2': MockReaction.empathy,
      });
      await tester.ensureVisible(find.text('定型文を送る'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('定型文を送る'));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('共感を取り消す'),
        100,
        scrollable: find.byType(Scrollable).last,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('共感を取り消す'));
      await tester.pumpAndSettle();
      expect(container.read(mockReactionsProvider), isEmpty);
      expect(tester.takeException(), isNull);
    });
  }
}
