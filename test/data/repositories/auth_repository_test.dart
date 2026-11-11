import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kosodate_hitoiki/data/repositories/auth_repository.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MockSupabaseClient extends Mock implements SupabaseClient {}

class MockGoTrueClient extends Mock implements GoTrueClient {}

void main() {
  late MockSupabaseClient client;
  late MockGoTrueClient auth;
  late AuthRepository repository;

  setUpAll(() => registerFallbackValue(OAuthProvider.apple));

  setUp(() {
    client = MockSupabaseClient();
    auth = MockGoTrueClient();
    when(() => client.auth).thenReturn(auth);
    repository = AuthRepository(client);
  });

  test('signInWithEmail は GoTrueClient.signInWithPassword に委譲する', () async {
    when(
      () => auth.signInWithPassword(
        email: any(named: 'email'),
        password: any(named: 'password'),
      ),
    ).thenAnswer((_) async => AuthResponse());

    await repository.signInWithEmail(
      email: 'a@example.com',
      password: 'password123',
    );

    verify(
      () => auth.signInWithPassword(
        email: 'a@example.com',
        password: 'password123',
      ),
    ).called(1);
  });

  test('signUpWithEmail は GoTrueClient.signUp に委譲する', () async {
    when(
      () => auth.signUp(
        email: any(named: 'email'),
        password: any(named: 'password'),
      ),
    ).thenAnswer((_) async => AuthResponse());

    await repository.signUpWithEmail(
      email: 'a@example.com',
      password: 'password123',
    );

    verify(
      () => auth.signUp(email: 'a@example.com', password: 'password123'),
    ).called(1);
  });

  group('Appleでサインイン', () {
    AuthorizationCredentialAppleID credential({String? idToken = 'id-token'}) =>
        AuthorizationCredentialAppleID(
          userIdentifier: 'apple-user',
          givenName: null,
          familyName: null,
          email: null,
          authorizationCode: 'auth-code',
          identityToken: idToken,
          state: null,
        );

    test('Appleにはnonceのハッシュを、Supabaseには元のnonceを渡す', () async {
      String? sentNonce;
      List<AppleIDAuthorizationScopes>? sentScopes;
      repository = AuthRepository(
        client,
        getAppleCredential: ({required scopes, nonce}) async {
          sentScopes = scopes;
          sentNonce = nonce;
          return credential();
        },
      );
      when(
        () => auth.signInWithIdToken(
          provider: any(named: 'provider'),
          idToken: any(named: 'idToken'),
          nonce: any(named: 'nonce'),
        ),
      ).thenAnswer((_) async => AuthResponse());

      await repository.signInWithApple();

      final rawNonce =
          verify(
                () => auth.signInWithIdToken(
                  provider: OAuthProvider.apple,
                  idToken: 'id-token',
                  nonce: captureAny(named: 'nonce'),
                ),
              ).captured.single
              as String;
      expect(rawNonce, isNotEmpty);
      expect(sentNonce, sha256.convert(utf8.encode(rawNonce)).toString());
      expect(sentScopes, [AppleIDAuthorizationScopes.email]);
    });

    test('Appleの画面を閉じたら、nullを返し、Supabaseに問い合わせない', () async {
      repository = AuthRepository(
        client,
        getAppleCredential: ({required scopes, nonce}) async =>
            throw const SignInWithAppleAuthorizationException(
              code: AuthorizationErrorCode.canceled,
              message: 'canceled',
            ),
      );

      expect(await repository.signInWithApple(), isNull);
      verifyNever(
        () => auth.signInWithIdToken(
          provider: any(named: 'provider'),
          idToken: any(named: 'idToken'),
          nonce: any(named: 'nonce'),
        ),
      );
    });

    test('IDトークンがなければ、失敗にする', () async {
      repository = AuthRepository(
        client,
        getAppleCredential: ({required scopes, nonce}) async =>
            credential(idToken: null),
      );

      await expectLater(
        repository.signInWithApple(),
        throwsA(isA<AuthException>()),
      );
    });

    test('退会用の認可コードを返す。閉じたらnull', () async {
      repository = AuthRepository(
        client,
        getAppleCredential: ({required scopes, nonce}) async => credential(),
      );
      expect(await repository.appleAuthorizationCode(), 'auth-code');

      repository = AuthRepository(
        client,
        getAppleCredential: ({required scopes, nonce}) async =>
            throw const SignInWithAppleAuthorizationException(
              code: AuthorizationErrorCode.canceled,
              message: 'canceled',
            ),
      );
      expect(await repository.appleAuthorizationCode(), isNull);
    });
  });

  group('Web(Apple JS)で閉じたとき', () {
    AuthRepository throwing(String message) => AuthRepository(
      client,
      getAppleCredential: ({required scopes, nonce}) async =>
          throw SignInWithAppleCredentialsException(message: message),
    );

    test('ポップアップを閉じた・やめたなら、nullを返す', () async {
      for (final error in [
        'popup_closed_by_user',
        'user_cancelled_authorize',
      ]) {
        repository = throwing('Authentication failed with $error');
        expect(await repository.appleAuthorizationCode(), isNull);
      }
    });

    test('それ以外の失敗は、そのまま失敗にする', () async {
      repository = throwing('Authentication failed with invalid_client');
      await expectLater(
        repository.appleAuthorizationCode(),
        throwsA(isA<SignInWithAppleCredentialsException>()),
      );
    });
  });

  group('usesAppleSignIn', () {
    User user(Map<String, dynamic> appMetadata) => User(
      id: 'u',
      appMetadata: appMetadata,
      userMetadata: const {},
      aud: 'authenticated',
      createdAt: '2026-11-10T00:00:00Z',
    );

    test('providersにappleがあれば、true', () {
      expect(
        usesAppleSignIn(
          user({
            'providers': ['email', 'apple'],
          }),
        ),
        isTrue,
      );
    });

    test('appleがなければ・ログインしていなければ、false', () {
      expect(
        usesAppleSignIn(
          user({
            'providers': ['google'],
          }),
        ),
        isFalse,
      );
      expect(usesAppleSignIn(null), isFalse);
    });
  });

  // signInWithGoogle(GoTrueClientのsignInWithOAuth拡張)は、
  // 内部でブラウザ起動を伴うFlutter拡張メソッドのため、単体テストでの検証は行わない。
  // 実際の動作確認はSupabaseプロジェクト作成後、実機/エミュレータで行う。

  test('signOut は GoTrueClient.signOut に委譲する', () async {
    when(() => auth.signOut()).thenAnswer((_) async {});

    await repository.signOut();

    verify(() => auth.signOut()).called(1);
  });
}
