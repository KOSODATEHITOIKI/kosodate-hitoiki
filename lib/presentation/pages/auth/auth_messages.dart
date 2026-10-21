import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/config/flavor.dart';
import '../../../core/config/password_policy.dart';
import '../../../data/api/api_exception.dart';

const _generic = 'うまくいきませんでした。通信状況を確認して、もう一度お試しください。';

/// 原因を調べやすいよう、dev環境だけ、エラーの種類と内容を文言の後ろに足す。
String withDevDetail(String message, Object error) =>
    AppConfig.flavor == Flavor.dev ? '$message\n(開発用: $error)' : message;

/// 認証(Supabase Auth)のエラーを、利用者向けの文言にする。
/// 登録の有無を推測させる文言は避ける(要件定義書3.3)。
String authErrorMessage(Object error) {
  if (error is AuthRetryableFetchException) {
    return '通信できませんでした。電波の良い場所で、もう一度お試しください。';
  }
  if (error is AuthException) {
    switch (error.code) {
      case 'invalid_credentials':
        return 'メールアドレスまたはパスワードが違います。';
      case 'email_not_confirmed':
        return '確認メールのリンクを開いてから、ログインしてください。';
      case 'user_already_exists':
      case 'email_exists':
        return 'このメールアドレスでは登録できません。ログインをお試しください。';
      case 'weak_password':
        return 'パスワードが条件を満たしていません。${PasswordPolicy.description}';
      case 'over_email_send_rate_limit':
      case 'over_request_rate_limit':
        return 'しばらく時間をおいてから、もう一度お試しください。';
    }
    // 新規登録の一時停止(Authのフックが拒否)。サーバーの文言をそのまま見せる。
    if (error.message.contains('お休み')) return error.message;
  }
  return withDevDetail(_generic, error);
}

/// プロフィール作成(`profile-create`)の失敗を、利用者向けの文言にする。
String profileErrorMessage(ApiException error) {
  if (error.isSignupHalted) {
    return '現在、新規登録を一時的にお休みしています。';
  }
  if (error.isUnavailable) {
    return '確認の仕組みが一時的に使えません。しばらくしてから、もう一度お試しください。';
  }
  switch (error.code) {
    case 'CONFLICT':
      return 'このニックネームは使えません。別のニックネームにしてください。';
    case 'VALIDATION_FAILED':
    case 'MODERATION_REJECTED':
      // サーバーの文言は日本語で、理由が分かる(API契約1節)。
      if (error.message.isNotEmpty) return error.message;
  }
  return withDevDetail(_generic, error);
}
