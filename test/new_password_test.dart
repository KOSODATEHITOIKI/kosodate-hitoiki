import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kosodate_hitoiki/app.dart';
import 'package:kosodate_hitoiki/core/constants/app_theme.dart';
import 'package:kosodate_hitoiki/data/repositories/auth_repository.dart';
import 'package:kosodate_hitoiki/presentation/pages/auth/new_password_page.dart';
import 'package:kosodate_hitoiki/presentation/pages/welcome/welcome_page.dart';
import 'package:kosodate_hitoiki/presentation/providers/auth_provider.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class _MockAuth extends Mock implements AuthRepository {}

UserResponse _updated() => UserResponse.fromJson({
  'id': 'user-1',
  'aud': 'authenticated',
  'app_metadata': <String, dynamic>{},
  'user_metadata': <String, dynamic>{},
  'created_at': '2026-10-21T00:00:00Z',
});

Future<void> pumpPage(WidgetTester tester, AuthRepository auth) async {
  tester.view.physicalSize = const Size(390, 1200);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [authRepositoryProvider.overrideWithValue(auth)],
      child: MaterialApp(
        theme: AppTheme.light,
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: TextButton(
                onPressed: () => Navigator.of(context).push<void>(
                  MaterialPageRoute(builder: (_) => const NewPasswordPage()),
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

Future<void> fill(WidgetTester tester, String password, String confirm) async {
  await tester.enterText(find.byKey(const ValueKey('new-password')), password);
  await tester.enterText(
    find.byKey(const ValueKey('new-password-confirm')),
    confirm,
  );
  await tester.pumpAndSettle();
}

Future<void> submit(WidgetTester tester) async {
  await tester.ensureVisible(find.byKey(const ValueKey('new-password-submit')));
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(const ValueKey('new-password-submit')));
  await tester.pumpAndSettle();
}

void main() {
  late _MockAuth auth;

  setUp(() {
    auth = _MockAuth();
  });

  testWidgets('条件を満たさない・確認と違うときは、送らずに理由を出す', (tester) async {
    await pumpPage(tester, auth);
    await fill(tester, 'short', 'short');
    await submit(tester);
    expect(find.textContaining('が必要です'), findsOneWidget);
    verifyNever(() => auth.updatePassword(any()));

    await fill(tester, 'Abcdefghi1', 'Abcdefghi2');
    await submit(tester);
    expect(find.text('パスワードが一致しません。'), findsOneWidget);
    verifyNever(() => auth.updatePassword(any()));
  });

  testWidgets('変更できたら、案内を出して、最初の画面へ戻る', (tester) async {
    when(() => auth.updatePassword(any())).thenAnswer((_) async => _updated());
    await pumpPage(tester, auth);
    await fill(tester, 'Abcdefghi1', 'Abcdefghi1');
    await submit(tester);

    verify(() => auth.updatePassword('Abcdefghi1')).called(1);
    expect(find.byType(NewPasswordPage), findsNothing);
    expect(find.text('パスワードを変更しました'), findsOneWidget);
  });

  testWidgets('今のパスワードと同じなら、案内して、画面は閉じない', (tester) async {
    when(() => auth.updatePassword(any())).thenThrow(
      const AuthException('same', statusCode: '422', code: 'same_password'),
    );
    await pumpPage(tester, auth);
    await fill(tester, 'Abcdefghi1', 'Abcdefghi1');
    await submit(tester);

    expect(find.text('今のパスワードと同じです。別のパスワードにしてください。'), findsOneWidget);
    expect(find.byType(NewPasswordPage), findsOneWidget);
  });

  testWidgets('送信中は、二重に送れない', (tester) async {
    final gate = Completer<UserResponse>();
    when(() => auth.updatePassword(any())).thenAnswer((_) => gate.future);
    await pumpPage(tester, auth);
    await fill(tester, 'Abcdefghi1', 'Abcdefghi1');
    await tester.ensureVisible(
      find.byKey(const ValueKey('new-password-submit')),
    );
    await tester.tap(find.byKey(const ValueKey('new-password-submit')));
    await tester.pump();
    expect(find.text('通信しています…'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('new-password-submit')));
    await tester.pump();
    verify(() => auth.updatePassword(any())).called(1);

    gate.complete(_updated());
    await tester.pumpAndSettle();
  });

  testWidgets('再設定のリンクから戻ったとき(passwordRecovery)、新しいパスワードの画面を開く', (
    tester,
  ) async {
    final controller = StreamController<AuthState>();
    addTearDown(controller.close);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          isLoggedInProvider.overrideWithValue(false),
          authStateChangesProvider.overrideWith((ref) => controller.stream),
        ],
        child: const App(),
      ),
    );
    expect(find.byType(WelcomePage), findsOneWidget);
    expect(find.byType(NewPasswordPage), findsNothing);

    // ほかのイベントでは開かない。
    controller.add(const AuthState(AuthChangeEvent.signedOut, null));
    await tester.pumpAndSettle();
    expect(find.byType(NewPasswordPage), findsNothing);

    controller.add(const AuthState(AuthChangeEvent.passwordRecovery, null));
    await tester.pumpAndSettle();
    expect(find.byType(NewPasswordPage), findsOneWidget);

    // 続けて同じイベントが来ても、二重に開かない。
    controller.add(const AuthState(AuthChangeEvent.passwordRecovery, null));
    await tester.pumpAndSettle();
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.byType(NewPasswordPage), findsNothing);
    expect(find.byType(WelcomePage), findsOneWidget);
  });
}
