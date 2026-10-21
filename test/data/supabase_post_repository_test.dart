import 'package:flutter_test/flutter_test.dart';
import 'package:kosodate_hitoiki/core/constants/app_icons.dart';
import 'package:kosodate_hitoiki/data/repositories/supabase_post_repository.dart';
import 'package:kosodate_hitoiki/domain/models/post.dart';

void main() {
  group('searchParams', () {
    test('語も種類もなければ、新着一覧(件数だけ)', () {
      expect(SupabasePostRepository.searchParams(query: ''), {'p_limit': 30});
      expect(SupabasePostRepository.searchParams(query: '  　'.trim()), {
        'p_limit': 30,
      });
    });

    test('語と種類は、APIの値にして渡す(前後の空白は除く)', () {
      expect(
        SupabasePostRepository.searchParams(
          query: ' 夜泣き 保育園 ',
          type: PostType.consult,
        ),
        {'p_query': '夜泣き 保育園', 'p_post_type': 'soudan', 'p_limit': 30},
      );
    });

    test('投稿の種類の変換は、往復で一致する', () {
      for (final type in PostType.values) {
        expect(
          SupabasePostRepository.postTypeFromCode(
            SupabasePostRepository.postTypeCode(type),
          ),
          type,
        );
      }
      expect(SupabasePostRepository.postTypeCode(PostType.grumble), 'guchi');
      expect(SupabasePostRepository.postTypeCode(PostType.tips), 'kotsu');
    });
  });

  group('postFromRow', () {
    Map<String, dynamic> row({String? authorId, String? iconKey}) => {
      'id': 'p-1',
      'author_id': authorId,
      'post_type': 'kotsu',
      'topic_id': null,
      'body': '夜泣きが落ち着いた方法です。',
      'reaction_mode': 'want_comments',
      'comment_acceptance': 'open',
      'created_at': '2026-10-21T01:02:03Z',
      'edited_at': null,
      'comment_count': 3,
      'author_nickname': 'はな',
      'author_icon_key': iconKey,
      'author_avatar_path': null,
    };

    test('未ログインの行(author_idなし)を、投稿にする', () {
      final post = SupabasePostRepository.postFromRow(row());
      expect(post.id, 'p-1');
      expect(post.authorId, '');
      expect(post.authorName, 'はな');
      expect(post.type, PostType.tips);
      expect(post.responseMode, ResponseMode.advice);
      expect(post.commentCount, 3);
      expect(post.empathyCount, 0);
      expect(post.isMine, isFalse);
      expect(post.createdAt.toUtc(), DateTime.utc(2026, 10, 21, 1, 2, 3));
    });

    test('自分の投稿かは、author_idと利用者IDの一致で決める', () {
      expect(
        SupabasePostRepository.postFromRow(
          row(authorId: 'me'),
          myUserId: 'me',
        ).isMine,
        isTrue,
      );
      expect(
        SupabasePostRepository.postFromRow(
          row(authorId: 'other'),
          myUserId: 'me',
        ).isMine,
        isFalse,
      );
      // 未ログイン(myUserIdなし)では、author_idがあっても自分の投稿にしない。
      expect(
        SupabasePostRepository.postFromRow(row(authorId: 'me')).isMine,
        isFalse,
      );
    });

    test('アカウント画像: 知っているicon_keyは対応する画像、なければ既定', () {
      expect(
        SupabasePostRepository.postFromRow(
          row(iconKey: 'tulip'),
        ).authorAvatarAsset,
        AppAvatars.defaultTulip,
      );
      expect(
        SupabasePostRepository.postFromRow(
          row(iconKey: 'unknown'),
        ).authorAvatarAsset,
        AppAvatars.defaultSprout,
      );
      expect(
        SupabasePostRepository.postFromRow(row()).authorAvatarAsset,
        AppAvatars.defaultSprout,
      );
    });

    test('反応モード: quiet_supportは「ただ聞いてほしい」', () {
      final post = SupabasePostRepository.postFromRow({
        ...row(),
        'reaction_mode': 'quiet_support',
      });
      expect(post.responseMode, ResponseMode.listening);
    });
  });
}
