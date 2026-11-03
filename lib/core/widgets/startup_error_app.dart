import 'package:flutter/material.dart';

/// Supabase初期化に失敗した場合の最小限のエラー画面。
/// (`.env`未作成・接続先未設定などが原因になりうる)
class StartupErrorApp extends StatelessWidget {
  const StartupErrorApp({super.key, required this.error});

  final Object error;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text('アプリの起動に失敗しました。\n$error'),
          ),
        ),
      ),
    );
  }
}
