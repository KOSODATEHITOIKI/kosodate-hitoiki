import 'package:flutter/material.dart';
import '../../../core/widgets/centered_page_transitions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kosodate_hitoiki/presentation/widgets/app_asset.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/child_age_range.dart';
import '../../../domain/models/user_profile.dart';
import '../../providers/auth_provider.dart';
import '../../providers/profile_providers.dart';
import '../../widgets/comfort_page.dart';
import '../auth/auth_page.dart';
import '../report/report_page.dart';

/// S-08。プロフィール取得はモック。認証状態は実際のProviderで分岐する。
class OtherProfilePage extends ConsumerWidget {
  const OtherProfilePage({super.key, required this.userId});
  final String userId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loggedIn = ref.watch(isLoggedInProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('プロフィール')),
      body: !loggedIn
          ? ComfortPage(
              title: 'ログインして、\nひと息',
              message: 'プロフィールを見るには、\n登録・ログインが必要です。',
              children: [
                FilledButton(
                  onPressed: () => _auth(context, AuthMode.register),
                  child: const Text('会員登録'),
                ),
                const SizedBox(height: 8),
                OutlinedButton(
                  onPressed: () => _auth(context, AuthMode.login),
                  child: const Text('ログイン'),
                ),
              ],
            )
          : ref
                .watch(otherProfileProvider(userId))
                .when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (_, _) => ComfortPage(
                    title: '読み込めませんでした',
                    message: '時間をおいて、もう一度お試しください。',
                    children: [
                      OutlinedButton(
                        onPressed: () =>
                            ref.invalidate(otherProfileProvider(userId)),
                        child: const Text('再読み込み'),
                      ),
                    ],
                  ),
                  data: (profile) => profile == null
                      ? const ComfortPage(
                          title: 'プロフィールが見つかりません',
                          message: '前の画面に戻ってお試しください。',
                          children: [],
                        )
                      : _profile(context, profile),
                ),
    );
  }

  Widget _profile(BuildContext context, UserProfile profile) => ComfortPage(
    title: '',
    message: '',
    children: [
      const Text('サンプルプロフィールです。', style: TextStyle(fontSize: 11)),
      const SizedBox(height: 12),
      Center(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final size = (constraints.maxWidth * 0.38).clamp(96.0, 144.0);
            return ClipOval(
              child: AppAsset(
                profile.avatarAsset,
                width: size,
                height: size,
                excludeFromSemantics: true,
              ),
            );
          },
        ),
      ),
      const SizedBox(height: 16),
      Text(
        profile.nickname,
        textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w700),
      ),
      const SizedBox(height: 12),
      Text(
        profile.bio.isEmpty ? '自己紹介はまだありません。' : profile.bio,
        textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 14, height: 1.7),
      ),
      const SizedBox(height: 24),
      Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '子どもの年齢帯',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 6),
            Text(
              ChildAgeRange.labelFor(profile.childAgeBand),
              style: const TextStyle(fontSize: 14),
            ),
          ],
        ),
      ),
      const SizedBox(height: 20),
      Wrap(
        alignment: WrapAlignment.center,
        spacing: 12,
        runSpacing: 12,
        children: [
          OutlinedButton.icon(
            onPressed: () => _notice(context, 'ブロック'),
            icon: const Icon(Icons.block, size: 20),
            label: const Text('ブロック'),
          ),
          OutlinedButton.icon(
            onPressed: () => Navigator.of(context).push<void>(
              MaterialPageRoute(
                builder: (_) => ReportPage(
                  targetId: profile.id,
                  targetType: ReportTargetType.user,
                ),
              ),
            ),
            icon: const Icon(Icons.flag_outlined, size: 20),
            label: const Text('通報'),
          ),
        ],
      ),
    ],
  );

  void _auth(BuildContext context, AuthMode mode) =>
      pushFullWidth<void>(context, builder: (_) => AuthPage(initialMode: mode));

  void _notice(BuildContext context, String action) => showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text('$actionは準備中です'),
      content: Text(
        action == 'ブロック'
            ? 'まだブロックされません。ブロック機能の接続を進めています。'
            : '通報は送信されません。通報フォームの実装を進めています。',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('閉じる'),
        ),
      ],
    ),
  );
}
