import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/config/flavor.dart';
import 'core/constants/app_theme.dart';
import 'core/utils/accessibility.dart';
import 'presentation/pages/welcome/welcome_page.dart';
import 'presentation/providers/auth_provider.dart';
import 'presentation/providers/post_providers.dart';

class App extends ConsumerWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 利用者IDが変わるたびに投稿リポジトリを作り直し、前の利用者が
    // 変更したモックデータ(保存状態等)を次の利用者に引き継がない。
    // ログイン・ログアウトだけでなく、ログインしたまま別の利用者に
    // 切り替わった場合(A→B)も検知するため、真偽値ではなく利用者IDを監視する。
    ref.listen<String?>(currentUserIdProvider, (previous, next) {
      if (previous != next) ref.invalidate(postRepositoryProvider);
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
      home: const WelcomePage(),
    );
  }
}
