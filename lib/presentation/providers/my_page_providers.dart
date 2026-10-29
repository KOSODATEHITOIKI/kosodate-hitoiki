import 'package:flutter_riverpod/flutter_riverpod.dart';

/// マイページで「保存した投稿」を見ているか(`false`は「自分の投稿」)。
/// 広い画面の左メニューの「保存した投稿」から、保存の一覧を直接開くために共有する。
final myPageSavedPostsProvider = StateProvider<bool>((ref) => false);
