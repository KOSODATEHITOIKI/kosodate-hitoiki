import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/auth_provider.dart';
import 'legal_consent.dart';
import 'profile_creation.dart';

/// 認証は済んだがプロフィールが未作成の利用者に、ニックネームと利用規約への同意を
/// 入力してもらう(API契約2節「プロフィール未登録ならプロフィール登録へ」)。
/// 作成できたら`true`、戻る操作で中断したら`false`を返す。
class ProfileSetupPage extends ConsumerStatefulWidget {
  const ProfileSetupPage({super.key, this.initialNickname = ''});
  final String initialNickname;

  @override
  ConsumerState<ProfileSetupPage> createState() => _ProfileSetupPageState();
}

class _ProfileSetupPageState extends ConsumerState<ProfileSetupPage> {
  final _form = GlobalKey<FormState>();
  late final _nickname = TextEditingController(text: widget.initialNickname);
  bool _agreeTerms = false;
  bool _agreePrivacy = false;
  bool _confirmedAge = false;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _nickname.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _busy = true;
      _error = null;
    });
    final error = await createProfileWithConfirmation(
      context: context,
      repository: ref.read(profileRegistrationRepositoryProvider),
      nickname: _nickname.text.trim(),
    );
    if (!mounted) return;
    if (error == null) {
      Navigator.of(context).pop(true);
      return;
    }
    setState(() {
      _busy = false;
      _error = error.isEmpty ? null : error;
    });
  }

  @override
  Widget build(BuildContext context) => PopScope<bool>(
    canPop: false,
    onPopInvokedWithResult: (didPop, _) {
      if (!didPop && !_busy) Navigator.of(context).pop(false);
    },
    child: Scaffold(
      appBar: AppBar(title: const Text('プロフィール登録')),
      body: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
              child: Form(
                key: _form,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'はじめに、ニックネームを決めてください。\n他の人に表示されます。',
                      style: TextStyle(height: 1.7),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      key: const ValueKey('setup-nickname'),
                      controller: _nickname,
                      maxLength: 12,
                      decoration: const InputDecoration(
                        labelText: 'ニックネーム',
                        helperText: '2〜12文字・本名やお子さんの名前は使わないでください。',
                        counterText: '',
                        prefixIcon: Icon(Icons.person_outline),
                      ),
                      validator: (value) =>
                          (value ?? '').trim().characters.length < 2
                          ? '2〜12文字で入力してください。'
                          : null,
                    ),
                    const SizedBox(height: 12),
                    LegalConsent(
                      termsAgreed: _agreeTerms,
                      privacyAgreed: _agreePrivacy,
                      onTermsChanged: (value) => setState(() {
                        _agreeTerms = value;
                        _error = null;
                      }),
                      onPrivacyChanged: (value) => setState(() {
                        _agreePrivacy = value;
                        _error = null;
                      }),
                      ageConfirmed: _confirmedAge,
                      onAgeChanged: (value) => setState(() {
                        _confirmedAge = value;
                        _error = null;
                      }),
                    ),
                    if (_error != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Text(
                          _error!,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    const SizedBox(height: 8),
                    FilledButton(
                      key: const ValueKey('setup-submit'),
                      onPressed:
                          _busy ||
                              !(_agreeTerms && _agreePrivacy && _confirmedAge)
                          ? null
                          : _submit,
                      child: Text(_busy ? '登録しています…' : '登録する'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
