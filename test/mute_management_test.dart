import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kosodate_hitoiki/core/constants/app_theme.dart';
import 'package:kosodate_hitoiki/data/api/api_exception.dart';
import 'package:kosodate_hitoiki/data/repositories/supabase_mute_repository.dart';
import 'package:kosodate_hitoiki/domain/repositories/mute_repository.dart';
import 'package:kosodate_hitoiki/presentation/pages/auth/auth_page.dart';
import 'package:kosodate_hitoiki/presentation/pages/settings/mute_management_page.dart';
import 'package:kosodate_hitoiki/presentation/providers/auth_provider.dart';
import 'package:kosodate_hitoiki/presentation/providers/mute_providers.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// 言葉の追加・削除を記録し、決めた結果(成功・失敗・待ち)を返す偽のリポジトリ。
class _ScriptedMute implements MuteRepository {
  _ScriptedMute({
    List<String> words = const [],
    this.addError,
    this.removeError,
    this.addGate,
    this.sample = false,
    List<Object>? fetchErrors,
  }) : words = List.of(words),
       fetchErrors = fetchErrors ?? [];

  final List<String> words;
  final Object? addError;
  final Object? removeError;
  final Future<void>? addGate;
  final bool sample;
  final List<Object> fetchErrors;
  final added = <String>[];
  final removed = <String>[];
  var fetchCount = 0;

  @override
  bool get isSample => sample;

  @override
  Future<List<String>> fetchWords() async {
    fetchCount++;
    if (fetchErrors.isNotEmpty) throw fetchErrors.removeAt(0);
    return List.of(words);
  }

  @override
  Future<void> addWord(String word) async {
    added.add(word);
    if (addGate != null) await addGate;
    if (addError != null) throw addError!;
    words.insert(0, word.trim());
  }

  @override
  Future<void> removeWord(String word) async {
    removed.add(word);
    if (removeError != null) throw removeError!;
    words.remove(word);
  }
}

Future<void> _pumpMute(
  WidgetTester tester,
  _ScriptedMute repository, {
  StateProvider<String?>? user,
  bool loggedIn = true,
}) async {
  tester.view.physicalSize = const Size(390, 1400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        if (user != null)
          currentUserIdProvider.overrideWith((ref) => ref.watch(user))
        else
          currentUserIdProvider.overrideWithValue(loggedIn ? 'me' : null),
        isLoggedInProvider.overrideWithValue(loggedIn),
        muteRepositoryProvider.overrideWithValue(repository),
      ],
      child: MaterialApp(
        theme: AppTheme.light,
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: TextButton(
                onPressed: () => Navigator.of(context).push<void>(
                  MaterialPageRoute(builder: (_) => const MuteManagementPage()),
                ),
                child: const Text('開く'),
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('開く'));
  await tester.pumpAndSettle();
}

Future<void> typeWord(WidgetTester tester, String word) async {
  await tester.enterText(find.byKey(const ValueKey('mute-word-field')), word);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('ミュートしている言葉を件数つきで出す。0件のときは、その旨を出す', (tester) async {
    await _pumpMute(tester, _ScriptedMute(words: ['ネタバレ', '広告']));
    expect(find.text('ネタバレ'), findsOneWidget);
    expect(find.text('広告'), findsOneWidget);
    expect(find.text('ミュートしている言葉(2/100)'), findsOneWidget);
    expect(find.textContaining('サンプル'), findsNothing);
  });

  testWidgets('ミュートしている言葉が0件のときは、その旨を出す', (tester) async {
    await _pumpMute(tester, _ScriptedMute());
    expect(find.byKey(const ValueKey('mute-empty')), findsOneWidget);
    expect(find.text('ミュートしている言葉(0/100)'), findsOneWidget);
  });

  testWidgets('外せなかったときは、案内し、一覧に残る', (tester) async {
    final repository = _ScriptedMute(
      words: ['ネタバレ'],
      removeError: Exception('network'),
    );
    await _pumpMute(tester, repository);
    await tester.tap(find.byKey(const ValueKey('mute-remove-ネタバレ')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('mute-error')), findsOneWidget);
    expect(find.text('ネタバレ'), findsOneWidget);
  });

  testWidgets('言葉を追加すると、前後の空白を除いて送り、入力を空にして、一覧に出る', (tester) async {
    final repository = _ScriptedMute();
    await _pumpMute(tester, repository);
    expect(
      tester
          .widget<FilledButton>(find.byKey(const ValueKey('mute-add')))
          .onPressed,
      isNull,
    );
    await typeWord(tester, '  ネタバレ  ');
    await tester.tap(find.byKey(const ValueKey('mute-add')));
    await tester.pumpAndSettle();

    expect(repository.added, ['ネタバレ']);
    expect(find.text('ネタバレ'), findsOneWidget);
    expect(
      tester
          .widget<TextField>(find.byKey(const ValueKey('mute-word-field')))
          .controller!
          .text,
      isEmpty,
    );
  });

  testWidgets('空白だけの言葉は、追加できない', (tester) async {
    final repository = _ScriptedMute();
    await _pumpMute(tester, repository);
    await typeWord(tester, '   ');
    expect(
      tester
          .widget<FilledButton>(find.byKey(const ValueKey('mute-add')))
          .onPressed,
      isNull,
    );
    expect(repository.added, isEmpty);
  });

  testWidgets('言葉を外すと、APIを呼び、一覧から消える', (tester) async {
    final repository = _ScriptedMute(words: ['ネタバレ']);
    await _pumpMute(tester, repository);
    await tester.tap(find.byKey(const ValueKey('mute-remove-ネタバレ')));
    await tester.pumpAndSettle();
    expect(repository.removed, ['ネタバレ']);
    expect(find.text('ネタバレ'), findsNothing);
    expect(find.byKey(const ValueKey('mute-empty')), findsOneWidget);
  });

  for (final item in <(String, ApiException, String)>[
    (
      '100件の上限',
      const ApiException(code: 'LIMIT_EXCEEDED', message: ''),
      '登録できる言葉は、100件までです。使わない言葉を外してください。',
    ),
    (
      '重複',
      const ApiException(code: 'DUPLICATE', message: ''),
      'その言葉は、すでに登録されています。',
    ),
  ]) {
    testWidgets('${item.$1}は案内し、入力は残る', (tester) async {
      final repository = _ScriptedMute(addError: item.$2);
      await _pumpMute(tester, repository);
      await typeWord(tester, 'ネタバレ');
      await tester.tap(find.byKey(const ValueKey('mute-add')));
      await tester.pumpAndSettle();
      expect(find.text(item.$3), findsOneWidget);
      expect(
        tester
            .widget<TextField>(find.byKey(const ValueKey('mute-word-field')))
            .controller!
            .text,
        'ネタバレ',
      );
    });
  }

  testWidgets('読み込めなかったときは、再読み込みできる', (tester) async {
    final repository = _ScriptedMute(
      words: ['広告'],
      fetchErrors: [Exception('network')],
    );
    await _pumpMute(tester, repository);
    expect(find.text('読み込めませんでした。'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('mute-retry')));
    await tester.pumpAndSettle();
    expect(find.text('広告'), findsOneWidget);
  });

  testWidgets('サンプルのときだけ、「サンプルです」と注記する', (tester) async {
    await _pumpMute(tester, _ScriptedMute(sample: true));
    expect(find.text('サンプルです。実際には、投稿に反映されません。'), findsOneWidget);
  });

  testWidgets('ゲストには、登録・ログインの案内だけを出す', (tester) async {
    await _pumpMute(tester, _ScriptedMute(), loggedIn: false);
    expect(find.byKey(const ValueKey('mute-word-field')), findsNothing);
    await tester.tap(find.text('ログイン'));
    await tester.pumpAndSettle();
    expect(find.byType(AuthPage), findsOneWidget);
  });

  testWidgets('利用者が切り替わったら、画面を閉じる', (tester) async {
    final user = StateProvider<String?>((ref) => 'user-a');
    final repository = _ScriptedMute(words: ['広告']);
    await _pumpMute(tester, repository, user: user);
    expect(find.byType(MuteManagementPage), findsOneWidget);
    final container = ProviderScope.containerOf(
      tester.element(find.byType(MuteManagementPage)),
    );
    container.read(user.notifier).state = 'user-b';
    await tester.pumpAndSettle();
    expect(find.byType(MuteManagementPage), findsNothing);
  });

  testWidgets('追加の応答を待つ間に画面を閉じても、例外にならず、保存できた言葉は取り直す', (tester) async {
    final gate = Completer<void>();
    final repository = _ScriptedMute(addGate: gate.future);
    await _pumpMute(tester, repository);
    await typeWord(tester, 'ネタバレ');
    await tester.tap(find.byKey(const ValueKey('mute-add')));
    await tester.pump();
    final container = ProviderScope.containerOf(
      tester.element(find.byType(MuteManagementPage)),
    );

    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.byType(MuteManagementPage), findsNothing);
    gate.complete();
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    // 画面が閉じても、追加できた言葉は、次に読むときに反映される(キャッシュを破棄している)。
    final words = await container.read(mutedWordsProvider.future);
    expect(words, ['ネタバレ']);
  });

  group('PostgRESTの失敗の変換', () {
    test('上限超過(54000)と重複(23505・409)を、画面で扱える失敗にする', () {
      expect(
        SupabaseMuteRepository.apiExceptionFor(
          const PostgrestException(message: 'LIMIT_EXCEEDED', code: '54000'),
        ).code,
        'LIMIT_EXCEEDED',
      );
      expect(
        SupabaseMuteRepository.apiExceptionFor(
          const PostgrestException(message: 'duplicate', code: '23505'),
        ).code,
        'DUPLICATE',
      );
      expect(
        SupabaseMuteRepository.apiExceptionFor(
          const PostgrestException(message: 'conflict', code: '409'),
        ).code,
        'DUPLICATE',
      );
      expect(
        SupabaseMuteRepository.apiExceptionFor(
          const PostgrestException(message: 'other', code: '500'),
        ).code,
        'UNKNOWN',
      );
    });
  });
}
