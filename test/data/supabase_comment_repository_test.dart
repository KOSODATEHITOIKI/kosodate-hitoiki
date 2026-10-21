import 'package:flutter_test/flutter_test.dart';
import 'package:kosodate_hitoiki/core/constants/app_icons.dart';
import 'package:kosodate_hitoiki/data/repositories/supabase_comment_repository.dart';

void main() {
  Map<String, dynamic> row({
    String? parentId,
    String? body = 'こんにちは',
    bool isDeleted = false,
    String? editedAt,
    String? authorId = 'author-1',
    String? iconKey,
  }) => {
    'id': 'c-1',
    'author_id': authorId,
    'parent_comment_id': parentId,
    'body': body,
    'is_deleted': isDeleted,
    'created_at': '2026-10-21T01:02:03Z',
    'edited_at': editedAt,
    'author_nickname': 'はな',
    'author_icon_key': iconKey,
    'author_avatar_path': null,
  };

  group('commentFromRow', () {
    test('コメントの行を、アプリのコメントにする', () {
      final comment = SupabaseCommentRepository.commentFromRow(row());
      expect(comment.id, 'c-1');
      expect(comment.authorName, 'はな');
      expect(comment.body, 'こんにちは');
      expect(comment.isReply, isFalse);
      expect(comment.isDeleted, isFalse);
      expect(comment.isEdited, isFalse);
      expect(comment.createdAt.toUtc(), DateTime.utc(2026, 10, 21, 1, 2, 3));
    });

    test('返信は parent_comment_id を持つ', () {
      final comment = SupabaseCommentRepository.commentFromRow(
        row(parentId: 'c-0'),
      );
      expect(comment.isReply, isTrue);
      expect(comment.parentId, 'c-0');
    });

    test('削除済みは本文がnull、編集済みは edited_at があるとき', () {
      final deleted = SupabaseCommentRepository.commentFromRow(
        row(isDeleted: true, body: null),
      );
      expect(deleted.isDeleted, isTrue);
      expect(deleted.body, isNull);
      final edited = SupabaseCommentRepository.commentFromRow(
        row(editedAt: '2026-10-21T02:00:00Z'),
      );
      expect(edited.isEdited, isTrue);
    });

    test('自分のコメントかは、author_id と利用者IDの一致で決める', () {
      expect(
        SupabaseCommentRepository.commentFromRow(
          row(authorId: 'me'),
          myUserId: 'me',
        ).isMine,
        isTrue,
      );
      expect(
        SupabaseCommentRepository.commentFromRow(
          row(authorId: 'other'),
          myUserId: 'me',
        ).isMine,
        isFalse,
      );
    });

    test('アカウント画像: 知っているicon_keyは対応する画像、なければ既定', () {
      expect(
        SupabaseCommentRepository.commentFromRow(
          row(iconKey: 'tulip'),
        ).authorAvatarAsset,
        AppAvatars.defaultTulip,
      );
      expect(
        SupabaseCommentRepository.commentFromRow(row()).authorAvatarAsset,
        AppAvatars.defaultSprout,
      );
    });
  });

  group('createBody', () {
    test('本文は前後の空白を除く。返信は親コメントのIDを付ける', () {
      expect(
        SupabaseCommentRepository.createBody(
          postId: 'p-1',
          body: '  わかります  ',
          parentId: 'c-1',
        ),
        {'post_id': 'p-1', 'parent_comment_id': 'c-1', 'body': 'わかります'},
      );
    });

    test('通常のコメントは parent_comment_id が null、確認後の再送は confirmed: true', () {
      final body = SupabaseCommentRepository.createBody(
        postId: 'p-1',
        body: 'こんにちは',
        confirmed: true,
      );
      expect(body['parent_comment_id'], isNull);
      expect(body['confirmed'], isTrue);
    });
  });
}
