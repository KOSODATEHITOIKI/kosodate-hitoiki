import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// アプリ全体で共有するSupabaseクライアント。
/// `SupabaseConfig.initialize()`が`main()`で完了済みであることが前提。
final supabaseClientProvider = Provider<SupabaseClient>((ref) {
  return Supabase.instance.client;
});
