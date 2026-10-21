import 'package:flutter/widgets.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/models/report.dart';
import '../../domain/repositories/report_repository.dart';
import '../api/api_exception.dart';

/// 通報(`POST /functions/v1/reports`)。同じ人が同じ対象を通報し直したときは、件数が増えず
/// `200 { duplicate: true }`になる(バックエンド docs/API契約.md 7節)。
class SupabaseReportRepository implements ReportRepository {
  SupabaseReportRepository(this._client);

  final SupabaseClient _client;

  @override
  bool get isSample => false;

  @override
  Future<ReportResult> submitReport({
    required String targetType,
    required String targetId,
    required ReportReason reason,
    String detail = '',
  }) async {
    try {
      final response = await _client.functions.invoke(
        'reports',
        body: requestBody(
          targetType: targetType,
          targetId: targetId,
          reason: reason,
          detail: detail,
        ),
      );
      return resultFromResponse(response.data);
    } on FunctionException catch (error) {
      throw ApiException.fromFunction(error);
    }
  }

  /// 通報APIのリクエスト本文。補足は、前後の空白を除き、200文字までにする。
  static Map<String, dynamic> requestBody({
    required String targetType,
    required String targetId,
    required ReportReason reason,
    String detail = '',
  }) => {
    'target_type': targetType,
    'target_id': targetId,
    'reason': reason.code,
    'detail': detail.trim().characters.take(200).toString(),
  };

  /// 応答(`{ id, duplicate }`)を、通報の結果にする。
  static ReportResult resultFromResponse(Object? data) {
    final map = data is Map ? data.cast<String, dynamic>() : const {};
    return ReportResult(
      id: map['id'] as String? ?? '',
      duplicate: map['duplicate'] == true,
    );
  }
}
