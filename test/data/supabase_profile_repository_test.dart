import 'package:flutter_test/flutter_test.dart';
import 'package:kosodate_hitoiki/core/constants/app_icons.dart';
import 'package:kosodate_hitoiki/data/repositories/supabase_post_repository.dart';
import 'package:kosodate_hitoiki/data/repositories/supabase_profile_repository.dart';

void main() {
  group('profileFromRow', () {
    test('自分のプロフィール(自己紹介・年齢帯つき)を読む', () {
      final profile = SupabaseProfileRepository.profileFromRow({
        'id': 'me',
        'nickname': 'こもれび',
        'bio': '子育ての気持ちを、少しずつ。',
        'child_age_range': '乳児',
        'icon_key': 'tulip',
      });
      expect(profile.id, 'me');
      expect(profile.nickname, 'こもれび');
      expect(profile.bio, '子育ての気持ちを、少しずつ。');
      expect(profile.childAgeBand, '乳児');
      expect(profile.avatarAsset, AppAvatars.defaultTulip);
    });

    test('ほかの人(ニックネーム・アイコンだけ)は、自己紹介が空、アイコンなしは既定', () {
      final profile = SupabaseProfileRepository.profileFromRow({
        'id': 'other',
        'nickname': 'はな',
        'icon_key': null,
      });
      expect(profile.bio, isEmpty);
      expect(profile.childAgeBand, isNull);
      expect(profile.avatarAsset, AppAvatars.defaultSprout);
    });
  });

  group('myPostFromRow', () {
    Map<String, dynamic> row({bool underReview = false}) => {
      'id': 'p-1',
      'post_type': 'guchi',
      'topic_id': null,
      'body': '今日はつかれた。',
      'reaction_mode': 'quiet_support',
      'comment_acceptance': 'open',
      'created_at': '2026-10-21T01:02:03Z',
      'edited_at': null,
      'under_review': underReview,
      'comment_count': 2,
    };

    test('投稿者は自分。ニックネームとアイコンは別に渡した値を使う', () {
      final post = SupabasePostRepository.myPostFromRow(
        row(),
        myUserId: 'me',
        nickname: 'こもれび',
        iconKey: 'sun',
      );
      expect(post.isMine, isTrue);
      expect(post.authorId, 'me');
      expect(post.authorName, 'こもれび');
      expect(post.authorAvatarAsset, AppAvatars.defaultSun);
      expect(post.commentCount, 2);
      expect(post.underReview, isFalse);
    });

    test('under_review が true の投稿は「確認中」になる', () {
      final post = SupabasePostRepository.myPostFromRow(
        row(underReview: true),
        myUserId: 'me',
        nickname: 'こもれび',
      );
      expect(post.underReview, isTrue);
    });
  });
}
