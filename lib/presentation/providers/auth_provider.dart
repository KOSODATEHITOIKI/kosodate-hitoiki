import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../data/datasources/supabase_client_provider.dart';
import '../../data/repositories/auth_repository.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(ref.watch(supabaseClientProvider));
});

/// ログイン状態の変化を監視するStream。
final authStateChangesProvider = StreamProvider<AuthState>((ref) {
  return ref.watch(authRepositoryProvider).authStateChanges;
});

/// 現在ログイン中の利用者ID(未ログイン時はnull)。A→Bの利用者切り替えも検知できるため、リセット判定に使う。
final currentUserIdProvider = Provider<String?>((ref) {
  final authState = ref.watch(authStateChangesProvider).valueOrNull;
  if (authState != null) {
    return authState.session?.user.id;
  }
  return ref.watch(authRepositoryProvider).currentUser?.id;
});

/// 現在ログイン中かどうか。未ログイン時はコメント・投稿・マイページ等で
/// 登録・ログイン案内を表示する分岐に使う(docs/全体設計書.md 8章)。
final isLoggedInProvider = Provider<bool>((ref) {
  return ref.watch(currentUserIdProvider) != null;
});
