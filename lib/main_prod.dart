import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'core/config/flavor.dart';
import 'core/config/supabase_config.dart';
import 'core/widgets/startup_error_app.dart';
import 'data/datasources/supabase_client_provider.dart';
import 'data/repositories/supabase_account_repository.dart';
import 'data/repositories/supabase_comment_repository.dart';
import 'presentation/providers/account_providers.dart';
import 'data/repositories/supabase_post_repository.dart';
import 'data/repositories/supabase_profile_repository.dart';
import 'presentation/providers/profile_providers.dart';
import 'data/repositories/supabase_report_repository.dart';
import 'presentation/providers/report_providers.dart';
import 'presentation/providers/comment_providers.dart';
import 'presentation/providers/post_providers.dart';

/// prod(リリース)環境のエントリーポイント
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  AppConfig.setFlavor(Flavor.prod);

  try {
    await SupabaseConfig.initialize();
  } catch (error) {
    runApp(StartupErrorApp(error: error));
    return;
  }

  runApp(
    ProviderScope(
      overrides: [
        // 投稿の取得はSupabaseに接続する(テストは既定のモックのまま)。
        postRepositoryProvider.overrideWith(
          (ref) => SupabasePostRepository(ref.watch(supabaseClientProvider)),
        ),
        commentRepositoryProvider.overrideWith(
          (ref) => SupabaseCommentRepository(ref.watch(supabaseClientProvider)),
        ),
        reportRepositoryProvider.overrideWith(
          (ref) => SupabaseReportRepository(ref.watch(supabaseClientProvider)),
        ),
        accountRepositoryProvider.overrideWith(
          (ref) => SupabaseAccountRepository(ref.watch(supabaseClientProvider)),
        ),
        profileRepositoryProvider.overrideWith(
          (ref) => SupabaseProfileRepository(ref.watch(supabaseClientProvider)),
        ),
      ],
      child: const App(),
    ),
  );
}
