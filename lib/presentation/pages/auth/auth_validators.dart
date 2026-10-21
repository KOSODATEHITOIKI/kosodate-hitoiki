/// 登録・ログイン画面の入力チェック。問題があれば「何が足りないか」を日本語で返し、
/// 問題がなければnullを返す。
///
/// パスワードの条件(文字数など)は要件が未決定のため、ここでは決めない。
/// 空欄のチェックだけを行い、条件を満たさない場合はSupabase Authの判定結果を
/// 送信後に表示する(auth_messages.dart)。
library;

import 'package:flutter/widgets.dart';

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
