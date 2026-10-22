import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kosodate_hitoiki/core/constants/app_theme.dart';
import 'package:kosodate_hitoiki/data/repositories/supabase_post_repository.dart';
import 'package:kosodate_hitoiki/domain/models/post.dart';
import 'package:kosodate_hitoiki/domain/models/topic.dart';
import 'package:kosodate_hitoiki/presentation/pages/home/home_page.dart';
import 'package:kosodate_hitoiki/presentation/pages/search/search_page.dart';
import 'package:kosodate_hitoiki/presentation/providers/post_providers.dart';

import 'helpers/scripted_post_repository.dart';

Future<void> pump(
  WidgetTester tester,
  ScriptedPostRepository repository,
  Widget page,
) async {
  tester.view.physicalSize = const Size(390, 1400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [postRepositoryProvider.overrideWithValue(repository)],
      child: MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(body: page),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> chooseTopic(WidgetTester tester, int id) async {
  await tester.tap(find.byKey(const ValueKey('topic-filter')));
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(ValueKey('topic-$id')));
  await tester.pumpAndSettle();
}

void main() {
  group('APIとの変換', () {
    test('話題の行を、話題にする', () {
      final topic = SupabasePostRepository.topicFromRow({
        'id': 4,
        'label': '睡眠・夜泣き',
        'sort_order': 1,
      });
      expect(topic.id, 4);
      expect(topic.label, '睡眠・夜泣き');
    });

    test('検索・作成の本文に、話題は選んだときだけ入れる', () {
      expect(SupabasePostRepository.searchParams(query: ''), {'p_limit': 30});
      expect(SupabasePostRepository.searchParams(query: '夜泣き', topicId: 4), {
        'p_query': '夜泣き',
        'p_topic_id': 4,
        'p_limit': 30,
      });
      final withTopic = SupabasePostRepository.createBody(
        type: PostType.grumble,
        responseMode: ResponseMode.listening,
        body: ' 本文 ',
        topicId: 7,
      );
      expect(withTopic['topic_id'], 7);
      final without = SupabasePostRepository.createBody(
        type: PostType.grumble,
        responseMode: ResponseMode.listening,
        body: '本文',
      );
      expect(without.containsKey('topic_id'), isFalse);
    });

    test('投稿の行から、話題のIDを読む', () {
      Map<String, dynamic> row(Object? topic) => {
        'id': 'p-1',
        'post_type': 'guchi',
        'body': '本文',
        'created_at': '2026-10-22T00:00:00Z',
        'topic_id': topic,
      };
      expect(SupabasePostRepository.postFromRow(row(3)).topicId, 3);
      expect(SupabasePostRepository.postFromRow(row(null)).topicId, isNull);
    });
  });

  testWidgets('ホーム: 話題を選ぶと、その話題で取り直し、外すとすべてに戻る', (tester) async {
    final repository = ScriptedPostRepository([]);
    await pump(tester, repository, HomePage(onCompose: () {}));
    expect(repository.feedTopicCalls, [null]);
    expect(find.text('話題を選ぶ'), findsOneWidget);

    await chooseTopic(tester, 2);
    expect(repository.feedTopicCalls.last, 2);
    expect(find.text('食事・離乳食'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('topic-filter-clear')));
    await tester.pumpAndSettle();
    expect(repository.feedTopicCalls.last, isNull);
    expect(find.text('話題を選ぶ'), findsOneWidget);
  });

  testWidgets('ホーム: 話題の一覧から「すべて」に戻せる', (tester) async {
    final repository = ScriptedPostRepository([]);
    await pump(tester, repository, HomePage(onCompose: () {}));
    await chooseTopic(tester, 1);
    expect(repository.feedTopicCalls.last, 1);

    await tester.tap(find.byKey(const ValueKey('topic-filter')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('topic-clear')));
    await tester.pumpAndSettle();
    expect(repository.feedTopicCalls.last, isNull);
  });

  testWidgets('検索: 話題を選ぶと、話題つきで検索する', (tester) async {
    final repository = ScriptedPostRepository([]);
    await pump(tester, repository, const SearchPage());
    await chooseTopic(tester, 1);
    expect(repository.searchTopicCalls.last, 1);
  });

  testWidgets('話題を読み込めなかったら、再読み込みできる', (tester) async {
    final repository = _FlakyTopicsRepository();
    await pump(tester, repository, HomePage(onCompose: () {}));
    await tester.tap(find.byKey(const ValueKey('topic-filter')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('topics-failed')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('topics-retry')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('topic-1')), findsOneWidget);
  });
}

/// 話題の取得が、1回目だけ失敗する。
class _FlakyTopicsRepository extends ScriptedPostRepository {
  _FlakyTopicsRepository() : super([]);
  var _calls = 0;

  @override
  Future<List<Topic>> fetchTopics() async {
    if (_calls++ == 0) throw Exception('network');
    return super.fetchTopics();
  }
}
