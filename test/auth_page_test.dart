import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kosodate_hitoiki/core/constants/app_theme.dart';
import 'package:kosodate_hitoiki/data/api/api_exception.dart';
import 'package:kosodate_hitoiki/data/repositories/auth_repository.dart';
import 'package:kosodate_hitoiki/data/repositories/profile_registration_repository.dart';
import 'package:kosodate_hitoiki/presentation/pages/auth/auth_page.dart';
import 'package:kosodate_hitoiki/presentation/pages/auth/legal_document_page.dart';
import 'package:kosodate_hitoiki/presentation/pages/auth/profile_setup_page.dart';
import 'package:kosodate_hitoiki/presentation/providers/auth_provider.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class _MockAuth extends Mock implements AuthRepository {}

class _MockProfiles extends Mock implements ProfileRegistrationRepository {}

User _user({Map<String, dynamic>? metadata}) => User(
  id: 'user-1',
  appMetadata: const {},
  userMetadata: metadata,
  aud: 'authenticated',
  createdAt: '2026-10-21T00:00:00Z',
);

AuthResponse _signedIn({Map<String, dynamic>? metadata}) => AuthResponse(
  user: _user(metadata: metadata),
  session: Session(
    accessToken: 'token',
    tokenType: 'bearer',
    user: _user(metadata: metadata),
  ),
);

void main() {
  late _MockAuth auth;
  late _MockProfiles profiles;

  setUp(() {
    auth = _MockAuth();
    profiles = _MockProfiles();
    when(() => auth.signOut()).thenAnswer((_) async {});
  });

  Future<void> pumpAuth(
    WidgetTester tester, {
    AuthMode mode = AuthMode.login,
  }) async {
    // 戻り先が分かるよう、AuthPageは別の画面から開く。
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(auth),
          profileRegistrationRepositoryProvider.overrideWithValue(profiles),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          home: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: TextButton(
                  onPressed: () => Navigator.of(context).push<void>(
                    MaterialPageRoute(
                      builder: (_) => AuthPage(initialMode: mode),
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

  Future<void> submit(WidgetTester tester) async {
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const ValueKey('auth-submit')));
    await tester.tap(find.byKey(const ValueKey('auth-submit')));
    await tester.pumpAndSettle();
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
  }

  /// 本文を開いて最後までスクロールし、「同意する」で戻る。
  Future<void> readDocument(WidgetTester tester, Key consentKey) async {
    await tester.ensureVisible(find.byKey(consentKey));
    await tester.tap(find.byKey(consentKey));
    await tester.pumpAndSettle();
    expect(find.byType(LegalDocumentPage), findsOneWidget);
    for (var i = 0; i < 10; i++) {
      await tester.drag(
        find.byType(SingleChildScrollView),
        const Offset(0, -600),
      );
      await tester.pumpAndSettle();
    }
    await tester.tap(find.byKey(const ValueKey('legal-done')));
    await tester.pumpAndSettle();
  }

  Future<void> agreeBoth(WidgetTester tester) async {
    await readDocument(tester, const ValueKey('consent-terms'));
    await readDocument(tester, const ValueKey('consent-privacy'));
  }

  Future<void> fillRegister(WidgetTester tester) async {
    await tester.enterText(find.byKey(const ValueKey('auth-nickname')), 'はなこ');
    await fillLogin(tester);
    await agreeBoth(tester);
  }

  testWidgets('ログインの入力検証とパスワード表示切替', (tester) async {
    await pumpAuth(tester);
    await submit(tester);
    expect(find.text('メールアドレスを入力してください。'), findsOneWidget);
    expect(find.text('パスワードを入力してください。'), findsOneWidget);
    verifyZeroInteractions(auth);

    await fillLogin(tester);
    await tester.ensureVisible(find.byTooltip('パスワードを表示'));
    await tester.tap(find.byTooltip('パスワードを表示'));
    await tester.pumpAndSettle();
    expect(find.byTooltip('パスワードを隠す'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('何も入力せず入力欄をタップして離れただけでは、赤くしない', (tester) async {
    await pumpAuth(tester, mode: AuthMode.register);
    final errorColor = AppTheme.light.colorScheme.error;
    bool anyRed() => tester
        .widgetList<Text>(find.byType(Text))
        .any((text) => text.style?.color == errorColor);

    // ニックネーム → メール → パスワード と、順にタップして通り過ぎる。
    for (final key in ['auth-nickname', 'auth-email', 'auth-password']) {
      await tester.ensureVisible(find.byKey(ValueKey(key)));
      await tester.tap(find.byKey(ValueKey(key)));
      await tester.pumpAndSettle();
    }
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pumpAndSettle();
    expect(anyRed(), isFalse);
    expect(find.text('メールアドレスを入力してください。'), findsNothing);

    // 何か入力して間違ったまま離れたときは、赤くする。
    await tester.enterText(find.byKey(const ValueKey('auth-email')), 'abc');
    await tester.tap(find.byKey(const ValueKey('auth-nickname')));
    await tester.pumpAndSettle();
    expect(anyRed(), isTrue);
  });

  testWidgets('登録の入力欄: 入力の途中は赤くせず足りないことを案内し、離れて間違っていれば赤くする', (tester) async {
    await pumpAuth(tester, mode: AuthMode.register);
    final errorColor = AppTheme.light.colorScheme.error;

    Color? helperColor(String text) =>
        tester.widget<Text>(find.text(text)).style?.color;

    // 1文字だけ入力: 入力の途中なので、赤ではなく案内として「あと1文字」を出す。
    await tester.enterText(find.byKey(const ValueKey('auth-nickname')), 'あ');
    await tester.pump();
    expect(find.textContaining('あと1文字必要です'), findsOneWidget);
    expect(helperColor('あと1文字必要です。(2〜12文字)'), isNot(errorColor));

    // 入力欄を離れても間違ったままなら、赤いエラーになる。
    await tester.tap(find.byKey(const ValueKey('auth-email')));
    await tester.pumpAndSettle();
    expect(helperColor('あと1文字必要です。(2〜12文字)'), errorColor);

    // 直すと、赤い表示は消える。
    await tester.enterText(find.byKey(const ValueKey('auth-nickname')), 'あい');
    await tester.pumpAndSettle();
    expect(find.textContaining('あと1文字'), findsNothing);

    // メール: 「@」がない間は案内を出し、直せば案内も消える。
    await tester.enterText(find.byKey(const ValueKey('auth-email')), 'abc');
    await tester.pump();
    expect(find.textContaining('「@」を含めてください'), findsOneWidget);
    await tester.enterText(
      find.byKey(const ValueKey('auth-email')),
      'a@example.com',
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('「@」を含めてください'), findsNothing);
    expect(find.text('他の人には公開されません'), findsOneWidget);
  });

  testWidgets('登録は、利用規約とプライバシーポリシーを最後まで読んで2つチェックがつくまで押せない', (tester) async {
    await pumpAuth(tester, mode: AuthMode.register);

    FilledButton submitButton() =>
        tester.widget<FilledButton>(find.byKey(const ValueKey('auth-submit')));
    bool checked(String key) =>
        tester.widget<CheckboxListTile>(find.byKey(ValueKey(key))).value!;

    // 最初は登録できず、2つとも未チェック。
    await tester.ensureVisible(find.byKey(const ValueKey('auth-submit')));
    expect(submitButton().onPressed, isNull);
    expect(checked('consent-terms'), isFalse);
    expect(checked('consent-privacy'), isFalse);

    // 本文を開いても、最後まで読まずに戻ればチェックはつかない。
    await tester.ensureVisible(find.byKey(const ValueKey('consent-terms')));
    await tester.tap(find.byKey(const ValueKey('consent-terms')));
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<FilledButton>(find.byKey(const ValueKey('legal-done')))
          .onPressed,
      isNull,
    );
    expect(find.byKey(const ValueKey('legal-draft-banner')), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(checked('consent-terms'), isFalse);

    // 1つ読んでも、残りの1つがまだなら登録できない。
    await readDocument(tester, const ValueKey('consent-terms'));
    expect(checked('consent-terms'), isTrue);
    expect(checked('consent-privacy'), isFalse);
    expect(submitButton().onPressed, isNull);

    // 2つともチェックがつくと、登録できる。
    await readDocument(tester, const ValueKey('consent-privacy'));
    expect(checked('consent-privacy'), isTrue);
    expect(submitButton().onPressed, isNotNull);

    // チェックは外せて、外すと登録できなくなる。
    await tester.tap(find.byKey(const ValueKey('consent-terms')));
    await tester.pumpAndSettle();
    expect(checked('consent-terms'), isFalse);
    expect(submitButton().onPressed, isNull);
  });

  testWidgets('ログイン成功でプロフィール作成済みなら、画面を閉じて元へ戻る', (tester) async {
    when(
      () => auth.signInWithEmail(
        email: any(named: 'email'),
        password: any(named: 'password'),
      ),
    ).thenAnswer((_) async => _signedIn());
    when(() => profiles.hasProfile('user-1')).thenAnswer((_) async => true);

    await pumpAuth(tester);
    await fillLogin(tester);
    await submit(tester);

    verify(
      () =>
          auth.signInWithEmail(email: 'a@example.com', password: 'password123'),
    ).called(1);
    expect(find.byType(AuthPage), findsNothing);
    expect(find.text('開く'), findsOneWidget);
  });

  testWidgets('パスワード違いは、登録の有無を示さない文言で表示する', (tester) async {
    when(
      () => auth.signInWithEmail(
        email: any(named: 'email'),
        password: any(named: 'password'),
      ),
    ).thenThrow(const AuthApiException('x', code: 'invalid_credentials'));

    await pumpAuth(tester);
    await fillLogin(tester);
    await submit(tester);

    expect(find.text('メールアドレスまたはパスワードが違います。'), findsOneWidget);
    expect(find.byType(AuthPage), findsOneWidget);
  });

  testWidgets('登録後にメール確認が必要なら、確認メールの案内を表示する', (tester) async {
    when(
      () => auth.signUpWithEmail(
        email: any(named: 'email'),
        password: any(named: 'password'),
        data: any(named: 'data'),
      ),
    ).thenAnswer((_) async => AuthResponse(user: _user()));

    await pumpAuth(tester, mode: AuthMode.register);
    await fillRegister(tester);
    await submit(tester);

    verify(
      () => auth.signUpWithEmail(
        email: 'a@example.com',
        password: 'password123',
        data: {'nickname': 'はなこ', 'terms_agreed': true},
      ),
    ).called(1);
    expect(find.text('確認メールを送りました'), findsOneWidget);
    verifyNever(
      () => profiles.create(
        nickname: any(named: 'nickname'),
        termsVersion: any(named: 'termsVersion'),
        confirmed: any(named: 'confirmed'),
      ),
    );

    await tester.tap(find.byKey(const ValueKey('auth-to-login')));
    await tester.pumpAndSettle();
    expect(find.text('ログインする'), findsOneWidget);
  });

  testWidgets('メール確認後の初回ログインで、控えたニックネームからプロフィールを作る', (tester) async {
    when(
      () => auth.signInWithEmail(
        email: any(named: 'email'),
        password: any(named: 'password'),
      ),
    ).thenAnswer(
      (_) async =>
          _signedIn(metadata: {'nickname': 'はなこ', 'terms_agreed': true}),
    );
    when(() => profiles.hasProfile('user-1')).thenAnswer((_) async => false);
    when(
      () => profiles.create(
        nickname: any(named: 'nickname'),
        termsVersion: any(named: 'termsVersion'),
        confirmed: any(named: 'confirmed'),
      ),
    ).thenAnswer((_) async {});

    await pumpAuth(tester);
    await fillLogin(tester);
    await submit(tester);

    verify(
      () => profiles.create(
        nickname: 'はなこ',
        termsVersion: any(named: 'termsVersion'),
        confirmed: false,
      ),
    ).called(1);
    expect(find.byType(AuthPage), findsNothing);
  });

  testWidgets('送信前チェックの確認が必要なら、確認後に confirmed: true で再送する', (tester) async {
    when(
      () => auth.signInWithEmail(
        email: any(named: 'email'),
        password: any(named: 'password'),
      ),
    ).thenAnswer(
      (_) async =>
          _signedIn(metadata: {'nickname': 'はなこ', 'terms_agreed': true}),
    );
    when(() => profiles.hasProfile('user-1')).thenAnswer((_) async => false);
    when(
      () => profiles.create(
        nickname: any(named: 'nickname'),
        termsVersion: any(named: 'termsVersion'),
        confirmed: false,
      ),
    ).thenThrow(
      const ApiException(
        code: 'MODERATION_CONFIRM_REQUIRED',
        message: '強い言葉が含まれています。',
        status: 409,
      ),
    );
    when(
      () => profiles.create(
        nickname: any(named: 'nickname'),
        termsVersion: any(named: 'termsVersion'),
        confirmed: true,
      ),
    ).thenAnswer((_) async {});

    await pumpAuth(tester);
    await fillLogin(tester);
    await submit(tester);

    expect(find.text('強い言葉が含まれています。'), findsOneWidget);
    await tester.tap(find.text('そのまま登録'));
    await tester.pumpAndSettle();

    verify(
      () => profiles.create(
        nickname: 'はなこ',
        termsVersion: any(named: 'termsVersion'),
        confirmed: true,
      ),
    ).called(1);
    expect(find.byType(AuthPage), findsNothing);
  });

  testWidgets('控えがないときはプロフィール登録へ進み、中断するとログアウトする', (tester) async {
    when(
      () => auth.signInWithEmail(
        email: any(named: 'email'),
        password: any(named: 'password'),
      ),
    ).thenAnswer((_) async => _signedIn());
    when(() => profiles.hasProfile('user-1')).thenAnswer((_) async => false);

    await pumpAuth(tester);
    await fillLogin(tester);
    await submit(tester);

    expect(find.byType(ProfileSetupPage), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();

    verify(() => auth.signOut()).called(1);
    expect(find.byType(ProfileSetupPage), findsNothing);
  });

  testWidgets('プロフィール登録でニックネームが使用中なら、案内を出して入力へ戻す', (tester) async {
    when(
      () => auth.signInWithEmail(
        email: any(named: 'email'),
        password: any(named: 'password'),
      ),
    ).thenAnswer((_) async => _signedIn());
    when(() => profiles.hasProfile('user-1')).thenAnswer((_) async => false);
    when(
      () => profiles.create(
        nickname: any(named: 'nickname'),
        termsVersion: any(named: 'termsVersion'),
        confirmed: any(named: 'confirmed'),
      ),
    ).thenThrow(const ApiException(code: 'CONFLICT', message: '', status: 409));

    await pumpAuth(tester);
    await fillLogin(tester);
    await submit(tester);

    await tester.enterText(find.byKey(const ValueKey('setup-nickname')), 'はなこ');
    await agreeBoth(tester);
    await tester.tap(find.byKey(const ValueKey('setup-submit')));
    await tester.pumpAndSettle();

    expect(find.text('このニックネームは使えません。別のニックネームにしてください。'), findsOneWidget);
    expect(find.byType(ProfileSetupPage), findsOneWidget);
  });

  testWidgets('小さい画面・文字拡大で登録と再設定へ移動できる', (tester) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: AppTheme.light,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: const TextScaler.linear(1.5)),
            child: child!,
          ),
          home: const AuthPage(),
        ),
      ),
    );
    await tester.ensureVisible(find.text('会員登録へ'));
    await tester.tap(find.text('会員登録へ'));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('auth-nickname')), findsOneWidget);
    expect(find.byType(CheckboxListTile), findsNWidgets(2));
    await tester.ensureVisible(find.text('ログインへ'));
    await tester.tap(find.text('ログインへ'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('パスワードを忘れた方'));
    await tester.tap(find.text('パスワードを忘れた方'));
    await tester.pumpAndSettle();
    expect(find.text('パスワード再設定'), findsOneWidget);
    expect(find.byKey(const ValueKey('auth-password')), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
