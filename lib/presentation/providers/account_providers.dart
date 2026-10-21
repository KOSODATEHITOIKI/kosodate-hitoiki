import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/mock/mock_account_repository.dart';
import '../../domain/repositories/account_repository.dart';

/// 退会の送り先。バックエンド接続時は、main_dev/prodでSupabase実装に差し替える。
final accountRepositoryProvider = Provider<AccountRepository>(
  (ref) => MockAccountRepository(),
);
