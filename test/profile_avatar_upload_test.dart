import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kosodate_hitoiki/core/constants/app_icons.dart';
import 'package:kosodate_hitoiki/core/constants/app_theme.dart';
import 'package:kosodate_hitoiki/data/api/api_exception.dart';
import 'package:kosodate_hitoiki/data/avatar_picker.dart';
import 'package:kosodate_hitoiki/domain/models/picked_avatar.dart';
import 'package:kosodate_hitoiki/domain/models/user_profile.dart';
import 'package:kosodate_hitoiki/presentation/pages/profile/profile_edit_page.dart';
import 'package:kosodate_hitoiki/presentation/providers/auth_provider.dart';
import 'package:kosodate_hitoiki/presentation/providers/profile_providers.dart';

import 'helpers/scripted_profile_repository.dart';

const _me = UserProfile(
  id: 'me',
  nickname: 'こもれび',
  avatarAsset: AppAvatars.defaultSprout,
  bio: 'もとの自己紹介',
);

/// 1x1の本物のPNG(画面に出せる)。
final _png = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg==',
);

class _Picker implements AvatarPicker {
  _Picker(this.results);

  /// 呼び出しごとに1つ使う。nullは「選ばずに戻った」、例外は投げる。
  final List<Object?> results;
  var calls = 0;

  @override
  Future<PickedAvatar?> pick() async {
    calls++;
    final next = results.removeAt(0);
    if (next is Exception) throw next;
    return next as PickedAvatar?;
  }
}

Future<void> pumpEdit(
  WidgetTester tester,
  ScriptedProfileRepository repository,
  AvatarPicker picker, {
  List<bool>? closed,
}) async {
  tester.view.physicalSize = const Size(390, 1600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        currentUserIdProvider.overrideWithValue('me'),
        profileRepositoryProvider.overrideWithValue(repository),
        avatarPickerProvider.overrideWithValue(picker),
      ],
      child: MaterialApp(
        theme: AppTheme.light,
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: TextButton(
                onPressed: () async {
                  await Navigator.of(context).push<void>(
                    MaterialPageRoute(builder: (_) => const ProfileEditPage()),
                  );
                  closed?.add(true);
                },
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

Future<void> tapKey(WidgetTester tester, String key) async {
  await tester.ensureVisible(find.byKey(ValueKey(key)));
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(ValueKey(key)));
  await tester.pumpAndSettle();
}

Future<void> pickPhoto(WidgetTester tester) =>
    tapKey(tester, 'profile-pick-photo');
Future<void> save(WidgetTester tester) => tapKey(tester, 'profile-save');

void main() {
  group('画像の形式と大きさ', () {
    test('JPEG・PNG・WebPを、先頭のバイト列で見分ける', () {
      expect(
        PickedAvatar.detectContentType(
          Uint8List.fromList([0xFF, 0xD8, 0xFF, 0xE0]),
        ),
        'image/jpeg',
      );
      expect(PickedAvatar.detectContentType(_png), 'image/png');
      expect(
        PickedAvatar.detectContentType(
          Uint8List.fromList([
            ...'RIFF'.codeUnits,
            0,
            0,
            0,
            0,
            ...'WEBP'.codeUnits,
          ]),
        ),
        'image/webp',
      );
      expect(
        PickedAvatar.detectContentType(Uint8List.fromList('GIF89a'.codeUnits)),
        isNull,
      );
      expect(PickedAvatar.detectContentType(Uint8List(0)), isNull);
    });

    test('対応外の形式・2MBを超える画像は、選べない', () {
      expect(
        () => PickedAvatar.fromBytes(Uint8List.fromList('GIF89a'.codeUnits)),
        throwsA(isA<AvatarPickException>()),
      );
      final big = Uint8List(PickedAvatar.maxBytes + 1)..setRange(0, 8, _png);
      expect(
        () => PickedAvatar.fromBytes(big),
        throwsA(isA<AvatarPickException>()),
      );
      final ok = Uint8List(PickedAvatar.maxBytes)..setRange(0, 8, _png);
      expect(PickedAvatar.fromBytes(ok).contentType, 'image/png');
    });
  });

  testWidgets('写真を選んでも保存までは送らず、保存で画像だけを送って閉じる', (tester) async {
    final repository = ScriptedProfileRepository(profile: _me);
    final picker = _Picker([PickedAvatar.fromBytes(_png)]);
    final closed = <bool>[];
    await pumpEdit(tester, repository, picker, closed: closed);
    expect(find.byKey(const ValueKey('profile-photo-notice')), findsOneWidget);

    await pickPhoto(tester);
    expect(find.byKey(const ValueKey('profile-photo-preview')), findsOneWidget);
    expect(repository.avatarCalls, isEmpty);

    await save(tester);
    expect(repository.avatarCalls, hasLength(1));
    expect(repository.avatarCalls.single.contentType, 'image/png');
    // 写真だけ変えたとき、icon_keyは送らない(送ると写真が外れる)。
    expect(repository.updateCalls, isEmpty);
    expect(repository.nicknameCalls, isEmpty);
    expect(closed, [true]);
  });

  testWidgets('選ばずに戻ったら、何も変わらない', (tester) async {
    final repository = ScriptedProfileRepository(profile: _me);
    await pumpEdit(tester, repository, _Picker([null]));
    await pickPhoto(tester);
    expect(find.byKey(const ValueKey('profile-photo-preview')), findsNothing);
    await save(tester);
    expect(repository.avatarCalls, isEmpty);
    expect(find.text('変更はありません'), findsOneWidget);
  });

  testWidgets('使えない画像を選んだら、案内して、送らない', (tester) async {
    final repository = ScriptedProfileRepository(profile: _me);
    final picker = _Picker([const AvatarPickException('この形式の画像は使えません。')]);
    await pumpEdit(tester, repository, picker);
    await pickPhoto(tester);
    expect(find.text('この形式の画像は使えません。'), findsOneWidget);
    expect(find.byKey(const ValueKey('profile-photo-preview')), findsNothing);
    expect(repository.avatarCalls, isEmpty);
  });

  testWidgets('画像の判定で断られたら、案内して閉じず、保存し直せる', (tester) async {
    final repository = ScriptedProfileRepository(
      profile: _me,
      avatarScript: [
        const ApiException(
          code: 'MODERATION_REJECTED',
          message: '',
          status: 422,
        ),
        null,
      ],
    );
    final closed = <bool>[];
    await pumpEdit(
      tester,
      repository,
      _Picker([PickedAvatar.fromBytes(_png)]),
      closed: closed,
    );
    await pickPhoto(tester);
    await save(tester);
    expect(find.text('選んだ画像は使えませんでした。別の画像を選んでください。'), findsOneWidget);
    expect(closed, isEmpty);

    await save(tester);
    expect(repository.avatarCalls, hasLength(2));
    expect(closed, [true]);
  });

  testWidgets('写真を選んだあとにイラストを選ぶと、写真は送らず、イラストだけ送る', (tester) async {
    final repository = ScriptedProfileRepository(
      profile: _me,
      updateScript: [null],
    );
    await pumpEdit(tester, repository, _Picker([PickedAvatar.fromBytes(_png)]));
    await pickPhoto(tester);
    await tester.ensureVisible(find.byTooltip('チューリップのアイコン'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('チューリップのアイコン'));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('profile-photo-preview')), findsNothing);
    await save(tester);
    expect(repository.avatarCalls, isEmpty);
    expect(repository.updateCalls.single.iconKey, 'tulip');
  });

  testWidgets('画像を送れたあと、あとの項目で失敗しても、画像を二重に送らない', (tester) async {
    final repository = ScriptedProfileRepository(
      profile: _me,
      updateScript: [Exception('network'), null],
    );
    await pumpEdit(tester, repository, _Picker([PickedAvatar.fromBytes(_png)]));
    await pickPhoto(tester);
    await tester.ensureVisible(find.byKey(const ValueKey('profile-bio')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('profile-bio')),
      '新しい自己紹介',
    );
    await save(tester);
    expect(repository.avatarCalls, hasLength(1));
    expect(repository.updateCalls, hasLength(1));

    await save(tester);
    expect(repository.avatarCalls, hasLength(1));
    expect(repository.updateCalls, hasLength(2));
  });
}
