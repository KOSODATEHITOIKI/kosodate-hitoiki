import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/datasources/supabase_client_provider.dart';
import '../../data/repositories/content_moderation_repository.dart';

final contentModerationRepositoryProvider =
    Provider<ContentModerationRepository>((ref) {
      return ContentModerationRepository(ref.watch(supabaseClientProvider));
    });
