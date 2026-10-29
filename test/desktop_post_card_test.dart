import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kosodate_hitoiki/core/constants/app_theme.dart';
import 'package:kosodate_hitoiki/data/mock/mock_post_repository.dart';
import 'package:kosodate_hitoiki/presentation/providers/auth_provider.dart';
import 'package:kosodate_hitoiki/presentation/providers/reaction_providers.dart';
import 'package:kosodate_hitoiki/presentation/widgets/post_card.dart';

Future<ProviderContainer> pumpCard(WidgetTester tester, Size size) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final post = (await MockPostRepository().fetchFeed()).firstWhere(
    (post) => post.id == 'p2',
  );
  final container = ProviderContainer(
    overrides: [isLoggedInProvider.overrideWithValue(true)],
  );
  addTearDown(container.dispose);
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
  return container;
}

void main() {
  testWidgets('広い画面の一覧のカードには、「定型文を送る」を出す', (tester) async {
    await pumpCard(tester, const Size(1280, 900));
    expect(find.text('定型文を送る'), findsOneWidget);
  });

  testWidgets('スマホ幅の一覧のカードには、これまでどおり、「定型文を送る」を出さない', (tester) async {
    await pumpCard(tester, const Size(390, 900));
    expect(find.text('定型文を送る'), findsNothing);
  });

  testWidgets('広い画面でも、「わかる」で共感でき、もう一度で取り消せる', (tester) async {
    final container = await pumpCard(tester, const Size(1280, 900));
    await tester.tap(find.text('わかる'));
    await tester.pumpAndSettle();
    expect(find.text('わかる ✓'), findsOneWidget);
    expect(container.read(myReactionsProvider), {'p2': 1});
    await tester.tap(find.text('わかる ✓'));
    await tester.pumpAndSettle();
    expect(container.read(myReactionsProvider), isEmpty);
  });

  testWidgets('広い画面では、投稿の文字を少し大きくする', (tester) async {
    final body = (await MockPostRepository().fetchFeed())
        .firstWhere((post) => post.id == 'p2')
        .body;
    double bodySize() => tester.widget<Text>(find.text(body)).style!.fontSize!;

    await pumpCard(tester, const Size(1280, 900));
    final wide = bodySize();
    await pumpCard(tester, const Size(390, 900));
    expect(wide, greaterThan(bodySize()));
  });
}
