import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kosodate_hitoiki/presentation/widgets/app_asset.dart';
import '../../../core/constants/app_brand.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_icons.dart';
import '../../../domain/models/post.dart';
import '../../providers/auth_provider.dart';
import '../../providers/post_providers.dart';
import '../../widgets/comfort_page.dart';
import '../../widgets/main_navigation_shell.dart';
import '../../../domain/models/topic.dart';
import '../auth/auth_page.dart';
import 'compose_review_page.dart';

/// S-04。投稿は、確認画面から投稿作成API(送信前チェックもサーバー側)を呼ぶ。
class ComposePage extends ConsumerStatefulWidget {
  const ComposePage({super.key, this.initialPost});
  final Post? initialPost;
  @override
  ConsumerState<ComposePage> createState() => _ComposePageState();
}

enum _ResponseMode { listening, advice }

class _ComposePageState extends ConsumerState<ComposePage> {
  final _body = TextEditingController();
  String _postType = 'ぐち';
  _ResponseMode _mode = _ResponseMode.listening;
  Topic? _topic;
  bool _guideSeen = false;

  @override
  void initState() {
    super.initState();
    final post = widget.initialPost;
    if (post != null) {
      _body.text = post.body;
      _postType = post.type.label;
      _mode = post.responseMode == ResponseMode.advice
          ? _ResponseMode.advice
          : _ResponseMode.listening;
    }
  }

  // ログアウト・利用者切り替え時に下書きを破棄する。
  void _resetDraft() {
    _body.clear();
    _postType = 'ぐち';
    _mode = _ResponseMode.listening;
    _topic = null;
    _guideSeen = false;
  }

  @override
  void dispose() {
    _body.dispose();
    super.dispose();
  }

  Future<void> _showPostingNotice() async {
    FocusManager.instance.primaryFocus?.unfocus();
    if (_body.text.trim().isEmpty || _body.text.characters.length > 1000) {
      return;
    }
    // 書く画面は未ログインでも開けて入力できる。投稿を押した時点で、登録・ログインを
    // 案内する。入力した文章は残る(要件定義書6.2.4)。
    if (!ref.read(isLoggedInProvider)) {
      await Navigator.of(
        context,
      ).push<void>(MaterialPageRoute(builder: (_) => const AuthPage()));
      return;
    }
    if (!_guideSeen && widget.initialPost == null) {
      final accepted = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          scrollable: true,
          title: const Text('はじめて投稿する前に'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppAsset(
                AppDecorations.sunSmiling,
                width: 96,
                height: 96,
                excludeFromSemantics: true,
              ),
              const SizedBox(height: 12),
              const Text(
                'ここに書いたことは、登録していない人も読めます。\n\n名前・学校や園・勤務先・住んでいる地域は書かず、「上の子」「夫」のように続柄で伝えましょう。\n\n入力した文章は残っています。',
                style: TextStyle(fontSize: 14, height: 1.7),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('あとにする'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('確認して書く'),
            ),
          ],
        ),
      );
      FocusManager.instance.primaryFocus?.unfocus();
      if (mounted && accepted == true) setState(() => _guideSeen = true);
      return;
    }
    if (!mounted) return;
    final posted = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => ComposeReviewPage(
          body: _body.text,
          postType: PostType.values.firstWhere(
            (type) => type.label == _postType,
          ),
          responseMode: _mode == _ResponseMode.listening
              ? ResponseMode.listening
              : ResponseMode.advice,
          topic: _topic,
          editing: widget.initialPost != null,
          postId: widget.initialPost?.id,
        ),
      ),
    );
    FocusManager.instance.primaryFocus?.unfocus();
    if (posted != true || !mounted) return;
    if (widget.initialPost != null) {
      // 編集できたら、新しい本文を持って、詳細へ戻る。
      Navigator.of(context).pop(_body.text.trim());
      return;
    }
    // 投稿できたら、下書きを空にして、ホームへ戻る。
    setState(_resetDraft);
    ref.read(bottomNavIndexProvider.notifier).state = 0;
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<String?>(currentUserIdProvider, (previous, next) {
      // ゲストがログインして書き続けるときは、入力を残す(登録・ログインの案内の
      // 約束)。ログアウトや、別の利用者への切り替えのときだけ破棄する。
      if (previous != null && previous != next) setState(_resetDraft);
    });
    return _build(context);
  }

  Widget _build(BuildContext context) => ComfortPage(
    title: '書く',
    titleImage: AppBrand.titleCompose,
    message: 'ここなら、気持ちを書けるよ。\nどんな気持ちも、受けとめます。',
    messageFontSize: 13,
    children: [
      if (widget.initialPost != null) ...[
        const Text(
          '編集できるのは、本文だけです。種類と反応の希望は、変えられません。',
          key: ValueKey('compose-edit-note'),
          style: TextStyle(fontSize: 12, height: 1.7),
        ),
        const SizedBox(height: 12),
      ],
      _section(
        '投稿の種類',
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            for (final type in ['ぐち', '相談', 'コツ・体験談'])
              ChoiceChip(
                label: Text(type, maxLines: 1, softWrap: false),
                labelStyle: const TextStyle(fontSize: 12),
                labelPadding: const EdgeInsets.symmetric(horizontal: 6),
                selected: _postType == type,
                onSelected: widget.initialPost != null
                    ? null
                    : (_) => setState(() => _postType = type),
                showCheckmark: false,
                selectedColor: AppColors.secondary,
                backgroundColor: AppColors.background,
                shape: const StadiumBorder(),
                side: const BorderSide(color: AppColors.divider),
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
              ),
          ],
        ),
      ),
      const SizedBox(height: 16),
      _section(
        '本文',
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _body,
              minLines: 4,
              maxLines: 10,
              maxLength: 1000,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(
                hintText: 'いまの気持ちを書いてみませんか。',
                labelText: '気持ちの本文',
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline, size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '名前・学校や園・住んでいる場所は書かないでね。健康に関することは、必要な範囲で。',
                      style: TextStyle(fontSize: 12.5, height: 1.6),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 16),
      _section(
        '反応の希望',
        Column(
          children: [
            _modeOption(_ResponseMode.listening, 'ただ聞いてほしい', '共感ボタン・定型文のみ'),
            const SizedBox(height: 12),
            _modeOption(_ResponseMode.advice, '話を聞きたい', '自由コメントを受け付ける'),
          ],
        ),
      ),
      // 話題は、投稿を作るときだけ付けられる(あとから変えられない)。編集では出さない。
      if (widget.initialPost == null) ...[
        const SizedBox(height: 16),
        _section(
          '話題（任意・1つ）',
          ref
              .watch(topicsProvider)
              .when(
                loading: () => const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Center(child: CircularProgressIndicator()),
                ),
                // 話題は任意。読み込めなくても、話題なしで投稿できる。
                error: (_, _) => Row(
                  children: [
                    const Expanded(
                      child: Text(
                        '話題を読み込めませんでした。話題なしでも投稿できます。',
                        key: ValueKey('compose-topics-failed'),
                        style: TextStyle(fontSize: 12, height: 1.6),
                      ),
                    ),
                    TextButton(
                      key: const ValueKey('compose-topics-retry'),
                      onPressed: () => ref.invalidate(topicsProvider),
                      child: const Text('再読み込み'),
                    ),
                  ],
                ),
                data: (topics) => Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (final topic in topics)
                      ChoiceChip(
                        key: ValueKey('compose-topic-${topic.id}'),
                        label: Text(topic.label, maxLines: 1, softWrap: false),
                        labelStyle: const TextStyle(fontSize: 12),
                        labelPadding: const EdgeInsets.symmetric(horizontal: 6),
                        selected: _topic == topic,
                        onSelected: (selected) =>
                            setState(() => _topic = selected ? topic : null),
                        showCheckmark: false,
                        selectedColor: AppColors.secondary,
                        backgroundColor: AppColors.background,
                        shape: const StadiumBorder(),
                        side: const BorderSide(color: AppColors.divider),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 4,
                        ),
                      ),
                  ],
                ),
              ),
        ),
      ],
      const SizedBox(height: 24),
      FilledButton.icon(
        key: const ValueKey('compose-submit'),
        onPressed: _body.text.trim().isEmpty ? null : _showPostingNotice,
        icon: AppAsset(
          AppIcons.navCompose,
          width: 24,
          height: 24,
          excludeFromSemantics: true,
          colorFilter: ColorFilter.mode(
            _body.text.trim().isEmpty
                ? AppColors.textSecondary
                : AppColors.white,
            BlendMode.srcIn,
          ),
        ),
        label: Text(widget.initialPost == null ? '投稿する' : '変更を確認する'),
      ),
      const SizedBox(height: 12),
      const Text(
        '入力内容はこの画面を開いている間だけ保持されます。',
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 11, height: 1.6),
      ),
    ],
  );

  Widget _modeOption(_ResponseMode value, String title, String description) {
    final selected = _mode == value;
    return Semantics(
      key: ValueKey('response-${value.name}'),
      selected: selected,
      button: true,
      child: Material(
        color: selected
            ? AppColors.accentPink.withValues(alpha: 0.35)
            : AppColors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: selected ? AppColors.primary : AppColors.divider,
            width: selected ? 2 : 1,
          ),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: widget.initialPost != null
              ? null
              : () => setState(() => _mode = value),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Icon(
                  selected
                      ? Icons.radio_button_checked
                      : Icons.radio_button_off,
                  color: selected ? AppColors.primary : AppColors.textPrimary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          title,
                          maxLines: 1,
                          style: const TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        description,
                        style: const TextStyle(fontSize: 12, height: 1.5),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _section(String title, Widget child) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: AppColors.white,
      borderRadius: BorderRadius.circular(24),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 12),
        child,
      ],
    ),
  );
}
