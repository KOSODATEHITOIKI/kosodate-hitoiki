import 'package:flutter/material.dart';

import 'legal_document_page.dart';
import 'legal_documents.dart';

/// 利用規約とプライバシーポリシーへの同意と、18歳以上であることの確認(自己申告)。
/// 規約・ポリシーは、本文を最後まで読んでからチェックがつく。3つすべてにチェックが
/// つくと登録できる(呼び出し側で判定する)。
class LegalConsent extends StatelessWidget {
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
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      _Row(
        fieldKey: const ValueKey('consent-terms'),
        document: LegalDocument.terms,
        agreed: termsAgreed,
        onChanged: onTermsChanged,
      ),
      _Row(
        fieldKey: const ValueKey('consent-privacy'),
        document: LegalDocument.privacy,
        agreed: privacyAgreed,
        onChanged: onPrivacyChanged,
      ),
      // 自己申告。読む文書はないので、そのままチェックできる。
      CheckboxListTile(
        key: const ValueKey('consent-age'),
        contentPadding: EdgeInsets.zero,
        controlAffinity: ListTileControlAffinity.leading,
        value: ageConfirmed,
        onChanged: (value) => onAgeChanged(value ?? false),
        title: const Text(
          '18歳以上です',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
        ),
      ),
    ],
  );
}

class _Row extends StatelessWidget {
  const _Row({
    required this.fieldKey,
    required this.document,
    required this.agreed,
    required this.onChanged,
  });

  final Key fieldKey;
  final LegalDocument document;
  final bool agreed;
  final ValueChanged<bool> onChanged;

  /// 本文を開く。最後まで読んで戻ったときだけ、チェックをつける。
  Future<void> _read(BuildContext context) async {
    // 入力中の欄からフォーカスを外してから開く。外さないと、戻ったときに
    // その入力欄へフォーカスが戻って、キーボードが出てしまう。
    FocusManager.instance.primaryFocus?.unfocus();
    final read = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => LegalDocumentPage(document: document)),
    );
    FocusManager.instance.primaryFocus?.unfocus();
    if (read == true) onChanged(true);
  }

  @override
  Widget build(BuildContext context) => CheckboxListTile(
    key: fieldKey,
    contentPadding: EdgeInsets.zero,
    controlAffinity: ListTileControlAffinity.leading,
    value: agreed,
    // 未読のときは、チェックを押すと本文が開く。読んだあとは、外すこともできる。
    onChanged: (value) => agreed ? onChanged(false) : _read(context),
    title: Text(
      document.title,
      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
    ),
  );
}
