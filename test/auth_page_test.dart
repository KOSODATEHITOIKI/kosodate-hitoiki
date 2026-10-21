import 'dart:async';

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

  /// ログイン状態の変化(Googleの認証から戻ったときなど)を流す。
  late StreamController<AuthState> authEvents;

  setUp(() {
    auth = _MockAuth();
    profiles = _MockProfiles();
    authEvents = StreamController<AuthState>.broadcast();
    addTearDown(authEvents.close);
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
          authStateChangesProvider.overrideWith((ref) => authEvents.stream),
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
    await tester.enterText(
      find.byKey(const ValueKey('auth-email')),
      'a@example.com',
    );
    await tester.enterText(
      find.byKey(const ValueKey('auth-password')),
      'Password1234',
    );
    await tester.enterText(
      find.byKey(const ValueKey('auth-password-confirm')),
      'Password1234',
    );
    await agreeBoth(tester);
  }

  testWidgets('Appleでのログインは、フェーズ2まで出さない', (tester) async {
    await pumpAuth(tester);
    expect(find.text('Appleで続ける'), findsNothing);
    expect(find.text('Googleで続ける'), findsOneWidget);
  });

  group('Googleで続ける', () {
    Future<void> tapGoogle(WidgetTester tester) async {
      await tester.ensureVisible(find.byKey(const ValueKey('auth-google')));
      await tester.tap(find.byKey(const ValueKey('auth-google')));
      await tester.pumpAndSettle();
    }

    testWidgets('認証画面を開き、戻るまで待つ(案内を出す)', (tester) async {
      when(() => auth.signInWithGoogle()).thenAnswer((_) async => true);
      await pumpAuth(tester);
      await tapGoogle(tester);

      verify(() => auth.signInWithGoogle()).called(1);
      expect(find.byKey(const ValueKey('auth-google-waiting')), findsOneWidget);
      expect(find.byType(AuthPage), findsOneWidget);
    });

    testWidgets('認証画面を開けなかったら、案内して、待たない', (tester) async {
      when(() => auth.signInWithGoogle()).thenAnswer((_) async => false);
      await pumpAuth(tester);
      await tapGoogle(tester);

      expect(find.text('Googleの認証画面を開けませんでした。もう一度お試しください。'), findsOneWidget);
      expect(find.byKey(const ValueKey('auth-google-waiting')), findsNothing);
    });

    testWidgets('戻ってログインできたら、プロフィールがあれば画面を閉じる', (tester) async {
      when(() => auth.signInWithGoogle()).thenAnswer((_) async => true);
      when(() => profiles.hasProfile('user-1')).thenAnswer((_) async => true);
      await pumpAuth(tester);
      await tapGoogle(tester);

      authEvents.add(AuthState(AuthChangeEvent.signedIn, _signedIn().session));
      await tester.pumpAndSettle();

      verify(() => profiles.hasProfile('user-1')).called(1);
      expect(find.byType(AuthPage), findsNothing);
    });

    testWidgets('初めての利用者は、ニックネームと同意の画面へ進む', (tester) async {
      when(() => auth.signInWithGoogle()).thenAnswer((_) async => true);
      when(() => profiles.hasProfile('user-1')).thenAnswer((_) async => false);
      await pumpAuth(tester);
      await tapGoogle(tester);

      authEvents.add(AuthState(AuthChangeEvent.signedIn, _signedIn().session));
      await tester.pumpAndSettle();

      expect(find.byType(ProfileSetupPage), findsOneWidget);
    });

    testWidgets('待っていないときのログインの通知では、何もしない', (tester) async {
      await pumpAuth(tester);
      authEvents.add(AuthState(AuthChangeEvent.signedIn, _signedIn().session));
      await tester.pumpAndSettle();

      verifyNever(() => profiles.hasProfile(any()));
      expect(find.byType(AuthPage), findsOneWidget);
    });

    testWidgets('認証が失敗して戻ったら、案内する', (tester) async {
      when(() => auth.signInWithGoogle()).thenAnswer((_) async => true);
      await pumpAuth(tester);
      await tapGoogle(tester);

      authEvents.addError(const AuthException('access_denied'));
      await tester.pumpAndSettle();

      expect(find.text('Googleでのログインを完了できませんでした。もう一度お試しください。'), findsOneWidget);
      expect(find.byKey(const ValueKey('auth-google-waiting')), findsNothing);
    });
  });

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

  testWidgets('登録のパスワード: 条件を案内し、足りないことを下に出し、確認用と一致しないと登録できない', (tester) async {
    await pumpAuth(tester, mode: AuthMode.register);
    final errorColor = AppTheme.light.colorScheme.error;
    Color? colorOf(String text) =>
        tester.widget<Text>(find.text(text)).style?.color;

    // 条件が、最初から下に出ている。
    expect(
      find.text('10文字以上で、英大文字・英小文字・数字を、それぞれ1文字以上入れてください。'),
      findsOneWidget,
    );

    // 入力の途中は、足りないことを赤くせずに案内する。
    await tester.enterText(
      find.byKey(const ValueKey('auth-password')),
      'password',
    );
    await tester.pump();
    expect(find.text('あと2文字・英大文字・数字が必要です。'), findsOneWidget);
    expect(colorOf('あと2文字・英大文字・数字が必要です。'), isNot(errorColor));

    await tester.enterText(
      find.byKey(const ValueKey('auth-password')),
      'Password1234',
    );
    await tester.pump();
    expect(find.text('条件を満たしています。'), findsOneWidget);

    // 確認用: 一致しない間は案内し、離れても間違ったままなら赤くする。
    await tester.enterText(
      find.byKey(const ValueKey('auth-password-confirm')),
      'Password',
    );
    await tester.pump();
    expect(find.text('まだ一致していません。'), findsOneWidget);
    await tester.ensureVisible(find.byKey(const ValueKey('auth-nickname')));
    await tester.tap(find.byKey(const ValueKey('auth-nickname')));
    await tester.pumpAndSettle();
    expect(find.text('パスワードが一致しません。'), findsOneWidget);
    expect(colorOf('パスワードが一致しません。'), errorColor);

    await tester.enterText(
      find.byKey(const ValueKey('auth-password-confirm')),
      'Password1234',
    );
    await tester.pumpAndSettle();
    expect(find.text('一致しています。'), findsOneWidget);
    expect(find.text('パスワードが一致しません。'), findsNothing);
  });

  testWidgets('規約・プライバシーから戻っても、入力欄にフォーカスが戻らずキーボードが出ない', (tester) async {
    await pumpAuth(tester, mode: AuthMode.register);
    await tester.tap(find.byKey(const ValueKey('auth-nickname')));
    await tester.pumpAndSettle();
    expect(FocusManager.instance.primaryFocus?.hasFocus, isTrue);

    await readDocument(tester, const ValueKey('consent-terms'));

    // 入力欄(EditableText)にフォーカスが戻っていない。
    final focus = FocusManager.instance.primaryFocus;
    expect(
      focus?.context?.findAncestorWidgetOfExactType<EditableText>() ??
          focus?.context?.widget is EditableText,
      anyOf(isNull, isFalse),
    );
    expect(
      tester
          .state<EditableTextState>(
            find.descendant(
              of: find.byKey(const ValueKey('auth-nickname')),
              matching: find.byType(EditableText),
            ),
          )
          .widget
          .focusNode
          .hasFocus,
      isFalse,
    );
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
        password: 'Password1234',
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

  group('登録済みかどうかを漏らさない案内', () {
    void stubSignUpNeedsConfirmation() {
      when(
        () => auth.signUpWithEmail(
          email: any(named: 'email'),
          password: any(named: 'password'),
          data: any(named: 'data'),
        ),
      ).thenAnswer((_) async => AuthResponse(user: _user()));
    }

    Future<void> registerAndSubmit(WidgetTester tester) async {
      await pumpAuth(tester, mode: AuthMode.register);
      await fillRegister(tester);
      await submit(tester);
    }

    testWidgets('確認メールの画面: 説明・届かないときの案内・3つのボタンが出る', (tester) async {
      stubSignUpNeedsConfirmation();
      await registerAndSubmit(tester);

      expect(find.text('確認メールを送りました'), findsOneWidget);
      expect(
        find.text('確認メールを送りました。メール内のボタンを押して、確認を完了してください。'),
        findsOneWidget,
      );
      expect(find.text('迷惑メールフォルダーを確認する'), findsOneWidget);
      expect(find.text('メールアドレスの入力ミスがないか確認する'), findsOneWidget);
      expect(
        find.textContaining(
          'すでに登録済みの可能性があります。その場合は、ログイン、またはパスワードの再設定をお試しください。',
        ),
        findsOneWidget,
      );
      expect(find.byKey(const ValueKey('auth-to-login')), findsOneWidget);
      expect(find.byKey(const ValueKey('auth-to-reset')), findsOneWidget);
      expect(find.byKey(const ValueKey('auth-resend')), findsOneWidget);
    });

    testWidgets('登録済みのアドレス(user_already_exists)でも、同じ画面になり、使用済みとは出さない', (
      tester,
    ) async {
      when(
        () => auth.signUpWithEmail(
          email: any(named: 'email'),
          password: any(named: 'password'),
          data: any(named: 'data'),
        ),
      ).thenThrow(
        const AuthApiException('exists', code: 'user_already_exists'),
      );
      await registerAndSubmit(tester);

      expect(find.text('確認メールを送りました'), findsOneWidget);
      expect(find.byKey(const ValueKey('auth-resend')), findsOneWidget);
      expect(find.textContaining('(あと60秒)'), findsOneWidget);
      expect(find.textContaining('すでに使われて'), findsNothing);
      expect(find.byKey(const ValueKey('auth-error')), findsNothing);
    });

    testWidgets('再送は60秒待たせ、残り秒数を出す。待ったあとに送れて、また待つ', (tester) async {
      stubSignUpNeedsConfirmation();
      when(
        () => auth.resendSignupEmail(any()),
      ).thenAnswer((_) async => ResendResponse());
      await registerAndSubmit(tester);

      OutlinedButton resend() => tester.widget<OutlinedButton>(
        find.byKey(const ValueKey('auth-resend')),
      );
      expect(resend().onPressed, isNull);
      expect(find.text('確認メールをもう一度送る(あと60秒)'), findsOneWidget);

      await tester.pump(const Duration(seconds: 30));
      expect(find.text('確認メールをもう一度送る(あと30秒)'), findsOneWidget);
      expect(resend().onPressed, isNull);
      verifyNever(() => auth.resendSignupEmail(any()));

      await tester.pump(const Duration(seconds: 31));
      expect(find.text('確認メールをもう一度送る'), findsOneWidget);
      expect(resend().onPressed, isNotNull);

      await tester.tap(find.byKey(const ValueKey('auth-resend')));
      await tester.pump();
      verify(() => auth.resendSignupEmail('a@example.com')).called(1);
      expect(find.text('確認メールをもう一度送りました。'), findsOneWidget);
      // 送ったあとは、また待たせる。
      expect(resend().onPressed, isNull);
      expect(find.textContaining('(あと60秒)'), findsOneWidget);
    });

    testWidgets('「パスワードを再設定する」で、入力したアドレスのまま再設定へ進む', (tester) async {
      stubSignUpNeedsConfirmation();
      await registerAndSubmit(tester);

      await tester.tap(find.byKey(const ValueKey('auth-to-reset')));
      await tester.pumpAndSettle();
      expect(find.text('パスワード再設定'), findsWidgets);
      expect(
        tester
            .widget<TextFormField>(find.byKey(const ValueKey('auth-email')))
            .controller!
            .text,
        'a@example.com',
      );
    });

    for (final failure in <bool>[false, true]) {
      testWidgets('再設定: 登録の有無にかかわらず、同じ文面(${failure ? 'エラー' : '成功'})', (
        tester,
      ) async {
        if (failure) {
          when(() => auth.sendPasswordReset(any())).thenThrow(
            const AuthApiException('not found', code: 'user_not_found'),
          );
        } else {
          when(() => auth.sendPasswordReset(any())).thenAnswer((_) async {});
        }
        await pumpAuth(tester, mode: AuthMode.reset);
        await tester.enterText(
          find.byKey(const ValueKey('auth-email')),
          'a@example.com',
        );
        await submit(tester);

        verify(() => auth.sendPasswordReset('a@example.com')).called(1);
        expect(
          find.text(
            '登録されている場合は、再設定のメールを送りました。'
            '届かない場合は、迷惑メールを確認するか、アドレスをご確認ください。',
          ),
          findsOneWidget,
        );
        expect(find.byKey(const ValueKey('auth-error')), findsNothing);
      });
    }

    testWidgets('再設定: 送信回数の制限のときだけ、そのことを伝える', (tester) async {
      when(() => auth.sendPasswordReset(any())).thenThrow(
        const AuthApiException('limit', code: 'over_email_send_rate_limit'),
      );
      await pumpAuth(tester, mode: AuthMode.reset);
      await tester.enterText(
        find.byKey(const ValueKey('auth-email')),
        'a@example.com',
      );
      await submit(tester);

      expect(find.text('しばらく時間をおいてから、もう一度お試しください。'), findsOneWidget);
      expect(find.byKey(const ValueKey('auth-reset-sent')), findsNothing);
    });
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
