import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kosodate_hitoiki/core/config/flavor.dart';
import 'package:kosodate_hitoiki/core/constants/app_theme.dart';
import 'package:kosodate_hitoiki/data/repositories/auth_repository.dart';
import 'package:kosodate_hitoiki/presentation/pages/auth/auth_page.dart';
import 'package:kosodate_hitoiki/presentation/providers/auth_provider.dart';
import 'package:kosodate_hitoiki/presentation/providers/captcha_provider.dart';
import 'package:kosodate_hitoiki/presentation/widgets/turnstile/turnstile_field.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'turnstile_field_test.dart' show FakeTurnstile;

class _MockAuth extends Mock implements AuthRepository {}

void main() {
  late _MockAuth auth;
  late FakeTurnstile fake;

  setUp(() {
    AppConfig.setFlavor(Flavor.dev);
    auth = _MockAuth();
    fake = FakeTurnstile();
    when(() => auth.signOut()).thenAnswer((_) async {});
  });

  Future<ProviderContainer> pumpAuth(
    WidgetTester tester, {
    required bool captcha,
    AuthMode mode = AuthMode.login,
  }) async {
    final container = ProviderContainer(
      overrides: [
        authRepositoryProvider.overrideWithValue(auth),
        authStateChangesProvider.overrideWith(
          (ref) => const Stream<AuthState>.empty(),
        ),
        captchaEnabledProvider.overrideWithValue(captcha),
        turnstileViewBuilderProvider.overrideWithValue(fake.builder),
      ],
    );
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: AppTheme.light,
          home: AuthPage(initialMode: mode),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return container;
  }

  Future<void> fillLogin(WidgetTester tester) async {
    await tester.enterText(
      find.byKey(const ValueKey('auth-email')),
      'a@example.com',
    );
    await tester.enterText(
      find.byKey(const ValueKey('auth-password')),
      'password123',
    );
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pumpAndSettle();
  }

  bool submitEnabled(WidgetTester tester) => tester
      .widget<FilledButton>(find.byKey(const ValueKey('auth-submit')))
      .enabled;

  testWidgets('使わない設定(既定)では、確認の部品を出さず、これまでどおり押せる', (tester) async {
    await pumpAuth(tester, captcha: false);
    expect(find.byKey(const ValueKey('turnstile-field')), findsNothing);
    expect(fake.built, 0);
    expect(submitEnabled(tester), isTrue);
  });

  testWidgets('使う設定では、確認が済むまで、ログインを押せない', (tester) async {
    final container = await pumpAuth(tester, captcha: true);
    expect(find.byKey(const ValueKey('turnstile-field')), findsOneWidget);
    expect(submitEnabled(tester), isFalse);

    fake.onToken!('tok-1');
    await tester.pumpAndSettle();
    expect(container.read(captchaTokenProvider), 'tok-1');
    expect(submitEnabled(tester), isTrue);

    // 期限が切れたら、また押せなくなる。
    fake.onExpired!();
    await tester.pumpAndSettle();
    expect(submitEnabled(tester), isFalse);
  });

  testWidgets('登録・パスワード再設定の画面にも、確認の部品を出す', (tester) async {
    await pumpAuth(tester, captcha: true, mode: AuthMode.register);
    expect(find.byKey(const ValueKey('turnstile-field')), findsOneWidget);
  });

  testWidgets('ログインを試したら、使ったトークンを消し、新しい確認をやり直す', (tester) async {
    when(
      () => auth.signInWithEmail(
        email: any(named: 'email'),
        password: any(named: 'password'),
      ),
    ).thenAnswer((_) async {
      // 本物のリポジトリは、通信の直前に、トークンを取り出して消す。
      throw const AuthException('bad', code: 'invalid_credentials');
    });
    final container = await pumpAuth(tester, captcha: true);
    await fillLogin(tester);
    fake.onToken!('tok-1');
    await tester.pumpAndSettle();
    expect(fake.built, 1);

    await tester.ensureVisible(find.byKey(const ValueKey('auth-submit')));
    await tester.tap(find.byKey(const ValueKey('auth-submit')));
    await tester.pumpAndSettle();

    verify(
      () =>
          auth.signInWithEmail(email: 'a@example.com', password: 'password123'),
    ).called(1);
    // 失敗しても、同じトークンは使わない。新しい確認が出て、それが済むまで押せない。
    expect(container.read(captchaTokenProvider), isNull);
    expect(fake.built, 2);
    expect(submitEnabled(tester), isFalse);
    expect(find.byKey(const ValueKey('auth-error')), findsOneWidget);
  });

  testWidgets('確認の部品を読み込めないときは、トークンなしで進めず、再試行を案内する', (tester) async {
    await pumpAuth(tester, captcha: true);
    fake.onError!();
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('turnstile-failed')), findsOneWidget);
    expect(submitEnabled(tester), isFalse);

    // 再試行して、確認が済むと、押せる。
    await tester.ensureVisible(find.byKey(const ValueKey('turnstile-retry')));
    await tester.tap(find.byKey(const ValueKey('turnstile-retry')));
    await tester.pumpAndSettle();
    fake.onToken!('tok-2');
    await tester.pumpAndSettle();
    expect(submitEnabled(tester), isTrue);
  });
}
