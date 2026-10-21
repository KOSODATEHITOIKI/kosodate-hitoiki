import '../../domain/models/report.dart';
import '../../domain/repositories/report_repository.dart';

/// 画面確認・テスト用のモック実装。送信はせず、同じ対象の通報し直しは`duplicate`にする。
class MockReportRepository implements ReportRepository {
  final _reported = <String>{};

  @override
  bool get isSample => true;

  @override
  Future<ReportResult> submitReport({
    required String targetType,
    required String targetId,
    required ReportReason reason,
    String detail = '',
  }) async {
    final duplicate = !_reported.add('$targetType:$targetId');
    return ReportResult(id: 'sample-report', duplicate: duplicate);
  }
}
