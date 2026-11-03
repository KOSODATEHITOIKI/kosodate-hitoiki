import 'package:kosodate_hitoiki/domain/models/report.dart';
import 'package:kosodate_hitoiki/domain/repositories/report_repository.dart';

/// 通報の呼び出しを記録し、決めた結果(成功・失敗)を返す偽のリポジトリ。
class ScriptedReportRepository implements ReportRepository {
  ScriptedReportRepository({this.result, this.error, this.sample = false});

  /// 成功のときの結果。
  final ReportResult? result;

  /// 失敗のとき、投げるエラー。
  final Object? error;
  final bool sample;
  final calls = <ReportCall>[];

  @override
  bool get isSample => sample;

  @override
  Future<ReportResult> submitReport({
    required String targetType,
    required String targetId,
    required ReportReason reason,
    String detail = '',
  }) async {
    calls.add(ReportCall(targetType, targetId, reason, detail));
    if (error != null) throw error!;
    return result ?? const ReportResult(id: 'r-1');
  }
}

class ReportCall {
  ReportCall(this.targetType, this.targetId, this.reason, this.detail);
  final String targetType;
  final String targetId;
  final ReportReason reason;
  final String detail;
}
