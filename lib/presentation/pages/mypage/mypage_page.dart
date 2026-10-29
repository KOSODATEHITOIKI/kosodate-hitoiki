import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kosodate_hitoiki/presentation/widgets/app_asset.dart';

import '../../../core/constants/app_brand.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_icons.dart';
import '../../providers/my_page_providers.dart';
import '../../providers/auth_provider.dart';
import '../../providers/post_providers.dart';
import '../../providers/profile_providers.dart';
import '../../widgets/comfort_page.dart';
import '../../widgets/mock_post_list.dart';
import '../auth/auth_page.dart';
import '../profile/profile_edit_page.dart';
import '../settings/settings_page.dart';

/// S-07。ログイン済みなら、自分のプロフィールと、自分の投稿・保存した投稿を出す。
/// ゲストには、登録・ログインの案内を出す(要件定義書6.2.4)。
class MyPagePage extends ConsumerStatefulWidget {
  const MyPagePage({super.key});

  @override
  ConsumerState<MyPagePage> createState() => _MyPagePageState();
}

class _MyPagePageState extends ConsumerState<MyPagePage> {
  /// 保存した投稿を見ているか。左メニューからも切り替わるので、providerで持つ。
  bool get _savedPosts => ref.watch(myPageSavedPostsProvider);

  @override
  Widget build(BuildContext context) {
    final loggedIn = ref.watch(isLoggedInProvider);
    final sample = ref.watch(postsAreSampleProvider);
    return ComfortPage(
      title: 'マイページ',
      titleImage: AppBrand.titleMyPage,
      titleImageScale: 1.15,
      message: 'あなたのペースで\nつながれる、ひと息の場所です。',
      children: [
        Align(
          alignment: Alignment.centerRight,
          child: TextButton.icon(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const SettingsPage()),
            ),
            icon: const Icon(Icons.settings_outlined),
            label: const Text('設定'),
          ),
        ),
        _profileCard(loggedIn),
        if (loggedIn) ...[
          const SizedBox(height: 24),
          SegmentedButton<bool>(
            segments: const [
              ButtonSegment(value: false, label: Text('自分の投稿')),
              ButtonSegment(value: true, label: Text('保存した投稿')),
            ],
            selected: {_savedPosts},
            showSelectedIcon: false,
            onSelectionChanged: (selection) =>
                ref.read(myPageSavedPostsProvider.notifier).state =
                    selection.single,
            style: SegmentedButton.styleFrom(
              backgroundColor: AppColors.white,
              selectedBackgroundColor: AppColors.secondary,
              selectedForegroundColor: AppColors.textPrimary,
              foregroundColor: AppColors.textPrimary,
              minimumSize: const Size(48, 52),
              side: const BorderSide(color: AppColors.divider),
              textStyle: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: 24),
          if (_savedPosts) ...[
            const Text(
              'あとで読みたい投稿',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            const Text(
              '保存したことは相手に通知されません。',
              style: TextStyle(fontSize: 12.5, height: 1.7),
            ),
            const SizedBox(height: 16),
          ],
          MockPostList(
            posts: ref.watch(
              _savedPosts ? savedPostsProvider : myPostsProvider,
            ),
            emptyAsset: _savedPosts
                ? AppIllustrations.emptyBookmarks
                : AppIllustrations.emptyMyPosts,
            emptyTitle: _savedPosts
                ? (sample ? '保存したサンプル投稿はありません' : '保存した投稿はありません')
                : (sample ? '自分のサンプル投稿はありません' : '自分の投稿はまだありません'),
            onRetry: () => ref.invalidate(
              _savedPosts ? savedPostsProvider : myPostsProvider,
            ),
            pagedProvider: _savedPosts ? savedPostsProvider : myPostsProvider,
          ),
        ],
      ],
    );
  }

  /// ログイン済みなら自分のプロフィール、ゲストなら登録・ログインの案内。
  Widget _profileCard(bool loggedIn) {
    final profile = loggedIn ? ref.watch(myProfileProvider).valueOrNull : null;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 72,
                height: 72,
                // 自分の写真(四角)も、丸くする。
                clipBehavior: Clip.antiAlias,
                decoration: const BoxDecoration(
                  color: AppColors.surface,
                  shape: BoxShape.circle,
                ),
                child: AppAsset(
                  profile?.avatarAsset ?? AppAvatars.defaultSprout,
                  excludeFromSemantics: true,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      loggedIn ? (profile?.nickname ?? 'あなた') : 'あなたのプロフィール',
                      key: const ValueKey('mypage-name'),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      loggedIn
                          ? (profile != null && profile.bio.isNotEmpty
                                ? profile.bio
                                : '自己紹介は、プロフィールの編集で書けます。')
                          : 'マイページの利用には\nログインが必要です。',
                      style: const TextStyle(fontSize: 12.5, height: 1.7),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (loggedIn)
            OutlinedButton.icon(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const ProfileEditPage(),
                ),
              ),
              icon: const Icon(Icons.edit_outlined),
              label: const Text('プロフィールを編集'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.textPrimary,
                side: const BorderSide(color: AppColors.divider),
              ),
            )
          else
            FilledButton(
              onPressed: () => Navigator.of(
                context,
              ).push(MaterialPageRoute<void>(builder: (_) => const AuthPage())),
              child: const Text('登録・ログイン'),
            ),
        ],
      ),
    );
  }
}
