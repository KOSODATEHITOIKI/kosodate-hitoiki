import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/legal_links.dart';
import '../../widgets/external_link.dart';

/// 利用規約・プライバシーポリシーへの同意と、18歳以上であることの確認(自己申告)。
/// 規約・ポリシーの本文は、公開ページ(外部のブラウザ)で読む。3つすべてにチェックが
/// つくと登録できる(呼び出し側で判定する)。
class LegalConsent extends ConsumerWidget {
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
  Widget build(BuildContext context, WidgetRef ref) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      _Row(
        fieldKey: const ValueKey('consent-terms'),
        openKey: const ValueKey('consent-terms-open'),
        label: '利用規約に同意する',
        agreed: termsAgreed,
        onChanged: onTermsChanged,
        onOpen: () =>
            openExternalLink(context, ref, LegalLinks.terms, title: '利用規約'),
      ),
      _Row(
        fieldKey: const ValueKey('consent-privacy'),
        openKey: const ValueKey('consent-privacy-open'),
        label: 'プライバシーポリシーに同意する',
        agreed: privacyAgreed,
        onChanged: onPrivacyChanged,
        onOpen: () => openExternalLink(
          context,
          ref,
          LegalLinks.privacy,
          title: 'プライバシーポリシー',
        ),
      ),
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

/// 同意のチェックと、「読む」(公開ページを開く)。
class _Row extends StatelessWidget {
  const _Row({
    required this.fieldKey,
    required this.openKey,
    required this.label,
    required this.agreed,
    required this.onChanged,
    required this.onOpen,
  });

  final Key fieldKey;
  final Key openKey;
  final String label;
  final bool agreed;
  final ValueChanged<bool> onChanged;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: CheckboxListTile(
          key: fieldKey,
          contentPadding: EdgeInsets.zero,
          controlAffinity: ListTileControlAffinity.leading,
          value: agreed,
          onChanged: (value) => onChanged(value ?? false),
          title: Text(
            label,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
          ),
        ),
      ),
      TextButton(key: openKey, onPressed: onOpen, child: const Text('読む')),
    ],
  );
}
