import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kosodate_hitoiki/core/config/flavor.dart';
import 'package:kosodate_hitoiki/core/config/turnstile_config.dart';
import 'package:kosodate_hitoiki/data/repositories/auth_repository.dart';
import 'package:kosodate_hitoiki/presentation/providers/captcha_provider.dart';
import 'package:kosodate_hitoiki/presentation/widgets/turnstile/turnstile_field.dart';
import 'package:kosodate_hitoiki/presentation/widgets/turnstile/turnstile_types.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// 確認の部品の代わり。呼び出された回数と、受け取った関数を控える。
class FakeTurnstile {
  /// 作り直された回数。画面が組み直されるだけでは、増やさない(キーが同じなら、同じ部品)。
  int get built => _keys.length;
  final _keys = <Key?>{};
  String? siteKey;
  ValueChanged<String>? onToken;
  VoidCallback? onExpired;
  VoidCallback? onError;

  TurnstileViewBuilder get builder =>
      ({
        Key? key,
        required String siteKey,
        required ValueChanged<String> onToken,
        required VoidCallback onExpired,
        required VoidCallback onError,
      }) {
        _keys.add(key);
        this.siteKey = siteKey;
        this.onToken = onToken;
        this.onExpired = onExpired;
        this.onError = onError;
        return const SizedBox.expand(key: ValueKey('fake-turnstile'));
      };
}

void main() {
  setUp(() => AppConfig.setFlavor(Flavor.dev));

  Future<(ProviderContainer, FakeTurnstile, GlobalKey<TurnstileFieldState>)>
  pumpField(WidgetTester tester) async {
    final fake = FakeTurnstile();
    final key = GlobalKey<TurnstileFieldState>();
    final container = ProviderContainer(
      overrides: [turnstileViewBuilderProvider.overrideWithValue(fake.builder)],
    );
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          home: Scaffold(body: TurnstileField(key: key)),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return (container, fake, key);
  }

  group('確認の部品の枠', () {
    testWidgets('部品を表示し、環境のSite Keyを渡す', (tester) async {
      final (_, fake, _) = await pumpField(tester);
      expect(find.byKey(const ValueKey('fake-turnstile')), findsOneWidget);
      expect(fake.siteKey, TurnstileConfig.devSiteKey);
    });

    testWidgets('確認が済むとトークンを置き、期限が切れたら消す', (tester) async {
      final (container, fake, _) = await pumpField(tester);
      expect(container.read(captchaTokenProvider), isNull);

      fake.onToken!('tok-1');
      expect(container.read(captchaTokenProvider), 'tok-1');

      fake.onExpired!();
      expect(container.read(captchaTokenProvider), isNull);
    });

    testWidgets('読み込めないときは、トークンを置かず、再試行を案内する', (tester) async {
      final (container, fake, _) = await pumpField(tester);
      fake.onToken!('tok-1');

      fake.onError!();
      await tester.pumpAndSettle();
      // 失敗したら、前のトークンも使えない。
      expect(container.read(captchaTokenProvider), isNull);
      expect(find.byKey(const ValueKey('turnstile-failed')), findsOneWidget);
      expect(find.textContaining('読み込めませんでした'), findsOneWidget);
      expect(find.byKey(const ValueKey('fake-turnstile')), findsNothing);
    });

    testWidgets('「もう一度読み込む」で、部品を作り直す', (tester) async {
      final (_, fake, _) = await pumpField(tester);
      expect(fake.built, 1);
      fake.onError!();
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('turnstile-retry')));
      await tester.pumpAndSettle();
      expect(fake.built, 2);
      expect(find.byKey(const ValueKey('fake-turnstile')), findsOneWidget);
      expect(find.byKey(const ValueKey('turnstile-failed')), findsNothing);
    });

    testWidgets('使い終わったら、トークンを消して、新しい確認をやり直す(使い回さない)', (tester) async {
      final (container, fake, key) = await pumpField(tester);
      fake.onToken!('tok-1');
      expect(container.read(captchaTokenProvider), 'tok-1');

      key.currentState!.reset();
      await tester.pumpAndSettle();
      expect(container.read(captchaTokenProvider), isNull);
      expect(fake.built, 2);
    });

    testWidgets('前の画面で残った古いトークンは、使わない', (tester) async {
      final fake = FakeTurnstile();
      final container = ProviderContainer(
        overrides: [
          turnstileViewBuilderProvider.overrideWithValue(fake.builder),
        ],
      );
      addTearDown(container.dispose);
      container.read(captchaTokenProvider.notifier).state = 'stale';
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: Scaffold(body: TurnstileField())),
        ),
      );
      await tester.pumpAndSettle();
      expect(container.read(captchaTokenProvider), isNull);
    });
  });

  group('認証のリポジトリ', () {
    SupabaseClient client() => SupabaseClient('http://localhost:1', 'anon-key');

    test('使う設定のとき、トークンがなければ、通信せずに失敗する', () async {
      final repository = AuthRepository(
        client(),
        captchaRequired: true,
        takeCaptchaToken: () => null,
      );
      for (final call in <Future<Object?> Function()>[
        () => repository.signInWithEmail(email: 'a@example.com', password: 'x'),
        () => repository.signUpWithEmail(email: 'a@example.com', password: 'x'),
        () => repository.sendPasswordReset('a@example.com'),
        () => repository.resendSignupEmail('a@example.com'),
      ]) {
        await expectLater(
          call,
          throwsA(
            isA<AuthException>().having(
              (e) => e.code,
              'code',
              'captcha_required',
            ),
          ),
        );
      }
    });

    test('使う設定のとき、通信の直前に、トークンを1回だけ取り出す', () async {
      var taken = 0;
      final repository = AuthRepository(
        client(),
        captchaRequired: true,
        takeCaptchaToken: () {
          taken++;
          return 'tok';
        },
      );
      // 通信先がないので失敗するが、その前に、取り出している。
      await expectLater(
        repository.signInWithEmail(email: 'a@example.com', password: 'x'),
        throwsA(anything),
      );
      expect(taken, 1);
    });

    test('使わない設定のとき、トークンを取り出さない(従来どおり)', () async {
      var taken = 0;
      final repository = AuthRepository(
        client(),
        takeCaptchaToken: () {
          taken++;
          return 'tok';
        },
      );
      await expectLater(
        repository.signInWithEmail(email: 'a@example.com', password: 'x'),
        throwsA(anything),
      );
      expect(taken, 0);
    });
  });
}
