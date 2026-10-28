import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/legal_links.dart';
import '../../widgets/external_link.dart';

/// 利用規約・プライバシーポリシーへの同意と、18歳以上であることの確認(自己申告)。
///
/// 規約・ポリシーは、読まずに、チェックできない。項目を押すと、公開ページが、外部の
/// ブラウザで開き、アプリに戻ってくると、チェックがつく(ページを開いて戻ったことを、
/// 読んだものとする。実際に読んだかまでは、確かめられない)。チェックは、押して、外せる。
/// 3つすべてにチェックがつくと登録できる(呼び出し側で判定する)。
class LegalConsent extends ConsumerStatefulWidget {
  const LegalConsent({
    super.key,
    required this.termsAgreed,
    required this.privacyAgreed,
    required this.ageConfirmed,
    required this.onTermsChanged,
    required this.onPrivacyChanged,
    required this.onAgeChanged,
  });

  final bool termsAgreed;
  final bool privacyAgreed;
  final bool ageConfirmed;
  final ValueChanged<bool> onTermsChanged;
  final ValueChanged<bool> onPrivacyChanged;
  final ValueChanged<bool> onAgeChanged;

  @override
  ConsumerState<LegalConsent> createState() => _LegalConsentState();
}

enum _Doc { terms, privacy }

class _LegalConsentState extends ConsumerState<LegalConsent>
    with WidgetsBindingObserver {
  /// 公開ページを開いて、戻るのを待っている文書。
  _Doc? _awaiting;

  /// 開いたあと、アプリがいったん、見えなくなった(ブラウザへ移った)か。戻る前の、一時的な
  /// 復帰では、チェックをつけない。
  bool _leftApp = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final doc = _awaiting;
    if (doc == null) return;
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden) {
      _leftApp = true;
    } else if (state == AppLifecycleState.resumed && _leftApp) {
      // ページを開いて、アプリに戻ってきた。
      _awaiting = null;
      _leftApp = false;
      switch (doc) {
        case _Doc.terms:
          widget.onTermsChanged(true);
        case _Doc.privacy:
          widget.onPrivacyChanged(true);
      }
    }
  }

  /// 公開ページを開く。開けたら、戻ってくるのを待つ(開けなければ、案内が出て、チェックはつかない)。
  Future<void> _open(_Doc doc) async {
    final url = doc == _Doc.terms ? LegalLinks.terms : LegalLinks.privacy;
    final title = doc == _Doc.terms ? '利用規約' : 'プライバシーポリシー';
    _awaiting = null;
    _leftApp = false;
    final opened = await openExternalLink(context, ref, url, title: title);
    if (opened && mounted) {
      _awaiting = doc;
      _leftApp = false;
    }
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      _DocRow(
        fieldKey: const ValueKey('consent-terms'),
        label: '利用規約に同意する',
        agreed: widget.termsAgreed,
        // チェック済みなら、外せる。未チェックなら、ページを開く。
        onTap: () => widget.termsAgreed
            ? widget.onTermsChanged(false)
            : _open(_Doc.terms),
      ),
      _DocRow(
        fieldKey: const ValueKey('consent-privacy'),
        label: 'プライバシーポリシーに同意する',
        agreed: widget.privacyAgreed,
        onTap: () => widget.privacyAgreed
            ? widget.onPrivacyChanged(false)
            : _open(_Doc.privacy),
      ),
      // 自己申告。読む文書はないので、そのままチェックできる。
      CheckboxListTile(
        key: const ValueKey('consent-age'),
        contentPadding: EdgeInsets.zero,
        controlAffinity: ListTileControlAffinity.leading,
        value: widget.ageConfirmed,
        onChanged: (value) => widget.onAgeChanged(value ?? false),
        title: const Text(
          '18歳以上です',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
        ),
      ),
    ],
  );
}

/// 文書への同意の行。押すと、(未チェックなら)公開ページが開く。
class _DocRow extends StatelessWidget {
  const _DocRow({
    required this.fieldKey,
    required this.label,
    required this.agreed,
    required this.onTap,
  });

  final Key fieldKey;
  final String label;
  final bool agreed;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => CheckboxListTile(
    key: fieldKey,
    contentPadding: EdgeInsets.zero,
    controlAffinity: ListTileControlAffinity.leading,
    value: agreed,
    onChanged: (_) => onTap(),
    title: Text(
      label,
      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
    ),
    subtitle: agreed
        ? null
        : const Text(
            '押すと、内容のページが開きます。読んで戻ると、チェックがつきます。',
            style: TextStyle(fontSize: 12, height: 1.5),
          ),
  );
}
