import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/config/flavor.dart';
import 'core/constants/app_theme.dart';
import 'core/utils/accessibility.dart';
import 'presentation/pages/welcome/welcome_page.dart';
import 'presentation/widgets/main_navigation_shell.dart';
import 'presentation/providers/auth_provider.dart';
import 'presentation/providers/comment_providers.dart';
import 'presentation/providers/mute_providers.dart';
import 'presentation/providers/notification_providers.dart';
import 'presentation/providers/profile_providers.dart';
import 'presentation/providers/post_providers.dart';

class App extends ConsumerWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 利用者ID(A→B切替も含む)が変わるたびに投稿リポジトリを作り直し、前の利用者のモックデータを引き継がない。
    ref.listen<String?>(currentUserIdProvider, (previous, next) {
      if (previous != next) {
        ref.invalidate(postRepositoryProvider);
        ref.invalidate(commentRepositoryProvider);
        ref.invalidate(profileRepositoryProvider);
        ref.invalidate(notificationRepositoryProvider);
        ref.invalidate(muteRepositoryProvider);
      }
    });
    return MaterialApp(
      title: AppConfig.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(textScaler: responsiveTextScaler(context)),
        child: child!,
      ),
      // ログイン状態が保持されていれば、案内画面を飛ばしてホームから始める(要件定義書6.2.4)。
      home: ref.watch(isLoggedInProvider)
          ? const MainNavigationShell()
          : const WelcomePage(),
    );
  }
}
