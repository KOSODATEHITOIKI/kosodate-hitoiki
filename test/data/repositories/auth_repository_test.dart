import 'package:flutter_test/flutter_test.dart';
import 'package:kosodate_hitoiki/data/repositories/auth_repository.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MockSupabaseClient extends Mock implements SupabaseClient {}

class MockGoTrueClient extends Mock implements GoTrueClient {}

void main() {
  late MockSupabaseClient client;
  late MockGoTrueClient auth;
  late AuthRepository repository;

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

  // signInWithGoogle/signInWithApple(GoTrueClientのsignInWithOAuth拡張)は、
  // 内部でブラウザ起動を伴うFlutter拡張メソッドのため、単体テストでの検証は行わない。
  // 実際の動作確認はSupabaseプロジェクト作成後、実機/エミュレータで行う。

  test('signOut は GoTrueClient.signOut に委譲する', () async {
    when(() => auth.signOut()).thenAnswer((_) async {});

    await repository.signOut();

    verify(() => auth.signOut()).called(1);
  });
}
