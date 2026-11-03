import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kosodate_hitoiki/core/constants/app_icons.dart';
import 'package:kosodate_hitoiki/core/constants/app_theme.dart';
import 'package:kosodate_hitoiki/data/api/api_exception.dart';
import 'package:kosodate_hitoiki/domain/models/user_profile.dart';
import 'package:kosodate_hitoiki/presentation/pages/profile/profile_edit_page.dart';
import 'package:kosodate_hitoiki/presentation/providers/auth_provider.dart';
import 'package:kosodate_hitoiki/presentation/providers/profile_providers.dart';

import 'helpers/scripted_profile_repository.dart';

const _me = UserProfile(
  id: 'me',
  nickname: 'こもれび',
  avatarAsset: AppAvatars.defaultSprout,
  bio: 'もとの自己紹介',
);

/// 利用者IDを[user]で切り替えられる状態で、プロフィール編集を別の画面から開く。
Future<void> pumpEdit(
  WidgetTester tester,
  ScriptedProfileRepository repository, {
  StateProvider<String?>? user,
  List<bool>? closed,
  bool settle = true,
}) async {
  tester.view.physicalSize = const Size(390, 1200);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        if (user != null)
          currentUserIdProvider.overrideWith((ref) => ref.watch(user))
        else
          currentUserIdProvider.overrideWithValue('me'),
        profileRepositoryProvider.overrideWithValue(repository),
      ],
      child: MaterialApp(
        theme: AppTheme.light,
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: TextButton(
                onPressed: () async {
                  await Navigator.of(context).push<void>(
                    MaterialPageRoute(builder: (_) => const ProfileEditPage()),
                  );
                  closed?.add(true);
                },
                child: const Text('開く'),
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('開く'));
  if (settle) {
    await tester.pumpAndSettle();
  } else {
    await tester.pump();
  }
}

Finder _field(String key) => find.byKey(ValueKey(key));

bool _enabled(WidgetTester tester, String key) =>
    tester
        .widget<TextField>(
          find.descendant(of: _field(key), matching: find.byType(TextField)),
        )
        .enabled ??
    true;

Future<void> save(WidgetTester tester) async {
  FocusManager.instance.primaryFocus?.unfocus();
  await tester.pumpAndSettle();
  await tester.scrollUntilVisible(
    _field('profile-save'),
    200,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.pumpAndSettle();
  await tester.tap(_field('profile-save'));
  await tester.pumpAndSettle();
}

Future<void> typeInto(WidgetTester tester, String key, String text) async {
  await tester.scrollUntilVisible(
    _field(key),
    -200,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.enterText(_field(key), text);
  await tester.pumpAndSettle();
}

void main() {
  group('読み込み中・読み込み失敗', () {
    testWidgets('読み込みが終わるまでは、編集も保存もできず、終わると値が入る(入力は消えない)', (tester) async {
      final gate = Completer<void>();
      final repository = ScriptedProfileRepository(
        profile: _me,
        fetchGate: gate.future,
      );
      await pumpEdit(tester, repository, settle: false);
      await tester.pump(const Duration(milliseconds: 50));

      expect(find.byKey(const ValueKey('profile-loading')), findsOneWidget);
      expect(_enabled(tester, 'profile-nickname'), isFalse);
      expect(_enabled(tester, 'profile-bio'), isFalse);
      await tester.scrollUntilVisible(
        _field('profile-save'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      expect(
        tester.widget<FilledButton>(_field('profile-save')).onPressed,
        isNull,
      );

      gate.complete();
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('profile-loading')), findsNothing);
      expect(_enabled(tester, 'profile-nickname'), isTrue);
      expect(
        tester
            .widget<TextFormField>(_field('profile-nickname'))
            .controller!
            .text,
        'こもれび',
      );
      expect(
        tester.widget<TextFormField>(_field('profile-bio')).controller!.text,
        'もとの自己紹介',
      );
    });

    testWidgets('読み込めなかったときは、編集できず、再読み込みで編集できるようになる', (tester) async {
      final repository = ScriptedProfileRepository(
        profile: _me,
        fetchErrors: [Exception('network')],
      );
      await pumpEdit(tester, repository);
      expect(find.byKey(const ValueKey('profile-load-failed')), findsOneWidget);
      expect(_enabled(tester, 'profile-nickname'), isFalse);

      await tester.tap(_field('profile-retry'));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('profile-load-failed')), findsNothing);
      expect(_enabled(tester, 'profile-nickname'), isTrue);
      expect(
        tester
            .widget<TextFormField>(_field('profile-nickname'))
            .controller!
            .text,
        'こもれび',
      );
      expect(repository.fetchCount, 2);
    });
  });

  group('利用者が切り替わったとき', () {
    testWidgets('編集画面を閉じる(前の利用者の入力を、切り替え後のアカウントに送らない)', (tester) async {
      final user = StateProvider<String?>((ref) => 'user-a');
      final repository = ScriptedProfileRepository(profile: _me);
      final closed = <bool>[];
      await pumpEdit(tester, repository, user: user, closed: closed);
      await typeInto(tester, 'profile-bio', 'Aさんが書いた自己紹介');
      expect(find.byType(ProfileEditPage), findsOneWidget);

      final container = ProviderScope.containerOf(
        tester.element(find.byType(ProfileEditPage)),
      );
      container.read(user.notifier).state = 'user-b';
      await tester.pumpAndSettle();

      expect(find.byType(ProfileEditPage), findsNothing);
      expect(closed, [true]);
      expect(repository.updateCalls, isEmpty);
      expect(repository.nicknameCalls, isEmpty);
    });

    testWidgets('確認ダイアログが開いていても、まとめて閉じる', (tester) async {
      final user = StateProvider<String?>((ref) => 'user-a');
      final repository = ScriptedProfileRepository(
        profile: _me,
        updateScript: [
          const ApiException(
            code: 'MODERATION_CONFIRM_REQUIRED',
            message: '強い言葉が含まれています。',
            status: 409,
          ),
          null,
        ],
      );
      await pumpEdit(tester, repository, user: user);
      await typeInto(tester, 'profile-bio', 'ありえない');
      await save(tester);
      expect(find.text('強い言葉が含まれています。'), findsOneWidget);

      final container = ProviderScope.containerOf(
        tester.element(find.byType(ProfileEditPage)),
      );
      container.read(user.notifier).state = 'user-b';
      await tester.pumpAndSettle();

      expect(find.byType(ProfileEditPage), findsNothing);
      expect(find.text('強い言葉が含まれています。'), findsNothing);
      // 切り替え後のアカウントに、再送しない。
      expect(repository.updateCalls, hasLength(1));
    });
  });

  testWidgets('ニックネームだけ保存できて自己紹介が失敗しても、プロフィールを取り直す', (tester) async {
    final repository = ScriptedProfileRepository(
      profile: _me,
      nicknameScript: [null],
      updateScript: [Exception('network')],
    );
    await pumpEdit(tester, repository);
    expect(repository.fetchCount, 1);
    await typeInto(tester, 'profile-nickname', 'あたらしい名前');
    await typeInto(tester, 'profile-bio', 'あたらしい自己紹介');
    await save(tester);

    // 自己紹介は失敗したが、ニックネームは保存済み。画面を閉じなくても、取り直される。
    expect(find.byKey(const ValueKey('profile-error')), findsOneWidget);
    expect(repository.nicknameCalls, hasLength(1));
    expect(repository.fetchCount, 2);
  });

  group('保存の応答を待つ間に、画面が閉じられたとき', () {
    testWidgets('戻る操作で閉じても、例外にならず、保存できた変更は表示に反映する', (tester) async {
      final gate = Completer<void>();
      final repository = ScriptedProfileRepository(
        profile: _me,
        nicknameScript: [() => gate.future],
      );
      final closed = <bool>[];
      await pumpEdit(tester, repository, closed: closed);
      await typeInto(tester, 'profile-nickname', 'あたらしい名前');
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        _field('profile-save'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(_field('profile-save'));
      await tester.pump();
      expect(repository.nicknameCalls, hasLength(1));
      expect(repository.fetchCount, 1);

      // 応答を待つ間に、戻る操作で画面を閉じる。
      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(find.byType(ProfileEditPage), findsNothing);

      // 応答が来ても、破棄された画面の ref を使わず、例外にならない。
      gate.complete();
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      // 保存できたニックネームは、プロフィールの表示に反映するため、キャッシュが破棄されている
      // (次に読むときに取り直す。破棄されていなければ、古い値のまま)。
      final container = ProviderScope.containerOf(
        tester.element(find.byType(Scaffold).first),
      );
      await container.read(myProfileProvider.future);
      expect(repository.fetchCount, 2);
      expect(closed, [true]);
    });

    testWidgets('利用者が切り替わって閉じても、例外にならない(切り替え後のアカウントには送らない)', (tester) async {
      final user = StateProvider<String?>((ref) => 'user-a');
      final gate = Completer<void>();
      final repository = ScriptedProfileRepository(
        profile: _me,
        nicknameScript: [() => gate.future],
        updateScript: [null],
      );
      await pumpEdit(tester, repository, user: user);
      await typeInto(tester, 'profile-nickname', 'あたらしい名前');
      await typeInto(tester, 'profile-bio', 'あたらしい自己紹介');
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        _field('profile-save'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(_field('profile-save'));
      await tester.pump();

      final container = ProviderScope.containerOf(
        tester.element(find.byType(ProfileEditPage)),
      );
      container.read(user.notifier).state = 'user-b';
      await tester.pumpAndSettle();
      expect(find.byType(ProfileEditPage), findsNothing);

      gate.complete();
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      // 切り替え後のアカウントに、自己紹介の更新は送らない。
      expect(repository.updateCalls, isEmpty);
    });
  });
}
