import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kosodate_hitoiki/app.dart';
import 'package:kosodate_hitoiki/data/push/push_messaging.dart';
import 'package:kosodate_hitoiki/data/repositories/auth_repository.dart';
import 'package:kosodate_hitoiki/presentation/providers/auth_provider.dart';
import 'package:kosodate_hitoiki/presentation/providers/push_providers.dart';
import 'package:kosodate_hitoiki/presentation/widgets/main_navigation_shell.dart';
import 'package:mocktail/mocktail.dart';

class _MockAuth extends Mock implements AuthRepository {}

class _Messaging implements PushMessaging {
  final taps = StreamController<PushTap>.broadcast();
  final foreground = StreamController<PushTap>.broadcast();
  PushTap? initial;

  @override
  bool get isAvailable => false;

  @override
  Future<bool> requestPermission() async => false;

  @override
  Future<String?> getToken() async => null;

  @override
  Stream<String> get onTokenRefresh => const Stream.empty();

  @override
  Stream<PushTap> get onTap => taps.stream;

  @override
  Stream<PushTap> get onForeground => foreground.stream;

  @override
  Future<PushTap?> getInitialTap() async => initial;
}

/// ログイン状態は、isLoggedInProviderで決める。プロフィールの確認は、利用者なしとして、行わない。
_MockAuth _auth() {
  final auth = _MockAuth();
  when(() => auth.currentUser).thenReturn(null);
  when(() => auth.authStateChanges).thenAnswer((_) => const Stream.empty());
  return auth;
}

void main() {
  late _Messaging messaging;

  Future<ProviderContainer> pumpApp(
    WidgetTester tester, {
    bool login = true,
  }) async {
    messaging = _Messaging();
    addTearDown(messaging.taps.close);
    addTearDown(messaging.foreground.close);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          isLoggedInProvider.overrideWithValue(login),
          pushMessagingProvider.overrideWithValue(messaging),
          authRepositoryProvider.overrideWithValue(_auth()),
        ],
        child: const App(),
      ),
    );
    await tester.pumpAndSettle();
    return ProviderScope.containerOf(tester.element(find.byType(App)));
  }

  testWidgets('アプリを開いているときに通知が届いたら、短く知らせる', (tester) async {
    await pumpApp(tester);
    messaging.foreground.add(const PushTap(notificationId: 'n-1'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('新しいお知らせがあります'), findsOneWidget);
    tester.widget<SnackBarAction>(find.byType(SnackBarAction)).onPressed();
    await tester.pumpAndSettle();
    final container = ProviderScope.containerOf(
      tester.element(find.byType(App)),
    );
    expect(container.read(bottomNavIndexProvider), notificationsTabIndex);
  });

  testWidgets('ログインしていなければ、知らせない', (tester) async {
    await pumpApp(tester, login: false);
    messaging.foreground.add(const PushTap());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('新しいお知らせがあります'), findsNothing);
  });

  testWidgets('通知をタップしたら、お知らせのタブを開く', (tester) async {
    final container = await pumpApp(tester);
    expect(container.read(bottomNavIndexProvider), 0);
    messaging.taps.add(const PushTap(notificationId: 'n-1'));
    await tester.pumpAndSettle();
    expect(container.read(bottomNavIndexProvider), notificationsTabIndex);
  });

  testWidgets('通知をタップして起動したときも、お知らせのタブを開く', (tester) async {
    messaging = _Messaging()..initial = const PushTap(notificationId: 'n-1');
    addTearDown(messaging.taps.close);
    addTearDown(messaging.foreground.close);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          isLoggedInProvider.overrideWithValue(true),
          pushMessagingProvider.overrideWithValue(messaging),
          authRepositoryProvider.overrideWithValue(_auth()),
        ],
        child: const App(),
      ),
    );
    await tester.pumpAndSettle();
    final container = ProviderScope.containerOf(
      tester.element(find.byType(App)),
    );
    expect(container.read(bottomNavIndexProvider), notificationsTabIndex);
  });
}
