import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kosodate_hitoiki/core/constants/app_theme.dart';
import 'package:kosodate_hitoiki/domain/models/user_profile.dart';
import 'package:kosodate_hitoiki/presentation/pages/mypage/mypage_page.dart';
import 'package:kosodate_hitoiki/presentation/pages/profile/profile_edit_page.dart';
import 'package:kosodate_hitoiki/presentation/providers/auth_provider.dart';
import 'package:kosodate_hitoiki/presentation/providers/post_providers.dart';
import 'package:kosodate_hitoiki/presentation/providers/profile_providers.dart';
import 'package:kosodate_hitoiki/presentation/widgets/app_asset.dart';

import 'helpers/scripted_post_repository.dart';
import 'helpers/scripted_profile_repository.dart';

/// 自分の写真(四角い画像)を、アイコンにしているとき。どこでも、丸く切り抜いて見せる。
const _photo = UserProfile(
  id: 'me',
  nickname: 'こもれび',
  avatarAsset: 'https://example.test/storage/v1/object/public/avatars/me/a.png',
  bio: '',
);

Future<void> pumpWith(WidgetTester tester, Widget page) async {
  tester.view.physicalSize = const Size(390, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        isLoggedInProvider.overrideWithValue(true),
        currentUserIdProvider.overrideWithValue('me'),
        postRepositoryProvider.overrideWithValue(ScriptedPostRepository([])),
        profileRepositoryProvider.overrideWithValue(
          ScriptedProfileRepository(profile: _photo),
        ),
      ],
      child: MaterialApp(theme: AppTheme.light, home: page),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('マイページの写真のアイコンは、丸く切り抜く(Containerの形で切る)', (tester) async {
    await pumpWith(tester, const Scaffold(body: MyPagePage()));
    final container = tester.widget<Container>(
      find
          .ancestor(of: find.byType(AppAsset), matching: find.byType(Container))
          .first,
    );
    expect(container.clipBehavior, Clip.antiAlias);
    expect((container.decoration as BoxDecoration).shape, BoxShape.circle);
  });

  testWidgets('プロフィール編集の、いまの写真のアイコンは、丸く切り抜く', (tester) async {
    await pumpWith(tester, const ProfileEditPage());
    expect(
      find.ancestor(of: find.byType(AppAsset), matching: find.byType(ClipOval)),
      findsWidgets,
    );
  });
}
