import 'package:supabase_flutter/supabase_flutter.dart';

/// バックエンドのAPI(Edge Functions)の失敗。`{ "error": { code, message, details } }`を
/// 画面で扱いやすい形にそろえる(kosodate-hitoiki-backend docs/API契約.md 1節)。
class ApiException implements Exception {
  const ApiException({
    required this.code,
    required this.message,
    this.status,
    this.details = const {},
  });

  /// `VALIDATION_FAILED`・`CONFLICT`など。応答の形が想定外なら`UNKNOWN`。
  final String code;
  final String message;
  final int? status;
  final Map<String, dynamic> details;

  /// 送信前チェックで確認表示が必要。確認後に`confirmed: true`で再送する。
  bool get isConfirmRequired => code == 'MODERATION_CONFIRM_REQUIRED';

  /// 送信前チェックで送信不可。覆らない。
  bool get isRejected => code == 'MODERATION_REJECTED';

  /// 送信前チェックが使えない。時間をおいて再試行を促す。
  bool get isUnavailable => code == 'MODERATION_UNAVAILABLE';

  /// 新規登録の一時停止中。
  bool get isSignupHalted => details['reason'] == 'signup_halted';

  factory ApiException.fromFunction(FunctionException exception) {
    final details = exception.details;
    if (details is Map && details['error'] is Map) {
      final error = (details['error'] as Map).cast<String, dynamic>();
      final extra = error['details'];
      return ApiException(
        code: error['code'] as String? ?? 'UNKNOWN',
        message: error['message'] as String? ?? '',
        status: exception.status,
        details: extra is Map ? extra.cast<String, dynamic>() : const {},
      );
    }
    return ApiException(code: 'UNKNOWN', message: '', status: exception.status);
  }

  @override
  String toString() => 'ApiException($code, $status): $message';
}
