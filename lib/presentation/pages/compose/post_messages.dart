import '../../../core/config/flavor.dart';
import '../../../data/api/api_exception.dart';

const _generic = 'うまくいきませんでした。通信状況を確認して、もう一度お試しください。';

/// 送信不可(`MODERATION_REJECTED`)のとき、書き直しを促す文。理由コードは
/// `details.reasons`に入る(本文は含まれない。API契約3節)。サーバーの文言があればそれを使う。
String rejectionMessage(ApiException error) {
  if (error.message.isNotEmpty) return error.message;
  final reasons = (error.details['reasons'] as List?)?.cast<Object?>() ?? [];
  if (reasons.any((reason) => '$reason'.startsWith('pii'))) {
    return '名前・電話番号・住所など、個人が特定される情報が含まれているようです。'
        '「長男」「夫」のように続柄に言い換えてください。';
  }
  return '誰かを傷つける表現が含まれているようです。書き直してください。';
}

/// 確認が必要(`MODERATION_CONFIRM_REQUIRED`)のときの文。
String confirmMessage(ApiException error) => error.message.isNotEmpty
    ? error.message
    : '誰かを傷つける表現になっていませんか？\n家族や知人は「上の子」「夫」などに言い換えられます。';

/// 投稿・コメントの作成が失敗したときの、利用者向けの文言。
/// 確認(409)・送信不可(422)は別の画面で扱うので、ここでは扱わない。
String postFailureMessage(Object error) {
  if (error is ApiException) {
    final reason = error.details['reason'];
    if (error.isUnavailable) {
      return '確認の仕組みが一時的に使えません。しばらくしてから、もう一度お試しください。';
    }
    if (reason == 'profile_required') {
      return 'プロフィールの登録が必要です。ログインし直して、ニックネームを登録してください。';
    }
    if (reason == 'restricted') {
      return '現在、投稿やコメントができません。';
    }
    if (error.code == 'CONFLICT') {
      return 'このニックネームは使えません。別のニックネームにしてください。';
    }
    if (reason == 'not_allowed') {
      return '自分の投稿・コメントは、通報できません。';
    }
    if (error.code == 'NOT_FOUND') {
      return '見つかりませんでした。すでに削除されているかもしれません。';
    }
    if (error.code == 'FORBIDDEN' && reason == null) {
      return 'この操作はできません。';
    }
    if (reason == 'unavailable') {
      return '送れませんでした。しばらくしてから、もう一度お試しください。';
    }
    if (reason == 'comments_closed') {
      return 'この投稿は、コメントの受付を終了しています。';
    }
    if (error.code == 'RATE_LIMITED') {
      final retryAt = DateTime.tryParse('${error.details['retry_at']}');
      if (retryAt != null) {
        final local = retryAt.toLocal();
        final minute = local.minute.toString().padLeft(2, '0');
        return '投稿が続いたため、${local.month}月${local.day}日 ${local.hour}:$minuteごろまでお待ちください。';
      }
      return '短い間に続けて送ったため、しばらく時間をおいてから、もう一度お試しください。';
    }
    if (error.code == 'VALIDATION_FAILED' && error.message.isNotEmpty) {
      return error.message;
    }
  }
  return withDevHint(_generic, error);
}

/// 原因を調べやすいよう、dev環境だけ、エラーの内容を後ろに足す。
String withDevHint(String message, Object error) =>
    AppConfig.flavor == Flavor.dev ? '$message\n(開発用: $error)' : message;
