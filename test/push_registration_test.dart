import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kosodate_hitoiki/data/push/push_messaging.dart';
import 'package:kosodate_hitoiki/data/repositories/supabase_push_device_repository.dart';
import 'package:kosodate_hitoiki/domain/repositories/push_device_repository.dart';
import 'package:kosodate_hitoiki/presentation/providers/auth_provider.dart';
import 'package:kosodate_hitoiki/presentation/providers/push_providers.dart';

class _FakeMessaging implements PushMessaging {
  _FakeMessaging({this.granted = true});

  final bool granted;
  final String? token = 'token-1';
  var permissionRequests = 0;
  final refresh = StreamController<String>.broadcast();

  @override
  bool get isAvailable => true;

  @override
  Future<bool> requestPermission() async {
    permissionRequests++;
    return granted;
  }

  @override
  Future<String?> getToken() async => token;

  @override
  Stream<String> get onTokenRefresh => refresh.stream;

  @override
  Stream<PushTap> get onTap => const Stream.empty();

  @override
  Stream<PushTap> get onForeground => const Stream.empty();

  @override
  Future<PushTap?> getInitialTap() async => null;
}

class _FakeDevices implements PushDeviceRepository {
  final registered = <String>[];
  final unregistered = <String>[];
  Object? registerError;

  @override
  Future<void> register(String token) async {
    if (registerError != null) throw registerError!;
    registered.add(token);
  }

  @override
  Future<void> unregister(String token) async => unregistered.add(token);
}

Future<void> _settle() => Future<void>.delayed(Duration.zero);

void main() {
  late StateProvider<String?> user;
  late _FakeDevices devices;

  ProviderContainer containerWith(_FakeMessaging messaging) {
    user = StateProvider<String?>((ref) => null);
    devices = _FakeDevices();
    final container = ProviderContainer(
      overrides: [
        currentUserIdProvider.overrideWith((ref) => ref.watch(user)),
        pushMessagingProvider.overrideWithValue(messaging),
        pushDeviceRepositoryProvider.overrideWithValue(devices),
      ],
    );
    addTearDown(container.dispose);
    addTearDown(messaging.refresh.close);
    container.read(pushRegistrationProvider);
    return container;
  }

  test('登録の引数', () {
    expect(SupabasePushDeviceRepository.registerParams('android', 'abc'), {
      'p_platform': 'android',
      'p_token': 'abc',
    });
  });

  test('ログインしていない間は、許可も求めず、登録もしない', () async {
    final messaging = _FakeMessaging();
    containerWith(messaging);
    await _settle();
    expect(messaging.permissionRequests, 0);
    expect(devices.registered, isEmpty);
  });

  test('ログインしたら、許可を求めて、端末を登録する', () async {
    final messaging = _FakeMessaging();
    final container = containerWith(messaging);
    container.read(user.notifier).state = 'u-1';
    await _settle();
    await _settle();

    expect(messaging.permissionRequests, 1);
    expect(devices.registered, ['token-1']);
    expect(container.read(registeredPushTokenProvider), 'token-1');
  });

  test('許可されなければ、登録しない(アプリは使える)', () async {
    final messaging = _FakeMessaging(granted: false);
    final container = containerWith(messaging);
    container.read(user.notifier).state = 'u-1';
    await _settle();
    await _settle();

    expect(devices.registered, isEmpty);
    expect(container.read(registeredPushTokenProvider), isNull);
  });

  test('トークンが変わったら、登録し直す', () async {
    final messaging = _FakeMessaging();
    final container = containerWith(messaging);
    container.read(user.notifier).state = 'u-1';
    await _settle();
    await _settle();

    messaging.refresh.add('token-2');
    await _settle();
    await _settle();
    expect(devices.registered, ['token-1', 'token-2']);
    expect(container.read(registeredPushTokenProvider), 'token-2');
  });

  test('登録に失敗しても、止まらない(登録済みにしない)', () async {
    final messaging = _FakeMessaging();
    final container = containerWith(messaging);
    // 先にログインしてしまうと失敗を仕込めないので、登録の失敗を用意してからログインする。
    devices.registerError = Exception('network');
    container.read(user.notifier).state = 'u-1';
    await _settle();
    await _settle();

    expect(container.read(registeredPushTokenProvider), isNull);
  });

  test('ログアウトの前の解除は、登録したトークンを外す。登録がなければ何もしない', () async {
    final messaging = _FakeMessaging();
    final container = containerWith(messaging);

    await unregisterPushDevice(container);
    expect(devices.unregistered, isEmpty);

    container.read(user.notifier).state = 'u-1';
    await _settle();
    await _settle();
    await unregisterPushDevice(container);
    expect(devices.unregistered, ['token-1']);
    expect(container.read(registeredPushTokenProvider), isNull);
  });

  test('利用者が別の人に変わったら、新しい人として登録し直す', () async {
    final messaging = _FakeMessaging();
    final container = containerWith(messaging);
    container.read(user.notifier).state = 'u-1';
    await _settle();
    await _settle();

    container.read(user.notifier).state = 'u-2';
    await _settle();
    await _settle();
    expect(devices.registered, ['token-1', 'token-1']);
  });

  test('使えないとき(設定ファイルがない)は、何もしない', () async {
    user = StateProvider<String?>((ref) => 'u-1');
    final container = ProviderContainer(
      overrides: [currentUserIdProvider.overrideWith((ref) => ref.watch(user))],
    );
    addTearDown(container.dispose);
    container.read(pushRegistrationProvider);
    await _settle();
    expect(container.read(registeredPushTokenProvider), isNull);
  });
}
