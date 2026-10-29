import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/config/flavor.dart';
import 'core/widgets/centered_page_transitions.dart';
import 'core/widgets/wide_screen_frame.dart';
import 'data/push/push_messaging.dart';
import 'core/constants/app_theme.dart';
import 'core/utils/accessibility.dart';
import 'presentation/pages/auth/auth_page.dart';
import 'presentation/pages/auth/ensure_profile.dart';
import 'presentation/pages/auth/new_password_page.dart';
import 'presentation/providers/notification_providers.dart';
import 'presentation/pages/welcome/welcome_page.dart';
import 'presentation/widgets/main_navigation_shell.dart';
import 'presentation/providers/auth_provider.dart';
import 'presentation/providers/comment_providers.dart';
import 'presentation/providers/mute_providers.dart';
import 'presentation/providers/profile_providers.dart';
import 'presentation/providers/push_providers.dart';
import 'presentation/providers/post_providers.dart';

final _navigatorKey = GlobalKey<NavigatorState>();
final _messengerKey = GlobalKey<ScaffoldMessengerState>();

class App extends ConsumerStatefulWidget {
  const App({super.key});

  @override
  ConsumerState<App> createState() => _AppState();
}

class _AppState extends ConsumerState<App> {
  /// 新しいパスワードの画面を開いている間(二重に開かない)。
  bool _newPasswordOpen = false;

  /// プロフィールの確認・作成の途中か(重ねて行わない)。
  bool _checkingProfile = false;

  /// ログイン済みでプロフィールがなければ、作る(作らないなら、ログアウトする)。
  /// 認証画面を開いている間は、その画面が行うので、ここでは行わない。メール確認・Googleの
  /// リンクから、アプリを新しく起動したときのために、起動時とログインしたときに確認する。
  Future<void> _ensureProfile() async {
    if (_checkingProfile || !mounted || AuthPage.openCount > 0) return;
    final navigatorContext = _navigatorKey.currentContext;
    if (navigatorContext == null) {
      // 画面が組み上がる前。組み上がってから確認する。
      WidgetsBinding.instance.addPostFrameCallback((_) => _ensureProfile());
      return;
    }
    _checkingProfile = true;
    try {
      final auth = ref.read(authRepositoryProvider);
      final user = auth.currentUser;
      if (user == null) return;
      final ready = await ensureProfile(
        context: navigatorContext,
        profiles: ref.read(profileRegistrationRepositoryProvider),
        user: user,
      );
      if (!mounted) return;
      if (ready) {
        ref.invalidate(myProfileProvider);
      } else {
        await auth.signOut();
      }
    } catch (_) {
      // 通信できないなど。確認できなかったことを伝え、やり直せるようにする(アプリは使える。
      // プロフィールがないまま投稿などをしても、サーバーが断る)。
      _messengerKey.currentState?.showSnackBar(
        SnackBar(
          content: const Text('プロフィールを確認できませんでした'),
          duration: const Duration(seconds: 10),
          action: SnackBarAction(
            label: '再確認',
            onPressed: () => unawaited(_ensureProfile()),
          ),
        ),
      );
    } finally {
      _checkingProfile = false;
    }
  }

  StreamSubscription<PushTap>? _pushTapSubscription;
  StreamSubscription<PushTap>? _pushForegroundSubscription;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && ref.read(isLoggedInProvider)) unawaited(_ensureProfile());
    });
    final messaging = ref.read(pushMessagingProvider);
    _pushTapSubscription = messaging.onTap.listen(_openNotifications);
    _pushForegroundSubscription = messaging.onForeground.listen(
      _onForegroundPush,
    );
    // 通知をタップして起動したときの、その1回。画面が組み上がってから開く。
    unawaited(
      messaging.getInitialTap().then((tap) {
        if (tap != null) {
          WidgetsBinding.instance.addPostFrameCallback(
            (_) => _openNotifications(tap),
          );
        }
      }),
    );
  }

  @override
  void dispose() {
    unawaited(_pushTapSubscription?.cancel());
    unawaited(_pushForegroundSubscription?.cancel());
    super.dispose();
  }

  /// メールのリンクが使えなかったことを知らせ、やり直し方を伝える。
  void _showLinkError() {
    _messengerKey.currentState
      ?..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
          content: Text('リンクの期限が切れているか、すでに使われています。お手数ですが、もう一度、メールを送ってください。'),
          duration: Duration(seconds: 10),
        ),
      );
  }

  /// アプリを開いているときに通知が届いたら、お知らせを取り直し、短く知らせる
  /// (端末の通知欄には出ないため)。ログインしていなければ、何もしない。
  void _onForegroundPush(PushTap tap) {
    if (!mounted || !ref.read(isLoggedInProvider)) return;
    ref.invalidate(notificationsProvider);
    _messengerKey.currentState?.showSnackBar(
      SnackBar(
        content: const Text('新しいお知らせがあります'),
        action: SnackBarAction(
          label: '見る',
          onPressed: () => _openNotifications(tap),
        ),
      ),
    );
  }

  /// 通知をタップしたとき、お知らせの一覧を開く(最新の状態に取り直す)。ログインしていなければ、
  /// 何もしない。
  void _openNotifications(PushTap tap) {
    if (!mounted || !ref.read(isLoggedInProvider)) return;
    _navigatorKey.currentState?.popUntil((route) => route.isFirst);
    ref.invalidate(notificationsProvider);
    ref.read(bottomNavIndexProvider.notifier).state = notificationsTabIndex;
  }

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
    // ログインしたら、この端末をプッシュ通知の送り先として登録する。
    ref.watch(pushRegistrationProvider);
    // ログインしたとき(認証画面の外で、ログインした場合も)、プロフィールを確認する。
    ref.listen<bool>(isLoggedInProvider, (previous, next) {
      if (next && previous != true) {
        WidgetsBinding.instance.addPostFrameCallback((_) => _ensureProfile());
      }
    });
    ref.listen<AsyncValue<AuthState>>(authStateChangesProvider, (_, next) {
      if (next.valueOrNull?.event == AuthChangeEvent.passwordRecovery) {
        _openNewPassword();
      }
      // メールのリンク(確認・パスワード再設定)が、期限切れ・使用済みなどで使えなかったとき。
      // 何も出さないと、押したのに何も起きなかったように見える。
      if (next.hasError && next.error is AuthException) {
        _showLinkError();
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
      scaffoldMessengerKey: _messengerKey,
      title: AppConfig.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(textScaler: responsiveTextScaler(context)),
        child: WideScreenFrame(child: child!),
      ),
      // ログイン状態が保持されていれば、案内画面を飛ばしてホームから始める(要件定義書6.2.4)。
      home: ref.watch(isLoggedInProvider)
          ? const MainNavigationShell()
          : const DesktopCentered(child: WelcomePage()),
    );
  }
}
