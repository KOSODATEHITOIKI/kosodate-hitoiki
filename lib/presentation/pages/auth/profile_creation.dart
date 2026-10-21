import 'package:flutter/material.dart';

import '../../../core/config/terms.dart';
import '../../../data/api/api_exception.dart';
import '../../../data/repositories/profile_registration_repository.dart';
import 'auth_messages.dart';

/// プロフィールを作る。送信前チェックで確認が必要なときは、確認ダイアログを
/// 出し、「そのまま登録」なら`confirmed: true`で再送する。
///
/// 成功なら`null`、失敗なら利用者向けの文言を返す。確認ダイアログで
/// 「書き直す」を選んだときは`''`(空文字。文言は出さず入力欄へ戻す)を返す。
Future<String?> createProfileWithConfirmation({
  required BuildContext context,
  required ProfileRegistrationRepository repository,
  required String nickname,
}) async {
  var confirmed = false;
  while (true) {
    try {
      await repository.create(
        nickname: nickname,
        termsVersion: TermsConfig.version,
        confirmed: confirmed,
      );
      return null;
    } on ApiException catch (error) {
      if (!error.isConfirmRequired || confirmed) {
        return profileErrorMessage(error);
      }
      if (!context.mounted) return '';
      final proceed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('もう一度確認してください'),
          content: Text(
            error.message.isNotEmpty ? error.message : '誰かを傷つける表現になっていませんか？',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('書き直す'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('そのまま登録'),
            ),
          ],
        ),
      );
      if (proceed != true) return '';
      confirmed = true;
    } catch (_) {
      return profileErrorMessage(
        const ApiException(code: 'UNKNOWN', message: ''),
      );
    }
  }
}
