import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kosodate_hitoiki/presentation/providers/post_providers.dart';
import 'package:kosodate_hitoiki/presentation/providers/reaction_providers.dart';

import 'helpers/scripted_post_repository.dart';

Future<void> settle() => Future<void>.delayed(Duration.zero);

void main() {
  ProviderContainer containerFor(ScriptedPostRepository repository) {
    final container = ProviderContainer(
      overrides: [postRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);
    return container;
  }

  test('取得中に取り消した共感は、遅れて届いた取得結果で、元に戻らない', () async {
    final repository = ScriptedPostRepository([])
      ..myReactions['p-1'] = 1
      ..reactionFetchGate = Completer<void>();
    final container = containerFor(repository);
    final notifier = container.read(myReactionsProvider.notifier);

    notifier.request('p-1');
    await settle();
    expect(repository.reactionFetches, [
      ['p-1'],
    ]);

    // 取得が終わる前に、取り消す。
    expect(await notifier.clear('p-1'), isNull);
    expect(container.read(myReactionsProvider), isEmpty);

    // 取消前の結果(共感あり)が、あとから届く。
    repository.reactionFetchGate!.complete();
    await settle();
    expect(container.read(myReactionsProvider), isEmpty);
  });

  test('取得中に選び直した共感は、操作した内容を優先する', () async {
    final repository = ScriptedPostRepository([])
      ..myReactions['p-1'] = 1
      ..reactionFetchGate = Completer<void>();
    final container = containerFor(repository);
    final notifier = container.read(myReactionsProvider.notifier);

    notifier.request('p-1');
    await settle();
    expect(await notifier.select('p-1', 2), isNull);

    repository.reactionFetchGate!.complete();
    await settle();
    expect(container.read(myReactionsProvider), {'p-1': 2});
  });

  test('取得中に操作しなかった投稿は、取得結果を反映する', () async {
    final repository = ScriptedPostRepository([])
      ..myReactions['p-1'] = 1
      ..myReactions['p-2'] = 3
      ..reactionFetchGate = Completer<void>();
    final container = containerFor(repository);
    final notifier = container.read(myReactionsProvider.notifier);

    notifier
      ..request('p-1')
      ..request('p-2');
    await settle();
    // p-1だけ取り消す。p-2は、操作しない。
    await notifier.clear('p-1');

    repository.reactionFetchGate!.complete();
    await settle();
    expect(container.read(myReactionsProvider), {'p-2': 3});
  });

  test('取得が終わってから取り消した共感は、これまでどおり、取り消される', () async {
    final repository = ScriptedPostRepository([])..myReactions['p-1'] = 1;
    final container = containerFor(repository);
    final notifier = container.read(myReactionsProvider.notifier);

    notifier.request('p-1');
    await settle();
    expect(container.read(myReactionsProvider), {'p-1': 1});

    await notifier.clear('p-1');
    expect(container.read(myReactionsProvider), isEmpty);
  });
}
