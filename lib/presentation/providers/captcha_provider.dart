import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/config/turnstile_config.dart';

/// 確認の部品(Turnstile)を出すか。通常は[TurnstileConfig.enabled]。テストでは差し替える。
final captchaEnabledProvider = Provider<bool>(
  (ref) => TurnstileConfig.enabledOverride ?? TurnstileConfig.enabled,
);

/// 確認の部品が出した、いま使えるトークン(なければnull)。
///
/// - 画面(確認の部品)が置き、認証のリポジトリが、登録・ログインなどを呼ぶ瞬間に取り出す。
/// - トークンは1回限り。取り出したら、すぐ消す(使い回さない)。
/// - ログには出さない。
final captchaTokenProvider = StateProvider<String?>((ref) => null);
