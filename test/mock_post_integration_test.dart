import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kosodate_hitoiki/core/constants/app_theme.dart';
import 'package:kosodate_hitoiki/presentation/pages/search/search_page.dart';
import 'package:kosodate_hitoiki/presentation/providers/auth_provider.dart';
import 'package:kosodate_hitoiki/presentation/providers/post_providers.dart';
import 'package:kosodate_hitoiki/presentation/widgets/post_card.dart';

void main() {
  testWidgets('本文検索・種類選択・クリアと保存一覧への同期', (tester) async {
    // 保存操作はログイン必須のため、ログイン済みとして扱う。
    final container = ProviderContainer(
      overrides: [isLoggedInProvider.overrideWithValue(true)],
    );
    addTearDown(container.dispose);
    expect((await container.read(savedPostsProvider.future)).length, 2);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: AppTheme.light,
          home: const Scaffold(body: SearchPage()),
        ),
      ),
    );
    await tester.enterText(find.byType(TextField), '寝かしつけ');
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pumpAndSettle();
    final results = await container.read(searchResultsProvider.future);
    expect(results.map((post) => post.id), ['p1']);
    await tester.scrollUntilVisible(
      find.byTooltip('保存する'),
      150,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byTooltip('保存する'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('保存する'));
    await tester.pumpAndSettle();
    expect(
      (await container.read(savedPostsProvider.future)).map((p) => p.id),
      contains('p1'),
    );
    expect(tester.widget<PostCard>(find.byType(PostCard)).post.isSaved, isTrue);
    await tester.scrollUntilVisible(
      find.widgetWithText(ChoiceChip, '相談'),
      -150,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.widgetWithText(ChoiceChip, '相談'));
    await tester.tap(find.widgetWithText(ChoiceChip, '相談'));
    await tester.pumpAndSettle();
    expect(await container.read(searchResultsProvider.future), isEmpty);
    await tester.ensureVisible(find.byTooltip('検索語を消す'));
    await tester.tap(find.byTooltip('検索語を消す'));
    await tester.pumpAndSettle();
    expect(
      (await container.read(searchResultsProvider.future)).map((p) => p.id),
      ['p2'],
    );
    expect(tester.takeException(), isNull);
  });
}
