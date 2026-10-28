import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kosodate_hitoiki/app.dart';
import 'package:kosodate_hitoiki/data/repositories/auth_repository.dart';
import 'package:kosodate_hitoiki/data/repositories/profile_registration_repository.dart';
import 'package:kosodate_hitoiki/presentation/pages/auth/auth_page.dart';
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
  createdAt: '2026-10-28T00:00:00Z',
);

void main() {
  late _MockAuth auth;
  late _MockProfiles profiles;

  setUp(() {
    AuthPage.openCount = 0;
    auth = _MockAuth();
    profiles = _MockProfiles();
    when(() => auth.authStateChanges).thenAnswer((_) => const Stream.empty());
    when(() => auth.signOut()).thenAnswer((_) async {});
  });

  Future<void> pumpApp(WidgetTester tester, {User? user}) async {
    when(() => auth.currentUser).thenReturn(user);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(auth),
          profileRegistrationRepositoryProvider.overrideWithValue(profiles),
          isLoggedInProvider.overrideWithValue(user != null),
        ],
        child: const App(),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('ログイン済みでプロフィールがなければ、起動時に、登録の画面へ進む', (tester) async {
    when(() => profiles.hasProfile('user-1')).thenAnswer((_) async => false);
    await pumpApp(tester, user: _user());

    expect(find.byType(ProfileSetupPage), findsOneWidget);
  });

  testWidgets('登録をやめたら、ログアウトする(プロフィールのない状態を残さない)', (tester) async {
    when(() => profiles.hasProfile('user-1')).thenAnswer((_) async => false);
    await pumpApp(tester, user: _user());

    await tester.pageBack();
    await tester.pumpAndSettle();
    verify(() => auth.signOut()).called(1);
  });

  testWidgets('プロフィールがあれば、何もしない', (tester) async {
    when(() => profiles.hasProfile('user-1')).thenAnswer((_) async => true);
    await pumpApp(tester, user: _user());

    expect(find.byType(ProfileSetupPage), findsNothing);
    verifyNever(() => auth.signOut());
  });

  testWidgets('ログインしていなければ、確認しない', (tester) async {
    await pumpApp(tester);
    verifyNever(() => profiles.hasProfile(any()));
  });

  testWidgets('確認できなくても(通信の失敗)、アプリは使える。ログアウトもしない', (tester) async {
    when(() => profiles.hasProfile('user-1')).thenThrow(Exception('network'));
    await pumpApp(tester, user: _user());

    expect(find.byType(ProfileSetupPage), findsNothing);
    verifyNever(() => auth.signOut());
  });

  testWidgets('控えたニックネームと同意があれば、自動で作る', (tester) async {
    when(() => profiles.hasProfile('user-1')).thenAnswer((_) async => false);
    when(
      () => profiles.create(
        nickname: any(named: 'nickname'),
        termsVersion: any(named: 'termsVersion'),
        confirmed: any(named: 'confirmed'),
      ),
    ).thenAnswer((_) async {});
    await pumpApp(
      tester,
      user: _user(metadata: {'nickname': 'はなこ', 'terms_agreed': true}),
    );

    verify(
      () => profiles.create(
        nickname: 'はなこ',
        termsVersion: any(named: 'termsVersion'),
        confirmed: false,
      ),
    ).called(1);
    expect(find.byType(ProfileSetupPage), findsNothing);
  });

  testWidgets('認証画面を開いている間は、アプリ全体では確認しない(その画面が行う)', (tester) async {
    AuthPage.openCount = 1;
    when(() => profiles.hasProfile('user-1')).thenAnswer((_) async => false);
    await pumpApp(tester, user: _user());

    verifyNever(() => profiles.hasProfile(any()));
    expect(find.byType(ProfileSetupPage), findsNothing);
  });
}
