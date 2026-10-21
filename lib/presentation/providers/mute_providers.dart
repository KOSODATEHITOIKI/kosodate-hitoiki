import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/mock/mock_mute_repository.dart';
import '../../domain/repositories/mute_repository.dart';

/// 言葉のミュートの送り先。バックエンド接続時は、main_dev/prodでSupabase実装に差し替える。
/// 利用者が変わったときは、lib/app.dartが作り直す。
final muteRepositoryProvider = Provider<MuteRepository>(
  (ref) => MockMuteRepository(),
);

/// ミュートしている言葉(新しく追加した順)。
final mutedWordsProvider = FutureProvider<List<String>>(
  (ref) => ref.watch(muteRepositoryProvider).fetchWords(),
);
