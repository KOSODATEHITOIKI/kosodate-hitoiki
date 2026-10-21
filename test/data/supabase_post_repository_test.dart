import 'package:flutter_test/flutter_test.dart';
import 'package:kosodate_hitoiki/core/constants/app_icons.dart';
import 'package:kosodate_hitoiki/data/api/idempotency_key.dart';
import 'package:kosodate_hitoiki/data/repositories/supabase_post_repository.dart';
import 'package:kosodate_hitoiki/domain/models/post.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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

  group('投稿作成のリクエスト', () {
    test('本文は前後の空白を除き、種類・反応モードをAPIの値にする(話題は送らない)', () {
      expect(
        SupabasePostRepository.createBody(
          type: PostType.tips,
          responseMode: ResponseMode.advice,
          body: '  夜泣きが落ち着きました。\n',
        ),
        {
          'post_type': 'kotsu',
          'body': '夜泣きが落ち着きました。',
          'reaction_mode': 'want_comments',
        },
      );
    });

    test('確認後の再送は confirmed: true を付ける', () {
      final body = SupabasePostRepository.createBody(
        type: PostType.grumble,
        responseMode: ResponseMode.listening,
        body: 'つかれた',
        confirmed: true,
      );
      expect(body['confirmed'], isTrue);
      expect(body['reaction_mode'], 'quiet_support');
      expect(body['post_type'], 'guchi');
    });
  });

  test('冪等キーはUUID(v4)の形で、毎回違う', () {
    final keys = {for (var i = 0; i < 50; i++) newIdempotencyKey()};
    expect(keys, hasLength(50));
    final pattern = RegExp(
      r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
    );
    expect(keys.every(pattern.hasMatch), isTrue);
  });

  group('編集APIの応答', () {
    test('edited_at と support_notice を読む', () {
      final result = SupabasePostRepository.editResultFromResponse({
        'id': 'p-1',
        'edited_at': '2026-10-21T01:02:03Z',
        'support_notice': true,
      });
      expect(result.editedAt!.toUtc(), DateTime.utc(2026, 10, 21, 1, 2, 3));
      expect(result.supportNotice, isTrue);
    });

    test('本文が変わらなかったとき(edited_at が null)や、応答が空でも壊れない', () {
      final unchanged = SupabasePostRepository.editResultFromResponse({
        'id': 'p-1',
        'edited_at': null,
        'support_notice': false,
      });
      expect(unchanged.editedAt, isNull);
      expect(unchanged.supportNotice, isFalse);
      expect(
        SupabasePostRepository.editResultFromResponse(null).editedAt,
        isNull,
      );
    });
  });

  group('保存・重複', () {
    test('保存しているかは、渡した値(isSaved)で決まる', () {
      final row = {
        'id': 'p-1',
        'author_id': null,
        'post_type': 'guchi',
        'body': 'つかれた',
        'reaction_mode': 'quiet_support',
        'created_at': '2026-10-21T01:02:03Z',
        'comment_count': 0,
        'author_nickname': 'はな',
        'author_icon_key': null,
      };
      expect(SupabasePostRepository.postFromRow(row).isSaved, isFalse);
      expect(
        SupabasePostRepository.postFromRow(row, isSaved: true).isSaved,
        isTrue,
      );
    });

    test('一意制約違反(23505・409)は、重ねた操作として成功扱いにする', () {
      expect(
        SupabasePostRepository.isDuplicate(
          const PostgrestException(message: 'duplicate', code: '23505'),
        ),
        isTrue,
      );
      expect(
        SupabasePostRepository.isDuplicate(
          const PostgrestException(message: 'conflict', code: '409'),
        ),
        isTrue,
      );
      // 見えない投稿・存在しない投稿(42501)は、成功扱いにしない。
      expect(
        SupabasePostRepository.isDuplicate(
          const PostgrestException(message: 'denied', code: '42501'),
        ),
        isFalse,
      );
    });
  });
}
