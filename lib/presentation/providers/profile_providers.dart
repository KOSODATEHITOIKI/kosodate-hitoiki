import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/mock/mock_profile_repository.dart';
import '../../domain/models/user_profile.dart';
import '../../domain/repositories/profile_repository.dart';
import 'auth_provider.dart';

final profileRepositoryProvider = Provider<ProfileRepository>(
  (ref) => MockProfileRepository(),
);

/// 直接画面を開いても、ゲストにはプロフィール取得を行わない。
/// API接続時にはサーバー側の認証・認可も必須。
final otherProfileProvider = FutureProvider.autoDispose
    .family<UserProfile?, String>((ref, userId) async {
      if (!ref.watch(isLoggedInProvider)) return null;
      return ref.watch(profileRepositoryProvider).fetchProfile(userId);
    });
