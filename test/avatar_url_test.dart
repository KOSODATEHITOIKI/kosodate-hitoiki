import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kosodate_hitoiki/core/config/supabase_config.dart';
import 'package:kosodate_hitoiki/core/constants/app_icons.dart';
import 'package:kosodate_hitoiki/data/repositories/supabase_comment_repository.dart';
import 'package:kosodate_hitoiki/data/repositories/supabase_post_repository.dart';
import 'package:kosodate_hitoiki/data/repositories/supabase_profile_repository.dart';
import 'package:kosodate_hitoiki/presentation/widgets/app_asset.dart';

const _path = 'u-1/a-1.png';

void main() {
  final url = SupabaseConfig.avatarUrl(_path);

  test('公開URLは、Storageのavatarsバケットのパスになる', () {
    expect(url, startsWith('https://'));
    expect(url, endsWith('/storage/v1/object/public/avatars/$_path'));
  });

  group('アップロード画像があれば、その公開URLを使う', () {
    test('forRow: avatar_pathが優先。なければicon_key、どちらもなければ既定', () {
      expect(AppAvatars.forRow(iconKey: 'tulip', avatarPath: _path), url);
      expect(
        AppAvatars.forRow(iconKey: 'tulip', avatarPath: null),
        AppAvatars.defaultTulip,
      );
      expect(
        AppAvatars.forRow(iconKey: null, avatarPath: ''),
        AppAvatars.defaultSprout,
      );
    });

    test('投稿・コメント・プロフィールの行に反映される', () {
      final post = SupabasePostRepository.postFromRow({
        'id': 'p-1',
        'author_nickname': 'はな',
        'author_avatar_path': _path,
        'post_type': 'tips',
        'body': '本文',
        'created_at': '2026-10-21T00:00:00Z',
      });
      expect(post.authorAvatarAsset, url);

      final comment = SupabaseCommentRepository.commentFromRow({
        'id': 'c-1',
        'author_nickname': 'はな',
        'author_avatar_path': _path,
        'body': '本文',
        'created_at': '2026-10-21T00:00:00Z',
      });
      expect(comment.authorAvatarAsset, url);

      final profile = SupabaseProfileRepository.profileFromRow({
        'id': 'u-1',
        'nickname': 'はな',
        'avatar_path': _path,
      });
      expect(profile.avatarAsset, url);
    });

    test('自分の投稿(my_posts)にも、自分の画像を付ける', () {
      final post = SupabasePostRepository.myPostFromRow(
        {
          'id': 'p-1',
          'post_type': 'tips',
          'body': '本文',
          'created_at': '2026-10-21T00:00:00Z',
        },
        myUserId: 'me',
        nickname: 'はな',
        avatarPath: _path,
      );
      expect(post.authorAvatarAsset, url);
    });
  });

  testWidgets('画像を読めないときは、既定のイラストを出し、例外にしない', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: AppAsset(url, width: 40, height: 40, excludeFromSemantics: true),
      ),
    );
    await tester.pump();
    await tester.pump();
    // テストのHTTPは常に失敗(400)する。落ちずに、イラストの画像へ切り替わる。
    final images = tester.widgetList<Image>(find.byType(Image)).toList();
    expect(
      images.any(
        (image) =>
            image.image is ResizeImage &&
            ((image.image as ResizeImage).imageProvider is AssetImage),
      ),
      isTrue,
    );
    expect(tester.takeException(), isNull);
  });
}
