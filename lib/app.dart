import 'package:flutter/material.dart';

import 'core/config/flavor.dart';
import 'core/constants/app_theme.dart';
import 'core/utils/accessibility.dart';
import 'presentation/pages/welcome/welcome_page.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
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
