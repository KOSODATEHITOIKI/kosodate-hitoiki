# kosodate-hitoiki
子育ての愚痴をこぼし、コメントでコツや体験談を共有できるSNSアプリ（Flutter + Supabase）

バックエンド（Supabaseのマイグレーション・RLSポリシー・Edge Functions）は別リポジトリ [kosodate-hitoiki-backend](https://github.com/naka328/kosodate-hitoiki-backend) で管理する。

詳細設計は [docs/全体設計書.md](docs/全体設計書.md) を参照。

## セットアップ

```bash
flutter pub get
flutter run --flavor dev -t lib/main_dev.dart
```

環境はdev/prodの2種(VS Codeの「実行とデバッグ」にも設定済み)。詳細は[docs/環境とブランチ運用.md](docs/環境とブランチ運用.md)を参照。

Supabaseの接続先は[lib/core/config/supabase_config.dart](lib/core/config/supabase_config.dart)に直接記載している(匿名キーは公開情報のため.envでの秘匿は不要。理由は同ファイルのコメント参照)。実際のプロジェクト作成後は同ファイルの値を差し替える。
