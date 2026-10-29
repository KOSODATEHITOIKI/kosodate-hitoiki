import 'dart:async';

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
    when(() => auth.sendPasswordReset(any())).thenAnswer((_) async {});
  });

  Future<void> pumpReset(WidgetTester tester, {bool captcha = false}) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(auth),
          authStateChangesProvider.overrideWith(
            (ref) => const Stream<AuthState>.empty(),
          ),
          captchaEnabledProvider.overrideWithValue(captcha),
          turnstileViewBuilderProvider.overrideWithValue(fake.builder),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          home: const AuthPage(initialMode: AuthMode.reset),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('auth-email')),
      'a@example.com',
    );
    FocusManager.instance.primaryFocus?.unfocus();
    if (captcha) fake.onToken!('tok-1');
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('auth-submit')));
    await tester.pumpAndSettle();
  }

  Future<void> enterCode(WidgetTester tester, String code) async {
    await tester.enterText(find.byKey(const ValueKey('auth-reset-code')), code);
    await tester.tap(find.byKey(const ValueKey('auth-reset-verify')));
    await tester.pumpAndSettle();
  }

  testWidgets('メールを送ると、確認コードの入力欄を出す', (tester) async {
    await pumpReset(tester);
    expect(find.byKey(const ValueKey('auth-reset-code')), findsOneWidget);
    expect(find.byKey(const ValueKey('auth-reset-verify')), findsOneWidget);
    expect(find.byKey(const ValueKey('auth-reset-resend')), findsOneWidget);
  });

  testWidgets('6〜8桁の数字を入れると、メールのアドレスと一緒に、確認する', (tester) async {
    when(
      () => auth.verifyRecoveryCode(
        email: any(named: 'email'),
        code: any(named: 'code'),
      ),
    ).thenAnswer((_) async => AuthResponse());
    await pumpReset(tester);
    await enterCode(tester, '12345678');

    verify(
      () => auth.verifyRecoveryCode(email: 'a@example.com', code: '12345678'),
    ).called(1);
    expect(find.textContaining('確認コード(6〜8桁'), findsNothing);
    // 使ったコードは、入力欄に残さない。
    expect(
      tester
          .widget<TextField>(find.byKey(const ValueKey('auth-reset-code')))
          .controller!
          .text,
      isEmpty,
    );
  });

  testWidgets('6桁のコードも、受け付ける', (tester) async {
    when(
      () => auth.verifyRecoveryCode(
        email: any(named: 'email'),
        code: any(named: 'code'),
      ),
    ).thenAnswer((_) async => AuthResponse());
    await pumpReset(tester);
    await enterCode(tester, '123456');
    verify(
      () => auth.verifyRecoveryCode(email: 'a@example.com', code: '123456'),
    ).called(1);
  });

  testWidgets('桁数が足りない・空のときは、通信せずに、案内する', (tester) async {
    await pumpReset(tester);
    await enterCode(tester, '12345');
    expect(find.textContaining('6〜8桁の数字'), findsOneWidget);
    await enterCode(tester, '');
    expect(find.textContaining('6〜8桁の数字'), findsOneWidget);
    verifyNever(
      () => auth.verifyRecoveryCode(
        email: any(named: 'email'),
        code: any(named: 'code'),
      ),
    );
  });

  testWidgets('数字以外は、入力できない(貼り付けでも、数字だけが残る)', (tester) async {
    await pumpReset(tester);
    await tester.enterText(
      find.byKey(const ValueKey('auth-reset-code')),
      'ab12-34 56',
    );
    expect(
      tester
          .widget<TextField>(find.byKey(const ValueKey('auth-reset-code')))
          .controller!
          .text,
      '123456',
    );
  });

  for (final code in ['otp_expired', 'otp_invalid']) {
    testWidgets('コードが違う・期限切れ($code)のときは、再送を案内する', (tester) async {
      when(
        () => auth.verifyRecoveryCode(
          email: any(named: 'email'),
          code: any(named: 'code'),
        ),
      ).thenThrow(AuthApiException('bad', code: code, statusCode: '403'));
      await pumpReset(tester);
      await enterCode(tester, '12345678');
      expect(find.textContaining('もう一度、メールを送ってください'), findsWidgets);
      expect(find.textContaining('確認コードが違うか、期限が切れています'), findsOneWidget);
      // 入力欄は、そのまま使える(再送もできる)。
      expect(find.byKey(const ValueKey('auth-reset-code')), findsOneWidget);
    });
  }

  testWidgets('「もう一度、メールを送る」で、同じアドレスに再送する(待ち時間つき)', (tester) async {
    await pumpReset(tester);
    // 送った直後は、連続で送れない。
    expect(
      tester
          .widget<OutlinedButton>(
            find.byKey(const ValueKey('auth-reset-resend')),
          )
          .enabled,
      isFalse,
    );
    await tester.pump(const Duration(seconds: 61));
    expect(
      tester
          .widget<OutlinedButton>(
            find.byKey(const ValueKey('auth-reset-resend')),
          )
          .enabled,
      isTrue,
    );
    await tester.tap(find.byKey(const ValueKey('auth-reset-resend')));
    await tester.pumpAndSettle();
    verify(() => auth.sendPasswordReset('a@example.com')).called(2);
    expect(find.textContaining('もう一度送りました'), findsOneWidget);
  });

  testWidgets('ボット対策が有効のとき、再送にも確認が要る', (tester) async {
    await pumpReset(tester, captcha: true);
    await tester.pump(const Duration(seconds: 61));
    // 送信で、使ったトークンは消えて、確認がやり直しになっている。
    expect(
      tester
          .widget<OutlinedButton>(
            find.byKey(const ValueKey('auth-reset-resend')),
          )
          .enabled,
      isFalse,
    );
    fake.onToken!('tok-2');
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<OutlinedButton>(
            find.byKey(const ValueKey('auth-reset-resend')),
          )
          .enabled,
      isTrue,
    );
  });
}
