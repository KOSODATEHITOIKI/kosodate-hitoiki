import '../models/user_profile.dart';

abstract class ProfileRepository {
  Future<UserProfile?> fetchProfile(String userId);
}
