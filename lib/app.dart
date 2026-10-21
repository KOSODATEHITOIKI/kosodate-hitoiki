import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/config/flavor.dart';
import 'core/constants/app_theme.dart';
import 'core/utils/accessibility.dart';
import 'presentation/pages/auth/new_password_page.dart';
import 'presentation/pages/welcome/welcome_page.dart';
import 'presentation/widgets/main_navigation_shell.dart';
import 'presentation/providers/auth_provider.dart';
import 'presentation/providers/comment_providers.dart';
import 'presentation/providers/mute_providers.dart';
import 'presentation/providers/notification_providers.dart';
import 'presentation/providers/profile_providers.dart';
import 'presentation/providers/post_providers.dart';

final _navigatorKey = GlobalKey<NavigatorState>();

class App extends ConsumerStatefulWidget {
  const App({super.key});

  @override
  ConsumerState<App> createState() => _AppState();
}

class _AppState extends ConsumerState<App> {
  /// 新しいパスワードの画面を開いている間(二重に開かない)。
  bool _newPasswordOpen = false;

  /// パスワード再設定のメールのリンクから戻ったとき、新しいパスワードの画面を開く。
  void _openNewPassword() {
    final navigator = _navigatorKey.currentState;
    if (_newPasswordOpen) return;
    if (navigator == null) {
      // 起動直後で、画面がまだ組み上がっていない。組み上がってから開く。
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _navigatorKey.currentState != null) _openNewPassword();
      });
      return;
    }
    _newPasswordOpen = true;
    navigator
        .push<void>(MaterialPageRoute(builder: (_) => const NewPasswordPage()))
        .whenComplete(() => _newPasswordOpen = false);
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AsyncValue<AuthState>>(authStateChangesProvider, (_, next) {
      if (next.valueOrNull?.event == AuthChangeEvent.passwordRecovery) {
        _openNewPassword();
      }
    });
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
      navigatorKey: _navigatorKey,
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
