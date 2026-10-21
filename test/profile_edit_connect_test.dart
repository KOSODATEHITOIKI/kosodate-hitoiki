import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kosodate_hitoiki/core/constants/app_icons.dart';
import 'package:kosodate_hitoiki/core/constants/app_theme.dart';
import 'package:kosodate_hitoiki/data/api/api_exception.dart';
import 'package:kosodate_hitoiki/data/repositories/supabase_profile_repository.dart';
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

/// プロフィール編集を、別の画面から開き、閉じたかを[closed]に入れる。
Future<void> pumpEdit(
  WidgetTester tester,
  ScriptedProfileRepository repository, {
  List<bool>? closed,
}) async {
  tester.view.physicalSize = const Size(390, 1200);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        currentUserIdProvider.overrideWithValue('me'),
        profileRepositoryProvider.overrideWithValue(repository),
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

Future<void> save(WidgetTester tester) async {
  FocusManager.instance.primaryFocus?.unfocus();
  await tester.pumpAndSettle();
  await tester.scrollUntilVisible(
    find.byKey(const ValueKey('profile-save')),
    200,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(const ValueKey('profile-save')));
  await tester.pumpAndSettle();
}

Future<void> typeInto(WidgetTester tester, String key, String text) async {
  await tester.scrollUntilVisible(
    find.byKey(ValueKey(key)),
    -200,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.enterText(find.byKey(ValueKey(key)), text);
  await tester.pumpAndSettle();
}

String _text(WidgetTester tester, String key) =>
    tester.widget<TextFormField>(find.byKey(ValueKey(key))).controller!.text;

void main() {
  testWidgets('開くと、いまのニックネーム・自己紹介が入っている。実データでは年齢帯を出さない', (tester) async {
    await pumpEdit(tester, ScriptedProfileRepository(profile: _me));
    expect(_text(tester, 'profile-nickname'), 'こもれび');
    expect(_text(tester, 'profile-bio'), 'もとの自己紹介');
    // 年齢帯の選択肢は未決定のため、実データでは出さない(送らない)。
    expect(find.byKey(const ValueKey('profile-age-band')), findsNothing);
  });

  testWidgets('何も変えずに保存すると、APIを呼ばず「変更はありません」', (tester) async {
    final repository = ScriptedProfileRepository(profile: _me);
    await pumpEdit(tester, repository);
    await save(tester);
    expect(repository.nicknameCalls, isEmpty);
    expect(repository.updateCalls, isEmpty);
    expect(find.text('変更はありません'), findsOneWidget);
  });

  testWidgets('ニックネームだけ変えたら、ニックネーム変更だけを呼ぶ(前後の空白は除く)', (tester) async {
    final repository = ScriptedProfileRepository(
      profile: _me,
      nicknameScript: [null],
    );
    final closed = <bool>[];
    await pumpEdit(tester, repository, closed: closed);
    await typeInto(tester, 'profile-nickname', '  あたらしい名前 ');
    await save(tester);

    expect(repository.nicknameCalls.single.nickname, 'あたらしい名前');
    expect(repository.nicknameCalls.single.confirmed, isFalse);
    expect(repository.updateCalls, isEmpty);
    expect(closed, [true]);
    expect(find.text('プロフィールを保存しました'), findsOneWidget);
  });

  testWidgets('自己紹介とアイコンを変えたら、変えた項目だけを更新に送る', (tester) async {
    final repository = ScriptedProfileRepository(
      profile: _me,
      updateScript: [null],
    );
    await pumpEdit(tester, repository);
    await typeInto(tester, 'profile-bio', 'あたらしい自己紹介');
    await tester.tap(find.byTooltip('チューリップのアイコン'));
    await tester.pumpAndSettle();
    await save(tester);

    expect(repository.nicknameCalls, isEmpty);
    final call = repository.updateCalls.single;
    expect(call.bio, 'あたらしい自己紹介');
    expect(call.iconKey, 'tulip');
    expect(call.age, isNull);
  });

  testWidgets('自己紹介を空にして保存すると、空の自己紹介を送る(消せる)', (tester) async {
    final repository = ScriptedProfileRepository(
      profile: _me,
      updateScript: [null],
    );
    await pumpEdit(tester, repository);
    await typeInto(tester, 'profile-bio', '');
    await save(tester);
    expect(repository.updateCalls.single.bio, '');
    expect(repository.updateCalls.single.iconKey, isNull);
  });

  testWidgets('両方変えたら、ニックネームのあとに更新を呼ぶ', (tester) async {
    final repository = ScriptedProfileRepository(
      profile: _me,
      nicknameScript: [null],
      updateScript: [null],
    );
    await pumpEdit(tester, repository);
    await typeInto(tester, 'profile-nickname', 'あたらしい名前');
    await typeInto(tester, 'profile-bio', 'あたらしい自己紹介');
    await save(tester);
    expect(repository.nicknameCalls, hasLength(1));
    expect(repository.updateCalls, hasLength(1));
  });

  testWidgets('短すぎるニックネームは、送らずに案内する', (tester) async {
    final repository = ScriptedProfileRepository(profile: _me);
    await pumpEdit(tester, repository);
    await typeInto(tester, 'profile-nickname', 'あ');
    await save(tester);
    expect(find.text('ニックネームは2〜12文字で入力してください。'), findsWidgets);
    expect(repository.nicknameCalls, isEmpty);
  });

  testWidgets('使用中のニックネームは、案内して、更新は呼ばない', (tester) async {
    final repository = ScriptedProfileRepository(
      profile: _me,
      nicknameScript: [
        const ApiException(code: 'CONFLICT', message: '', status: 409),
      ],
    );
    await pumpEdit(tester, repository);
    await typeInto(tester, 'profile-nickname', 'はな');
    await typeInto(tester, 'profile-bio', 'あたらしい自己紹介');
    await save(tester);

    expect(find.text('このニックネームは使えません。別のニックネームにしてください。'), findsOneWidget);
    expect(repository.updateCalls, isEmpty);
    // 入力は残る(直して、もう一度保存できる)。
    expect(_text(tester, 'profile-nickname'), 'はな');
  });

  testWidgets('30日以内の再変更など、サーバーの文言(日本語)をそのまま出す', (tester) async {
    final repository = ScriptedProfileRepository(
      profile: _me,
      nicknameScript: [
        const ApiException(
          code: 'VALIDATION_FAILED',
          message: 'ニックネームの変更は、30日に1回までです。',
          status: 422,
        ),
      ],
    );
    await pumpEdit(tester, repository);
    await typeInto(tester, 'profile-nickname', 'あたらしい名前');
    await save(tester);
    expect(find.text('ニックネームの変更は、30日に1回までです。'), findsOneWidget);
  });

  testWidgets('自己紹介の確認が必要なときは、確認後に confirmed:true で再送する', (tester) async {
    final repository = ScriptedProfileRepository(
      profile: _me,
      updateScript: [
        const ApiException(
          code: 'MODERATION_CONFIRM_REQUIRED',
          message: '強い言葉が含まれています。',
          status: 409,
        ),
        null,
      ],
    );
    await pumpEdit(tester, repository);
    await typeInto(tester, 'profile-bio', 'ありえない');
    await save(tester);
    expect(find.text('強い言葉が含まれています。'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('moderated-proceed')));
    await tester.pumpAndSettle();

    expect(repository.updateCalls, hasLength(2));
    expect(repository.updateCalls[0].confirmed, isFalse);
    expect(repository.updateCalls[1].confirmed, isTrue);
  });

  testWidgets('自己紹介が送信不可のときは理由を出し、入力は残る', (tester) async {
    final repository = ScriptedProfileRepository(
      profile: _me,
      updateScript: [
        const ApiException(
          code: 'MODERATION_REJECTED',
          message: '',
          status: 422,
          details: {
            'reasons': ['pii_phone'],
          },
        ),
      ],
    );
    await pumpEdit(tester, repository);
    await typeInto(tester, 'profile-bio', '090-0000-0000');
    await save(tester);
    expect(find.textContaining('個人が特定される情報'), findsOneWidget);
    expect(_text(tester, 'profile-bio'), '090-0000-0000');
  });

  testWidgets('ニックネームは保存できたが自己紹介が失敗しても、やり直しでニックネームを二重に送らない', (tester) async {
    final repository = ScriptedProfileRepository(
      profile: _me,
      nicknameScript: [null],
      updateScript: [Exception('network'), null],
    );
    await pumpEdit(tester, repository);
    await typeInto(tester, 'profile-nickname', 'あたらしい名前');
    await typeInto(tester, 'profile-bio', 'あたらしい自己紹介');
    await save(tester);
    expect(find.byKey(const ValueKey('profile-error')), findsOneWidget);
    expect(repository.nicknameCalls, hasLength(1));

    await save(tester);
    expect(repository.nicknameCalls, hasLength(1));
    expect(repository.updateCalls, hasLength(2));
  });

  testWidgets('サンプルのときは、保存せず「準備中」と案内する', (tester) async {
    final repository = ScriptedProfileRepository(profile: _me, sample: true);
    await pumpEdit(tester, repository);
    await typeInto(tester, 'profile-bio', 'あたらしい自己紹介');
    await save(tester);
    expect(find.text('プロフィールの保存は準備中です'), findsOneWidget);
    expect(repository.updateCalls, isEmpty);
    expect(find.byKey(const ValueKey('profile-age-band')), findsOneWidget);
  });

  group('プロフィール更新のリクエスト', () {
    test('指定した項目だけを入れる(空の自己紹介も送れる)', () {
      expect(SupabaseProfileRepository.updateBody(), isEmpty);
      expect(SupabaseProfileRepository.updateBody(bio: '  こんにちは '), {
        'bio': 'こんにちは',
      });
      expect(SupabaseProfileRepository.updateBody(bio: ''), {'bio': ''});
      expect(
        SupabaseProfileRepository.updateBody(iconKey: 'tulip', confirmed: true),
        {'icon_key': 'tulip', 'confirmed': true},
      );
    });

    test('アカウント画像と icon_key は、相互に変換できる', () {
      for (final asset in [
        AppAvatars.defaultSprout,
        AppAvatars.defaultSun,
        AppAvatars.defaultLittleBird,
        AppAvatars.defaultYellowFlower,
        AppAvatars.defaultTulip,
        AppAvatars.defaultBlueFlowers,
      ]) {
        expect(AppAvatars.forIconKey(AppAvatars.keyFor(asset)), asset);
      }
    });
  });
}
