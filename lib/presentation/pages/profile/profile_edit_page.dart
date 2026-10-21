import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kosodate_hitoiki/presentation/widgets/app_asset.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_icons.dart';
import '../../../data/api/api_exception.dart';
import '../../../domain/models/picked_avatar.dart';
import '../../providers/auth_provider.dart';
import '../../providers/post_providers.dart';
import '../../providers/profile_providers.dart';
import '../../widgets/comfort_page.dart';
import '../compose/moderated_action.dart';
import '../compose/post_messages.dart';

/// S-09。プロフィールの取得・保存に接続している。
/// - ニックネーム: `profile-nickname`(30日に1回。送信前チェックあり)
/// - 自己紹介・アイコン: `profile-update`(自己紹介は送信前チェックあり)
/// 子どもの年齢帯は、選択肢が未決定のため、サンプル(モック)のときだけ出す。
/// アカウント画像は、用意したイラストを選ぶか、自分の写真を選ぶ(`profile-avatar`。保存を押したときに送る)。
class ProfileEditPage extends ConsumerStatefulWidget {
  const ProfileEditPage({super.key});
  @override
  ConsumerState<ProfileEditPage> createState() => _ProfileEditPageState();
}

class _ProfileEditPageState extends ConsumerState<ProfileEditPage> {
  final _form = GlobalKey<FormState>();
  final _nickname = TextEditingController();
  final _bio = TextEditingController();
  String _avatar = AppAvatars.defaultSprout;
  String? _nameError;

  /// 選んだ自分の写真。イラストとは、どちらか一方。保存を押したときに送る。
  PickedAvatar? _picked;

  /// [_picked]を送り終えたか(保存が途中で失敗しても、二重に送らない)。
  bool _pickedUploaded = false;
  String _ageBand = '';

  /// 読み込んだときの値。変わった項目だけを送るために持つ。
  String _origNickname = '';
  String _origBio = '';
  String _origAvatar = AppAvatars.defaultSprout;
  bool _filled = false;

  bool _busy = false;
  String? _error;

  // 年齢帯の区分は未確定。画面確認用のサンプルとして扱う(サンプルのときだけ出す)。
  static const _sampleAgeBands = ['', '乳児', '未就学児', '小学生', '中学生以上'];

  @override
  void initState() {
    super.initState();
    // 読み込めたら、いまの値を入れる(入力を始めたあとの再読み込みでは、上書きしない)。
    ref.listenManual(myProfileProvider, (_, next) {
      final profile = next.valueOrNull;
      if (profile != null) {
        _fill(profile.nickname, profile.bio, profile.avatarAsset);
      }
    }, fireImmediately: true);
  }

  void _fill(String nickname, String bio, String avatar) {
    if (_filled) return;
    _filled = true;
    setState(() {
      _nickname.text = nickname;
      _bio.text = bio;
      _avatar = avatar;
      _origNickname = nickname;
      _origBio = bio;
      _origAvatar = avatar;
    });
  }

  @override
  void dispose() {
    _nickname.dispose();
    _bio.dispose();
    super.dispose();
  }

  /// 自分のプロフィールと、投稿・コメントに出る名前・アイコンを、取り直す。
  ///
  /// 保存の応答を待つ間に、画面が閉じられる(戻る操作・利用者の切り替え)ことがある。
  /// 閉じたあとの`ref`は使えないので、保存を始める前に取っておいた[container]で
  /// 行う(画面が閉じても、保存できた変更は、表示に反映する)。
  static void _refreshCaches(ProviderContainer container) {
    container
      ..invalidate(myProfileProvider)
      ..invalidate(feedPostsProvider)
      ..invalidate(searchResultsProvider)
      ..invalidate(myPostsProvider)
      ..invalidate(savedPostsProvider);
  }

  Future<void> _save() async {
    final length = _nickname.text.trim().characters.length;
    setState(
      () => _nameError = length < 2 || length > 12
          ? 'ニックネームは2〜12文字で入力してください。'
          : null,
    );
    if (_nameError != null) return;
    FocusScope.of(context).unfocus();
    if (ref.read(profileIsSampleProvider)) {
      showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('プロフィールの保存は準備中です'),
          content: const Text('入力内容は保存されません。プロフィールの編集にはログインが必要です。'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('編集に戻る'),
            ),
          ],
        ),
      );
      return;
    }
    final nickname = _nickname.text.trim();
    final bio = _bio.text.trim();
    final nicknameChanged = nickname != _origNickname;
    final bioChanged = bio != _origBio.trim();
    final iconChanged = _picked == null && _avatar != _origAvatar;
    final photoChanged = _picked != null && !_pickedUploaded;
    if (!nicknameChanged && !bioChanged && !iconChanged && !photoChanged) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('変更はありません')));
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    final repository = ref.read(profileRepositoryProvider);
    final container = ProviderScope.containerOf(context);
    try {
      if (nicknameChanged) {
        final error = await runModerated(
          context: context,
          action: (confirmed) => repository.changeNickname(
            nickname: nickname,
            confirmed: confirmed,
          ),
        );
        if (error != null) {
          if (mounted) setState(() => _error = error.isEmpty ? null : error);
          return;
        }
        // ここまでは保存できた。次の項目が失敗しても、ニックネームは二重に送らない。
        // また、ここで終わっても表示が古いまま残らないよう、すぐに取り直す。
        _origNickname = nickname;
        _refreshCaches(container);
      }
      if (photoChanged) {
        try {
          await repository.uploadAvatar(_picked!);
          _pickedUploaded = true;
          // 以後にイラストを選んだら、(元と同じ絵でも)変更として送る。写真が外れるため。
          _origAvatar = '';
          _refreshCaches(container);
        } catch (error) {
          if (mounted) setState(() => _error = _photoFailure(error));
          return;
        }
      }
      if (bioChanged || iconChanged) {
        if (!mounted) return;
        final error = await runModerated(
          context: context,
          action: (confirmed) => repository.updateProfile(
            bio: bioChanged ? bio : null,
            iconKey: iconChanged ? AppAvatars.keyFor(_avatar) : null,
            confirmed: confirmed,
          ),
        );
        if (error != null) {
          if (mounted) setState(() => _error = error.isEmpty ? null : error);
          return;
        }
      }
      _refreshCaches(container);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('プロフィールを保存しました')));
      Navigator.of(context).pop();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  /// 写真を選ぶ。選べたら、保存を押すまで、画面の表示だけを変える。
  Future<void> _pickPhoto() async {
    try {
      final picked = await ref.read(avatarPickerProvider).pick();
      if (picked == null || !mounted) return;
      setState(() {
        _picked = picked;
        _pickedUploaded = false;
        // 写真を選んだら、イラストの選択は取り消す(どちらか一方)。
        _avatar = _origAvatar;
        _error = null;
      });
    } on AvatarPickException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } catch (_) {
      if (mounted) setState(() => _error = '画像を選べませんでした。もう一度お試しください。');
    }
  }

  /// 写真の送信が失敗したときの文言。
  String _photoFailure(Object error) {
    if (error is ApiException) {
      if (error.isRejected) {
        return '選んだ画像は使えませんでした。別の画像を選んでください。';
      }
      if (error.code == 'VALIDATION_FAILED') {
        return '画像を保存できませんでした。JPEG・PNG・WebPの、2MB以下の画像を選んでください。';
      }
    }
    return postFailureMessage(error);
  }

  @override
  Widget build(BuildContext context) {
    final sample = ref.watch(profileIsSampleProvider);
    // 利用者が切り替わったら、この画面(と、上に乗った確認ダイアログ)を閉じる。
    // 閉じないと、前の利用者の入力を、切り替え後のアカウントに保存してしまう。
    ref.listen<String?>(currentUserIdProvider, (previous, next) {
      if (previous == next) return;
      final navigator = Navigator.of(context);
      final myRoute = ModalRoute.of(context);
      if (myRoute != null) {
        navigator.popUntil((route) => route == myRoute);
      }
      if (navigator.canPop()) navigator.pop();
    });
    // いまのプロフィールを読み込み終えるまでは、編集も保存もできない(入力が、読み込みで
    // 上書きされて消えるのを防ぐ)。読み込めなかったときは、再読み込みを案内する。
    final profile = ref.watch(myProfileProvider);
    final loading = profile.isLoading && !profile.hasValue;
    final failed = profile.hasError && !profile.hasValue;
    final editable = !_busy && !loading && !failed;
    return Scaffold(
      appBar: AppBar(title: const Text('プロフィール編集')),
      body: Form(
        key: _form,
        child: ComfortPage(
          title: 'プロフィール',
          message: 'あなたのことを、ひとこと。',
          children: [
            if (loading)
              const Padding(
                padding: EdgeInsets.only(bottom: 16),
                child: Text(
                  'いまのプロフィールを読み込んでいます…',
                  key: ValueKey('profile-loading'),
                  style: TextStyle(fontSize: 13, height: 1.7),
                ),
              ),
            if (failed)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'プロフィールを読み込めませんでした。読み込めるまで、編集できません。',
                      key: ValueKey('profile-load-failed'),
                      style: TextStyle(fontSize: 13, height: 1.7),
                    ),
                    TextButton(
                      key: const ValueKey('profile-retry'),
                      onPressed: () => ref.invalidate(myProfileProvider),
                      child: const Text('再読み込み'),
                    ),
                  ],
                ),
              ),
            _section(
              'アイコンを選ぶ',
              Column(
                children: [
                  if (_picked != null)
                    ClipOval(
                      child: Image.memory(
                        _picked!.bytes,
                        key: const ValueKey('profile-photo-preview'),
                        width: 96,
                        height: 96,
                        fit: BoxFit.cover,
                        semanticLabel: '選んだ写真',
                      ),
                    )
                  else
                    AppAsset(
                      _avatar,
                      width: 96,
                      height: 96,
                      semanticsLabel: '選択中のアイコン',
                    ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 16,
                    runSpacing: 12,
                    children: [
                      for (final item in const [
                        (AppAvatars.defaultSprout, '芽'),
                        (AppAvatars.defaultYellowFlower, '花'),
                        (AppAvatars.defaultTulip, 'チューリップ'),
                        (AppAvatars.defaultLittleBird, '鳥'),
                      ])
                        Semantics(
                          button: true,
                          selected: _picked == null && _avatar == item.$1,
                          label: '${item.$2}のアイコン',
                          child: Tooltip(
                            message: '${item.$2}のアイコン',
                            child: InkWell(
                              onTap: !editable
                                  ? null
                                  : () => setState(() {
                                      _avatar = item.$1;
                                      _picked = null;
                                    }),
                              borderRadius: BorderRadius.circular(40),
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: AppColors.surface,
                                  border: Border.all(
                                    color: _picked == null && _avatar == item.$1
                                        ? AppColors.primary
                                        : AppColors.divider,
                                    width: 2,
                                  ),
                                ),
                                child: AppAsset(
                                  item.$1,
                                  width: 56,
                                  height: 56,
                                  excludeFromSemantics: true,
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  OutlinedButton.icon(
                    key: const ValueKey('profile-pick-photo'),
                    onPressed: editable ? _pickPhoto : null,
                    icon: const Icon(Icons.photo_library_outlined),
                    label: const Text('自分の写真から選ぶ'),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '顔写真やお子さんの写真は、避けてください。選んだ画像は、投稿やコメントの横に、ニックネームと一緒に公開されます。',
                    key: ValueKey('profile-photo-notice'),
                    style: TextStyle(fontSize: 12, height: 1.7),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _section(
              'ニックネーム（必須）',
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextFormField(
                    key: const ValueKey('profile-nickname'),
                    controller: _nickname,
                    enabled: editable,
                    forceErrorText: _nameError,
                    onChanged: (_) {
                      if (_nameError != null) setState(() => _nameError = null);
                    },
                    maxLength: 12,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                      labelText: 'ニックネーム',
                      hintText: 'あなたの呼び名',
                    ),
                    validator: (value) =>
                        (value ?? '').trim().characters.length < 2
                        ? 'ニックネームは2〜12文字で入力してください。'
                        : null,
                  ),
                  const Text(
                    '2〜12文字・変更は30日に1回です。\n本名やお子さんの名前は使わないでください。',
                    style: TextStyle(fontSize: 12, height: 1.7),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _section(
              '自己紹介（任意）',
              TextFormField(
                key: const ValueKey('profile-bio'),
                controller: _bio,
                enabled: editable,
                maxLength: 100,
                minLines: 3,
                maxLines: 6,
                decoration: const InputDecoration(
                  labelText: '自己紹介',
                  hintText: 'あなたのことを、ひとこと',
                  alignLabelWithHint: true,
                ),
              ),
            ),
            if (sample) ...[
              const SizedBox(height: 16),
              _section(
                '子どもの年齢帯（任意）',
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    InputDecorator(
                      decoration: const InputDecoration(labelText: '年齢帯'),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          key: const ValueKey('profile-age-band'),
                          value: _ageBand,
                          isExpanded: true,
                          itemHeight: null,
                          style: Theme.of(
                            context,
                          ).textTheme.bodyMedium?.copyWith(fontSize: 14),
                          items: [
                            for (final age in _sampleAgeBands)
                              DropdownMenuItem(
                                value: age,
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 8,
                                  ),
                                  child: Text(age.isEmpty ? '未選択' : age),
                                ),
                              ),
                          ],
                          onChanged: (value) =>
                              setState(() => _ageBand = value ?? ''),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '選ばなくても構いません。選択肢は画面確認用のサンプルです。',
                      style: TextStyle(fontSize: 12, height: 1.7),
                    ),
                  ],
                ),
              ),
            ],
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Text(
                  _error!,
                  key: const ValueKey('profile-error'),
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.error,
                    fontSize: 13,
                    height: 1.6,
                  ),
                ),
              ),
            const SizedBox(height: 24),
            FilledButton(
              key: const ValueKey('profile-save'),
              onPressed: editable ? _save : null,
              child: Text(_busy ? '保存しています…' : '保存する'),
            ),
            if (sample) ...[
              const SizedBox(height: 12),
              const Text(
                '保存機能は準備中です。\nこの画面を閉じると入力内容は消えます。',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 11, height: 1.7),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _section(String title, Widget child) => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: AppColors.white,
      borderRadius: BorderRadius.circular(24),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 16),
        child,
      ],
    ),
  );
}
