/// 登録・ログイン画面の入力チェック。問題があれば「何が足りないか」を日本語で返し、
/// 問題がなければnullを返す。
///
/// パスワードの条件は要件が未決定のため、ここでは決めない。ログインでは空欄だけ
/// 確認する(登録済みのパスワードは、今の条件を満たさないかもしれない)。登録では、
/// 現在のSupabase Authの設定(password_policy.dart)に合わせて足りないことを案内する。
/// 最終判定はSupabase Authが行う(auth_messages.dart)。
library;

import 'package:flutter/widgets.dart';

import '../../../core/config/password_policy.dart';

const nicknameMinLength = 2;
const nicknameMaxLength = 12;

String? nicknameProblem(String value) {
  final length = value.trim().characters.length;
  if (length == 0) return 'ニックネームを入力してください。';
  if (length < nicknameMinLength) {
    return 'あと${nicknameMinLength - length}文字必要です。($nicknameMinLength〜$nicknameMaxLength文字)';
  }
  if (length > nicknameMaxLength) {
    return '$nicknameMaxLength文字以内にしてください。';
  }
  return null;
}

String? emailProblem(String value) {
  final email = value.trim();
  if (email.isEmpty) return 'メールアドレスを入力してください。';
  if (RegExp(r'\s').hasMatch(email)) return '空白は使えません。';
  final at = email.indexOf('@');
  if (at < 0) return '「@」を含めてください。(例: example@example.com)';
  if (at == 0) return '「@」の前に、メールアドレスの名前部分を入力してください。';
  if (email.indexOf('@', at + 1) >= 0) return '「@」は1つだけにしてください。';
  final domain = email.substring(at + 1);
  if (domain.isEmpty) return '「@」のあとに、ドメイン(例: example.com)を入力してください。';
  if (!domain.contains('.') || domain.startsWith('.') || domain.endsWith('.')) {
    return '「@」のあとは、「example.com」のように「.」でつないで入力してください。';
  }
  return null;
}

String? passwordProblem(String value) =>
    value.isEmpty ? 'パスワードを入力してください。' : null;

/// 登録時のパスワード。足りないことをまとめて案内する(例: 「あと3文字・英大文字が必要です。」)。
String? passwordRegisterProblem(String value) {
  if (value.isEmpty) return 'パスワードを入力してください。';
  final length = value.characters.length;
  final missing = [
    if (length < PasswordPolicy.minLength)
      'あと${PasswordPolicy.minLength - length}文字',
    if (!PasswordPolicy.upper.hasMatch(value)) '英大文字',
    if (!PasswordPolicy.lower.hasMatch(value)) '英小文字',
    if (!PasswordPolicy.digit.hasMatch(value)) '数字',
  ];
  return missing.isEmpty ? null : '${missing.join('・')}が必要です。';
}

/// 確認用のパスワード。もとのパスワードと同じか。
String? passwordConfirmProblem(String password, String confirm) {
  if (confirm.isEmpty) return '確認のため、もう一度入力してください。';
  if (confirm != password) return 'パスワードが一致しません。';
  return null;
}
