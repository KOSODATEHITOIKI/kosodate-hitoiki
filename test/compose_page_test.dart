import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kosodate_hitoiki/core/constants/app_theme.dart';
import 'package:kosodate_hitoiki/domain/models/topic.dart';
import 'package:kosodate_hitoiki/presentation/pages/auth/auth_page.dart';
import 'package:kosodate_hitoiki/presentation/pages/compose/compose_page.dart';
import 'package:kosodate_hitoiki/presentation/providers/auth_provider.dart';
import 'package:kosodate_hitoiki/presentation/providers/post_providers.dart';
import 'package:kosodate_hitoiki/presentation/widgets/main_navigation_shell.dart';

import 'helpers/scripted_post_repository.dart';

/// ログイン済みの利用者として、書く画面を開く設定。
final _loggedIn = isLoggedInProvider.overrideWithValue(true);

void main() {
  testWidgets('初回案内は320px文字2倍でも延期でき、本文を失わない', (tester) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [_loggedIn],
        child: MaterialApp(
          theme: AppTheme.light,
          home: const MediaQuery(
            data: MediaQueryData(textScaler: TextScaler.linear(2)),
            child: Scaffold(body: ComposePage()),
          ),
        ),
      ),
    );
    await tester.scrollUntilVisible(
      find.byType(TextField),
      180,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'いまの気持ち');
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('compose-submit')),
      180,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('compose-submit')));
    await tester.pumpAndSettle();
    expect(find.text('はじめて投稿する前に'), findsOneWidget);
    await tester.tap(find.text('あとにする'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.byType(TextField),
      -180,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller!.text,
      'いまの気持ち',
    );
    expect(tester.takeException(), isNull);
  });
  testWidgets('反応の希望は縦並びで選択できる', (tester) async {
    tester.view.physicalSize = const Size(768, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: AppTheme.light,
          home: const Scaffold(body: ComposePage()),
        ),
      ),
    );
    await tester.scrollUntilVisible(
      find.text('話を聞きたい'),
      150,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('話を聞きたい'));
    await tester.pumpAndSettle();
    expect(
      tester.getTopLeft(find.text('話を聞きたい')).dy,
      greaterThan(tester.getTopLeft(find.text('ただ聞いてほしい')).dy),
    );
    await tester.tap(find.text('話を聞きたい'));
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<Semantics>(find.byKey(const ValueKey('response-advice')))
          .properties
          .selected,
      isTrue,
    );
    expect(tester.takeException(), isNull);
  });
  testWidgets('空白だけでは投稿不可、初回案内と確認後も本文を保持する', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [_loggedIn],
        child: MaterialApp(
          theme: AppTheme.light,
          home: const Scaffold(body: ComposePage()),
        ),
      ),
    );
    await tester.enterText(find.byType(TextField), '   ');
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('compose-submit')),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(
      tester
          .widget<FilledButton>(find.byKey(const ValueKey('compose-submit')))
          .onPressed,
      isNull,
    );
    await tester.scrollUntilVisible(
      find.byType(TextField),
      -200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.enterText(find.byType(TextField), '今日は少し疲れた。');
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('compose-submit')),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const ValueKey('compose-submit')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('compose-submit')));
    await tester.pumpAndSettle();
    expect(find.text('はじめて投稿する前に'), findsOneWidget);
    await tester.tap(find.text('確認して書く'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('compose-submit')));
    await tester.pumpAndSettle();
    expect(find.text('投稿の確認'), findsOneWidget);
    expect(find.text('今日は少し疲れた。'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('書き直す'),
      160,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('書き直す'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.byType(TextField),
      -200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller!.text,
      '今日は少し疲れた。',
    );
    expect(tester.takeException(), isNull);
  });
  testWidgets('案内ダイアログと確認画面から戻っても、本文の入力欄にフォーカスは戻らない', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [_loggedIn],
        child: MaterialApp(
          theme: AppTheme.light,
          home: const Scaffold(body: ComposePage()),
        ),
      ),
    );
    await tester.enterText(find.byType(TextField), '今日は少し疲れた。');
    await tester.pumpAndSettle();
    expect(tester.widget<TextField>(find.byType(TextField)).focusNode, isNull);
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('compose-submit')),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('compose-submit')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('確認して書く'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.byType(TextField),
      -200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(
      find.descendant(
        of: find.byType(TextField),
        matching: find.byType(EditableText),
      ),
      findsOneWidget,
    );
    bool fieldFocused() => tester
        .state<EditableTextState>(find.byType(EditableText))
        .widget
        .focusNode
        .hasFocus;
    expect(fieldFocused(), isFalse);
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('compose-submit')),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.byKey(const ValueKey('compose-submit')));
    await tester.pumpAndSettle();
    expect(find.text('投稿の確認'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('書き直す'),
      160,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('書き直す'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.byType(TextField),
      -200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(fieldFocused(), isFalse);
  });

  Future<void> typeAndPressPost(WidgetTester tester, String text) async {
    await tester.enterText(find.byType(TextField), text);
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('compose-submit')),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('compose-submit')));
    await tester.pumpAndSettle();
  }

  testWidgets('未ログインで「投稿する」を押すと、登録・ログインを案内し、入力は残る', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [isLoggedInProvider.overrideWithValue(false)],
        child: MaterialApp(
          theme: AppTheme.light,
          home: const Scaffold(body: ComposePage()),
        ),
      ),
    );
    await typeAndPressPost(tester, '今日は少し疲れた。');
    expect(find.byType(AuthPage), findsOneWidget);
    expect(find.text('はじめて投稿する前に'), findsNothing);

    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.byType(TextField),
      -200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller!.text,
      '今日は少し疲れた。',
    );
  });

  testWidgets('投稿できたら、下書きを空にして、ホームのタブへ戻る', (tester) async {
    final repository = ScriptedPostRepository([created()]);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          _loggedIn,
          postRepositoryProvider.overrideWithValue(repository),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          home: const Scaffold(body: ComposePage()),
        ),
      ),
    );
    final container = ProviderScope.containerOf(
      tester.element(find.byType(ComposePage)),
    );
    container.read(bottomNavIndexProvider.notifier).state = 2;

    await typeAndPressPost(tester, '今日は少し疲れた。');
    await tester.tap(find.text('確認して書く'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('compose-submit')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('compose-send')));
    await tester.pumpAndSettle();
    expect(repository.calls.single.body, '今日は少し疲れた。');

    await tester.tap(find.byKey(const ValueKey('compose-done')));
    await tester.pumpAndSettle();
    expect(container.read(bottomNavIndexProvider), 0);
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller!.text,
      isEmpty,
    );
  });

  testWidgets('ゲストがログインしても下書きは残り、ログアウト・別の利用者への切り替えでは消える', (tester) async {
    final user = StateProvider<String?>((ref) => null);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          currentUserIdProvider.overrideWith((ref) => ref.watch(user)),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          home: const Scaffold(body: ComposePage()),
        ),
      ),
    );
    final container = ProviderScope.containerOf(
      tester.element(find.byType(ComposePage)),
    );
    String draft() =>
        tester.widget<TextField>(find.byType(TextField)).controller!.text;

    await tester.enterText(find.byType(TextField), 'ゲストの下書き');
    await tester.pumpAndSettle();

    // ゲスト → ログイン: 残る。
    container.read(user.notifier).state = 'user-a';
    await tester.pumpAndSettle();
    expect(draft(), 'ゲストの下書き');

    // 別の利用者に切り替え: 消える。
    container.read(user.notifier).state = 'user-b';
    await tester.pumpAndSettle();
    expect(draft(), isEmpty);

    // ログアウト: 消える。
    await tester.enterText(find.byType(TextField), 'Bの下書き');
    container.read(user.notifier).state = null;
    await tester.pumpAndSettle();
    expect(draft(), isEmpty);
  });

  testWidgets('話題は、投稿を作るときだけ選べて、選ぶとその話題を送る(あとから変えられない)', (tester) async {
    final repository = ScriptedPostRepository([created()]);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          _loggedIn,
          postRepositoryProvider.overrideWithValue(repository),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          home: const Scaffold(body: ComposePage()),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('compose-topic-2')),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.byKey(const ValueKey('compose-topic-2')));
    await tester.pumpAndSettle();

    await typeAndPressPost(tester, '今日は少し疲れた。');
    await tester.tap(find.text('確認して書く'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('compose-submit')));
    await tester.pumpAndSettle();
    // 確認画面にも、選んだ話題が出る。
    expect(find.text('食事・離乳食'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('compose-send')));
    await tester.pumpAndSettle();
    expect(repository.calls.single.topicId, 2);
  });

  testWidgets('話題を選ばなければ、話題なしで送る。読み込めなくても投稿できる', (tester) async {
    final repository = _TopicsFailRepository([created()]);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          _loggedIn,
          postRepositoryProvider.overrideWithValue(repository),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          home: const Scaffold(body: ComposePage()),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('compose-topics-failed')),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.byKey(const ValueKey('compose-topics-failed')), findsOneWidget);

    await typeAndPressPost(tester, '今日は少し疲れた。');
    await tester.tap(find.text('確認して書く'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('compose-submit')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('compose-send')));
    await tester.pumpAndSettle();
    expect(repository.calls.single.topicId, isNull);
  });

  testWidgets('小さい画面と拡大文字で種類・反応の希望を変更できる', (tester) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: AppTheme.light,
          home: const MediaQuery(
            data: MediaQueryData(textScaler: TextScaler.linear(1.5)),
            child: Scaffold(body: ComposePage()),
          ),
        ),
      ),
    );
    await tester.scrollUntilVisible(
      find.widgetWithText(ChoiceChip, '相談'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.widgetWithText(ChoiceChip, '相談'));
    await tester.pumpAndSettle();
    expect(
      tester.widget<ChoiceChip>(find.widgetWithText(ChoiceChip, '相談')).selected,
      isTrue,
    );
    await tester.scrollUntilVisible(
      find.text('話を聞きたい'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('話を聞きたい'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('話を聞きたい'), warnIfMissed: true);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}

/// 話題を読み込めない。
class _TopicsFailRepository extends ScriptedPostRepository {
  _TopicsFailRepository(super.script);

  @override
  Future<List<Topic>> fetchTopics() async => throw Exception('network');
}
