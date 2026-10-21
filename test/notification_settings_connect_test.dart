import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kosodate_hitoiki/core/constants/app_theme.dart';
import 'package:kosodate_hitoiki/data/repositories/supabase_notification_repository.dart';
import 'package:kosodate_hitoiki/domain/models/app_notification.dart';
import 'package:kosodate_hitoiki/presentation/pages/settings/notification_settings_page.dart';
import 'package:kosodate_hitoiki/presentation/providers/auth_provider.dart';
import 'package:kosodate_hitoiki/presentation/providers/notification_providers.dart';

import 'helpers/scripted_notification_repository.dart';

/// 通知設定を、別の画面から開き、利用者IDを[user]で切り替えられる状態にする。
Future<void> pumpSettings(
  WidgetTester tester,
  ScriptedNotificationRepository repository, {
  StateProvider<String?>? user,
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
          currentUserIdProvider.overrideWithValue('me'),
        isLoggedInProvider.overrideWithValue(true),
        notificationRepositoryProvider.overrideWithValue(repository),
      ],
      child: MaterialApp(
        theme: AppTheme.light,
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: TextButton(
                onPressed: () => Navigator.of(context).push<void>(
                  MaterialPageRoute(
                    builder: (_) => const NotificationSettingsPage(),
                  ),
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

Finder _switchOf(String title) => find.widgetWithText(SwitchListTile, title);

bool _value(WidgetTester tester, String title) =>
    tester.widget<SwitchListTile>(_switchOf(title)).value;

void main() {
  testWidgets('いまの設定を表示する(実データでは「サンプル」と出さない)', (tester) async {
    await pumpSettings(
      tester,
      ScriptedNotificationRepository(
        settings: const NotificationSettings(
          comments: true,
          replies: false,
          reactions: true,
        ),
      ),
    );
    expect(_value(tester, 'コメント'), isTrue);
    expect(_value(tester, '返信'), isFalse);
    expect(_value(tester, '共感のまとめ'), isTrue);
    expect(find.textContaining('サンプル'), findsNothing);
    expect(find.textContaining('受け取らない'), findsOneWidget);
  });

  testWidgets('切り替えると、すぐ変わり、その項目だけをサーバーへ送る', (tester) async {
    final repository = ScriptedNotificationRepository();
    await pumpSettings(tester, repository);
    await tester.tap(_switchOf('返信'));
    await tester.pumpAndSettle();

    expect(_value(tester, '返信'), isFalse);
    expect(repository.updateCalls, hasLength(1));
    final call = repository.updateCalls.single;
    expect(call.replies, isFalse);
    expect(call.comments, isNull);
    expect(call.reactions, isNull);
  });

  testWidgets('送れなかったときは、元に戻して、案内する', (tester) async {
    final repository = ScriptedNotificationRepository(
      settingsError: Exception('network'),
    );
    await pumpSettings(tester, repository);
    await tester.tap(_switchOf('コメント'));
    await tester.pumpAndSettle();

    expect(repository.updateCalls, hasLength(1));
    expect(_value(tester, 'コメント'), isTrue);
    expect(find.text('設定を変更できませんでした'), findsOneWidget);
  });

  testWidgets('読み込み中は、切り替えられない。読み込めたら、設定が入る', (tester) async {
    final repository = ScriptedNotificationRepository(
      settings: const NotificationSettings(replies: false),
      settingsFetchErrors: const [],
    );
    // 読み込みを待たせるため、取得を遅らせる偽のリポジトリを使う。
    final gate = Completer<void>();
    final slow = _SlowSettings(repository, gate.future);
    await pumpSettings(tester, slow);
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.byKey(const ValueKey('settings-loading')), findsOneWidget);
    expect(tester.widget<SwitchListTile>(_switchOf('コメント')).onChanged, isNull);
    gate.complete();
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('settings-loading')), findsNothing);
    expect(
      tester.widget<SwitchListTile>(_switchOf('コメント')).onChanged,
      isNotNull,
    );
    expect(_value(tester, '返信'), isFalse);
  });

  testWidgets('読み込めなかったときは、変更できず、再読み込みで変更できる', (tester) async {
    final repository = ScriptedNotificationRepository(
      settingsFetchErrors: [Exception('network')],
    );
    await pumpSettings(tester, repository);
    expect(find.byKey(const ValueKey('settings-load-failed')), findsOneWidget);
    expect(tester.widget<SwitchListTile>(_switchOf('コメント')).onChanged, isNull);

    await tester.tap(find.byKey(const ValueKey('settings-retry')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('settings-load-failed')), findsNothing);
    expect(
      tester.widget<SwitchListTile>(_switchOf('コメント')).onChanged,
      isNotNull,
    );
    expect(repository.settingsFetchCount, 2);
  });

  testWidgets('利用者が切り替わったら、画面を閉じる(別の人の設定を変えない)', (tester) async {
    final user = StateProvider<String?>((ref) => 'user-a');
    final repository = ScriptedNotificationRepository();
    await pumpSettings(tester, repository, user: user);
    expect(find.byType(NotificationSettingsPage), findsOneWidget);

    final container = ProviderScope.containerOf(
      tester.element(find.byType(NotificationSettingsPage)),
    );
    container.read(user.notifier).state = 'user-b';
    await tester.pumpAndSettle();

    expect(find.byType(NotificationSettingsPage), findsNothing);
    expect(repository.updateCalls, isEmpty);
  });

  testWidgets('応答を待つ間に画面を閉じても、例外にならない', (tester) async {
    final gate = Completer<void>();
    final repository = _SlowUpdate(
      ScriptedNotificationRepository(),
      gate.future,
    );
    await pumpSettings(tester, repository);
    await tester.tap(_switchOf('コメント'));
    await tester.pump();
    await tester.pageBack();
    await tester.pumpAndSettle();
    gate.complete();
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  group('設定の行と変更の本文', () {
    test('行を設定にする(列がなければ、受け取る)', () {
      final settings = SupabaseNotificationRepository.settingsFromRow({
        'comments_enabled': false,
        'replies_enabled': true,
        'reactions_enabled': false,
        'push_enabled': true,
      });
      expect(settings.comments, isFalse);
      expect(settings.replies, isTrue);
      expect(settings.reactions, isFalse);
      expect(settings.push, isTrue);
      expect(
        SupabaseNotificationRepository.settingsFromRow(const {}).comments,
        isTrue,
      );
    });

    test('変更の本文は、指定した項目だけを入れる', () {
      expect(SupabaseNotificationRepository.settingsBody(), isEmpty);
      expect(SupabaseNotificationRepository.settingsBody(comments: false), {
        'comments_enabled': false,
      });
      expect(
        SupabaseNotificationRepository.settingsBody(
          replies: true,
          reactions: false,
        ),
        {'replies_enabled': true, 'reactions_enabled': false},
      );
    });
  });
}

/// 設定の取得を、[gate]が終わるまで待たせる。
class _SlowSettings extends ScriptedNotificationRepository {
  _SlowSettings(ScriptedNotificationRepository base, this.gate)
    : super(settings: base.settings);
  final Future<void> gate;

  @override
  Future<NotificationSettings> fetchSettings() async {
    await gate;
    return super.fetchSettings();
  }
}

/// 設定の変更を、[gate]が終わるまで待たせる。
class _SlowUpdate extends ScriptedNotificationRepository {
  _SlowUpdate(ScriptedNotificationRepository base, this.gate)
    : super(settings: base.settings, settingsError: Exception('network'));
  final Future<void> gate;

  @override
  Future<void> updateSettings({
    bool? comments,
    bool? replies,
    bool? reactions,
  }) async {
    await gate;
    return super.updateSettings(
      comments: comments,
      replies: replies,
      reactions: reactions,
    );
  }
}
