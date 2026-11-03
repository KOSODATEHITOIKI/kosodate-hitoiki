import 'package:flutter/material.dart';

import '../../../data/api/api_exception.dart';
import 'post_messages.dart';

/// 送信前チェックのある操作(プロフィール・ニックネームの変更など)を実行する。
///
/// 確認が必要(`MODERATION_CONFIRM_REQUIRED`)なときは、確認のダイアログを出し、
/// 「そのまま」を選んだら[action]を`confirmed: true`でもう一度実行する。
///
/// 成功なら`null`、利用者が確認で「書き直す」を選んだときは`''`(文言は出さず入力へ戻す)、
/// 失敗なら利用者向けの文言を返す。送信不可(422)は理由の文言になる。
Future<String?> runModerated({
  required BuildContext context,
  required Future<void> Function(bool confirmed) action,
  String confirmLabel = 'そのまま保存',
}) async {
  var confirmed = false;
  while (true) {
    try {
      await action(confirmed);
      return null;
    } on ApiException catch (error) {
      if (error.isRejected) return rejectionMessage(error);
      if (!error.isConfirmRequired || confirmed) {
        return postFailureMessage(error);
      }
      if (!context.mounted) return '';
      final proceed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('もう一度確認してください'),
          content: Text(confirmMessage(error)),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('書き直す'),
            ),
            FilledButton(
              key: const ValueKey('moderated-proceed'),
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(confirmLabel),
            ),
          ],
        ),
      );
      if (proceed != true) return '';
      confirmed = true;
    } catch (error) {
      return postFailureMessage(error);
    }
  }
}
