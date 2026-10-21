import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../../data/api/api_exception.dart';
import '../../../domain/repositories/mute_repository.dart';
import '../../providers/auth_provider.dart';
import '../../providers/mute_providers.dart';
import '../../providers/post_providers.dart';
import '../../widgets/comfort_page.dart';
import '../auth/auth_page.dart';
import '../compose/post_messages.dart';

/// 言葉のミュート管理。ミュートした言葉を含む投稿は、一覧・検索に出なくなる
/// (投稿の本文にだけ適用し、コメントには適用しない)。相手には知らせない。
/// 話題のミュートは、話題のマスタが未決定のため、まだ出さない。
class MuteManagementPage extends ConsumerStatefulWidget {
  const MuteManagementPage({super.key});

  @override
  ConsumerState<MuteManagementPage> createState() => _MuteManagementPageState();
}

class _MuteManagementPageState extends ConsumerState<MuteManagementPage> {
  final _word = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _word.dispose();
    super.dispose();
  }

  /// 一覧・検索を取り直す(ミュートの変更を、表示に反映する)。応答を待つ間に画面が
  /// 閉じられることがあるので、画面の`ref`ではなく、先に取っておいた[container]で行う。
  static void _refresh(ProviderContainer container) {
    container
      ..invalidate(mutedWordsProvider)
      ..invalidate(feedPostsProvider)
      ..invalidate(searchResultsProvider);
  }

  String _failure(Object error) {
    if (error is ApiException) {
      if (error.code == 'LIMIT_EXCEEDED') {
        return '登録できる言葉は、$maxMutedWords件までです。使わない言葉を外してください。';
      }
      if (error.code == 'DUPLICATE') return 'その言葉は、すでに登録されています。';
    }
    return postFailureMessage(error);
  }

  Future<void> _add() async {
    final word = _word.text.trim();
    if (word.isEmpty || word.characters.length > maxMutedWordLength || _busy) {
      return;
    }
    FocusScope.of(context).unfocus();
    final container = ProviderScope.containerOf(context);
    final repository = ref.read(muteRepositoryProvider);
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await repository.addWord(word);
      _refresh(container);
      if (mounted) _word.clear();
    } catch (error) {
      if (mounted) setState(() => _error = _failure(error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _remove(String word) async {
    if (_busy) return;
    final container = ProviderScope.containerOf(context);
    final repository = ref.read(muteRepositoryProvider);
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await repository.removeWord(word);
      _refresh(container);
    } catch (error) {
      if (mounted) setState(() => _error = _failure(error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final loggedIn = ref.watch(isLoggedInProvider);
    // 利用者が切り替わったら、この画面を閉じる(前の利用者の言葉を、別の人に見せない)。
    ref.listen<String?>(currentUserIdProvider, (previous, next) {
      if (previous == next) return;
      final navigator = Navigator.of(context);
      final myRoute = ModalRoute.of(context);
      if (myRoute != null) {
        navigator.popUntil((route) => route == myRoute);
      }
      if (navigator.canPop()) navigator.pop();
    });
    return Scaffold(
      appBar: AppBar(title: const Text('ミュート管理')),
      body: !loggedIn
          ? ComfortPage(
              title: 'ログインして、\nひと息',
              message: 'ミュート管理には、\n登録・ログインが必要です。',
              children: [
                FilledButton(
                  onPressed: () => _auth(AuthMode.register),
                  child: const Text('会員登録'),
                ),
                const SizedBox(height: 8),
                OutlinedButton(
                  onPressed: () => _auth(AuthMode.login),
                  child: const Text('ログイン'),
                ),
              ],
            )
          : _content(),
    );
  }

  Widget _content() {
    final words = ref.watch(mutedWordsProvider);
    final sample = ref.watch(muteRepositoryProvider).isSample;
    final count = words.valueOrNull?.length;
    return ComfortPage(
      title: '言葉のミュート',
      message: '見たくない言葉を、\n自分の画面からだけ隠せます。',
      children: [
        const Text(
          'ミュートした言葉を含む投稿が、一覧・検索に出なくなります。コメントには適用されません。相手には知らせません。',
          style: TextStyle(fontSize: 13, height: 1.7),
        ),
        if (sample) ...[
          const SizedBox(height: 8),
          const Text(
            'サンプルです。実際には、投稿に反映されません。',
            style: TextStyle(fontSize: 12, height: 1.7),
          ),
        ],
        const SizedBox(height: 16),
        TextField(
          key: const ValueKey('mute-word-field'),
          controller: _word,
          enabled: !_busy,
          maxLength: maxMutedWordLength,
          textInputAction: TextInputAction.done,
          onChanged: (_) => setState(() => _error = null),
          onSubmitted: (_) => _add(),
          decoration: const InputDecoration(
            labelText: '隠したい言葉',
            hintText: '例: 〇〇',
            counterText: '',
          ),
        ),
        const SizedBox(height: 8),
        FilledButton(
          key: const ValueKey('mute-add'),
          onPressed: _busy || _word.text.trim().isEmpty ? null : _add,
          child: Text(_busy ? '送信しています…' : '追加する'),
        ),
        if (_error != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              _error!,
              key: const ValueKey('mute-error'),
              style: TextStyle(
                color: Theme.of(context).colorScheme.error,
                fontSize: 13,
                height: 1.6,
              ),
            ),
          ),
        const SizedBox(height: 24),
        Text(
          count == null ? 'ミュートしている言葉' : 'ミュートしている言葉($count/$maxMutedWords)',
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        words.when(
          loading: () => const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (_, _) => Column(
            children: [
              const Text('読み込めませんでした。', style: TextStyle(fontSize: 14)),
              TextButton(
                key: const ValueKey('mute-retry'),
                onPressed: () => ref.invalidate(mutedWordsProvider),
                child: const Text('再読み込み'),
              ),
            ],
          ),
          data: (items) => items.isEmpty
              ? const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Text(
                    'ミュートしている言葉は、まだありません。',
                    key: ValueKey('mute-empty'),
                    style: TextStyle(fontSize: 14),
                  ),
                )
              : Column(
                  children: [
                    for (final word in items)
                      Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        decoration: BoxDecoration(
                          color: AppColors.white,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: ListTile(
                          title: Text(
                            word,
                            style: const TextStyle(fontSize: 14),
                          ),
                          trailing: IconButton(
                            key: ValueKey('mute-remove-$word'),
                            tooltip: '「$word」を外す',
                            onPressed: _busy ? null : () => _remove(word),
                            icon: const Icon(Icons.close),
                          ),
                        ),
                      ),
                  ],
                ),
        ),
      ],
    );
  }

  void _auth(AuthMode mode) => Navigator.of(
    context,
  ).push<void>(MaterialPageRoute(builder: (_) => AuthPage(initialMode: mode)));
}
