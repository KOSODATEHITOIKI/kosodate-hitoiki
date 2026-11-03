import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/mock/mock_report_repository.dart';
import '../../domain/repositories/report_repository.dart';

/// 通報の送り先。バックエンド接続時は、main_dev/prodでSupabase実装に差し替える。
final reportRepositoryProvider = Provider<ReportRepository>(
  (ref) => MockReportRepository(),
);
