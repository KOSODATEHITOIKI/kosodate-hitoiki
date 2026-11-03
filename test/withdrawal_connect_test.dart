import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kosodate_hitoiki/core/constants/app_theme.dart';
import 'package:kosodate_hitoiki/data/api/api_exception.dart';
import 'package:kosodate_hitoiki/data/repositories/auth_repository.dart';
import 'package:kosodate_hitoiki/domain/repositories/account_repository.dart';
import 'package:kosodate_hitoiki/presentation/pages/auth/auth_page.dart';
import 'package:kosodate_hitoiki/presentation/pages/settings/withdrawal_page.dart';
import 'package:kosodate_hitoiki/presentation/providers/account_providers.dart';
import 'package:kosodate_hitoiki/presentation/providers/auth_provider.dart';
import 'package:mocktail/mocktail.dart';

class _MockAuth extends Mock implements AuthRepository {}

/// 退会の呼び出しを数え、決めた結果(成功・失敗・待ち)を返す偽のリポジトリ。
class _ScriptedAccount implements AccountRepository {
  _ScriptedAccount(this.script);

  /// 呼び出しごとに1つ使う。nullなら成功、`Future Function()`ならその結果を待つ、
  /// それ以外は投げる。
  final List<Object?> script;
  var calls = 0;

  @override
  bool get isSample => false;

  @override
  Future<void> deleteAccount() async {
    calls++;
    final next = script.removeAt(0);
    if (next == null) return;
    if (next is Future<void> Function()) return next();
    throw next;
  }
}

final _user = StateProvider<String?>((ref) => 'user-a');

late _MockAuth _auth;

Future<void> _pumpWithdrawal(
  WidgetTester tester,
  _ScriptedAccount account,
) async {
  tester.view.physicalSize = const Size(390, 1200);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        authRepositoryProvider.overrideWithValue(_auth),
        accountRepositoryProvider.overrideWithValue(account),
        currentUserIdProvider.overrideWith((ref) => ref.watch(_user)),
        isLoggedInProvider.overrideWith(
          (ref) => ref.watch(currentUserIdProvider) != null,
        ),
      ],
      child: MaterialApp(
        theme: AppTheme.light,
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: TextButton(
                onPressed: () => Navigator.of(context).push<void>(
                  MaterialPageRoute(builder: (_) => const WithdrawalPage()),
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

ProviderContainer _containerOf(WidgetTester tester) =>
    ProviderScope.containerOf(tester.element(find.byType(Scaffold).first));

Future<void> _tapKey(WidgetTester tester, String key) async {
  await tester.scrollUntilVisible(
    find.byKey(ValueKey(key)),
    200,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(ValueKey(key)));
  await tester.pumpAndSettle();
}

/// 「削除される内容を確認しました」にチェックして、「退会の確認へ」を押す。
Future<void> _startWithdrawal(WidgetTester tester) async {
  await tester.scrollUntilVisible(
    find.byType(CheckboxListTile),
    200,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.pumpAndSettle();
  await tester.tap(find.byType(CheckboxListTile));
  await tester.pumpAndSettle();
  await _tapKey(tester, 'withdraw-start');
}

void main() {
  setUp(() {
    _auth = _MockAuth();
    when(() => _auth.signOut()).thenAnswer((_) async {});
    when(() => _auth.signOutLocal()).thenAnswer((_) async {});
  });

  testWidgets('「やめる」と、退会しない', (tester) async {
    final account = _ScriptedAccount([null]);
    await _pumpWithdrawal(tester, account);
    await _startWithdrawal(tester);
    expect(find.text('本当に退会しますか？'), findsOneWidget);
    expect(find.textContaining('元に戻せません'), findsWidgets);
    await tester.tap(find.text('やめる'));
    await tester.pumpAndSettle();
    expect(account.calls, 0);
    expect(find.byType(WithdrawalPage), findsOneWidget);
  });

  testWidgets('退会できたら、完了の画面を出し、端末のログインを外す(完了の画面は閉じない)', (tester) async {
    final account = _ScriptedAccount([null]);
    // 端末のログインを外すと、利用者IDがなくなる。
    when(() => _auth.signOutLocal()).thenAnswer((_) async {
      _containerOf(tester).read(_user.notifier).state = null;
    });
    await _pumpWithdrawal(tester, account);
    await _startWithdrawal(tester);
    await tester.tap(find.byKey(const ValueKey('withdraw-confirm')));
    await tester.pumpAndSettle();

    expect(account.calls, 1);
    verify(() => _auth.signOutLocal()).called(1);
    // 利用者IDが変わっても、完了の画面は残る。
    expect(find.text('退会しました。'), findsOneWidget);
    expect(find.byKey(const ValueKey('withdraw-done')), findsOneWidget);
    expect(find.textContaining('30日間'), findsWidgets);

    await tester.tap(find.byKey(const ValueKey('withdraw-home')));
    await tester.pumpAndSettle();
    expect(find.byType(WithdrawalPage), findsNothing);
  });

  testWidgets('本人確認(reauth_required)が必要なときは、再ログインを案内し、ログアウトして認証画面へ進む', (
    tester,
  ) async {
    final account = _ScriptedAccount([
      const ApiException(
        code: 'FORBIDDEN',
        message: '',
        status: 403,
        details: {'reason': 'reauth_required'},
      ),
    ]);
    when(() => _auth.signOut()).thenAnswer((_) async {
      _containerOf(tester).read(_user.notifier).state = null;
    });
    await _pumpWithdrawal(tester, account);
    await _startWithdrawal(tester);
    await tester.tap(find.byKey(const ValueKey('withdraw-confirm')));
    await tester.pumpAndSettle();

    expect(find.text('もう一度ログインしてください'), findsOneWidget);
    // 退会は、まだされていない(完了の画面ではない)。
    expect(find.text('退会しました。'), findsNothing);
    await tester.tap(find.byKey(const ValueKey('withdraw-relogin')));
    await tester.pumpAndSettle();

    verify(() => _auth.signOut()).called(1);
    expect(find.byType(AuthPage), findsOneWidget);
    expect(find.byType(WithdrawalPage), findsNothing);
  });

  testWidgets('再ログインの案内で「やめる」と、ログアウトせず、退会の画面に残る', (tester) async {
    final account = _ScriptedAccount([
      const ApiException(
        code: 'FORBIDDEN',
        message: '',
        status: 403,
        details: {'reason': 'reauth_required'},
      ),
    ]);
    await _pumpWithdrawal(tester, account);
    await _startWithdrawal(tester);
    await tester.tap(find.byKey(const ValueKey('withdraw-confirm')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('やめる'));
    await tester.pumpAndSettle();
    verifyNever(() => _auth.signOut());
    expect(find.byType(WithdrawalPage), findsOneWidget);
  });

  testWidgets('運営者として登録されているときは、退会できない理由を出す', (tester) async {
    final account = _ScriptedAccount([
      const ApiException(
        code: 'CONFLICT',
        message: '',
        status: 409,
        details: {'reason': 'operator_registered'},
      ),
    ]);
    await _pumpWithdrawal(tester, account);
    await _startWithdrawal(tester);
    await tester.tap(find.byKey(const ValueKey('withdraw-confirm')));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('withdraw-error')),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.textContaining('運営者として登録されているため'), findsOneWidget);
    verifyNever(() => _auth.signOutLocal());
  });

  testWidgets('通信の失敗は案内し、もう一度退会できる(同じ操作の再実行)', (tester) async {
    final account = _ScriptedAccount([Exception('network'), null]);
    await _pumpWithdrawal(tester, account);
    await _startWithdrawal(tester);
    await tester.tap(find.byKey(const ValueKey('withdraw-confirm')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('withdraw-error')), findsOneWidget);
    expect(find.text('退会しました。'), findsNothing);

    await _tapKey(tester, 'withdraw-start');
    await tester.tap(find.byKey(const ValueKey('withdraw-confirm')));
    await tester.pumpAndSettle();
    expect(account.calls, 2);
    expect(find.text('退会しました。'), findsOneWidget);
  });

  testWidgets('削除の処理中は、戻れず、二重に実行できない', (tester) async {
    final gate = Completer<void>();
    final account = _ScriptedAccount([() => gate.future]);
    await _pumpWithdrawal(tester, account);
    await _startWithdrawal(tester);
    await tester.tap(find.byKey(const ValueKey('withdraw-confirm')));
    await tester.pump();

    expect(find.text('退会しています…'), findsOneWidget);
    expect(
      tester
          .widget<OutlinedButton>(find.byKey(const ValueKey('withdraw-start')))
          .onPressed,
      isNull,
    );
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.byType(WithdrawalPage), findsOneWidget);

    gate.complete();
    await tester.pumpAndSettle();
    expect(account.calls, 1);
    expect(find.text('退会しました。'), findsOneWidget);
  });

  testWidgets('利用者が切り替わったら、画面を(確認ダイアログごと)閉じて、退会しない', (tester) async {
    final account = _ScriptedAccount([null]);
    await _pumpWithdrawal(tester, account);
    await _startWithdrawal(tester);
    expect(find.text('本当に退会しますか？'), findsOneWidget);

    _containerOf(tester).read(_user.notifier).state = 'user-b';
    await tester.pumpAndSettle();

    expect(find.byType(WithdrawalPage), findsNothing);
    expect(find.text('本当に退会しますか？'), findsNothing);
    expect(account.calls, 0);
  });
}
