# ローカル主体の保管設計と所在確認用実装
## Request
ローカル主体・共有時のみリモート移動へ設計更新。既存原本を開発用リモートとして表示し、新しいローカル画像をアプリで実機確認できるよう実装。
## Investigation
通常／アーカイブは分類、原本の所在・端末保持は別軸。Windows試作とWebの既定DBは独立しており、既存素材を比較するには明示的なライブラリ切り替えが必要。
## Changes
保管設計と判断0008を作成。SQLite v4で既存原本をdevelopment-remote、新規原本をlocalへ分類。所在バッジ・詳細・フィルター、固定フォルダ参照登録を実装。参照元の欠損／変更表示と削除時保持を追加。管理取り込みは読めるファイル名でコピー保存。既存Webライブラリを開く-WebLibrary起動を追加。
## Files Changed
保管設計、関連設計・判断・CURRENT・ARCHITECTURE・CODEMAP、local-api/vault・テスト、Web画面、共通契約と生成DTO、desktop/main.cjs、start-desktop.ps1、確認用画像生成スクリプト、運用文書。
## Validation
API29件、既存API8件、Node3件、Web型チェック／ビルド、共通契約一致、文書full、git diff --check、Electron描画smokeを確認。ブラウザで混在表示・所在絞り込み・詳細・フォルダ新画像登録を確認し、エラーログなし。既存Web原本20件のパス・ハッシュ保持とSQLite integrity_checkを確認。参照原本を元の内容に戻した時の回復も含め最終API29件を再検証。
## Result
確認用ローカル画像を配置。Webライブラリは既存開発用リモート20点＋ローカル4点。Webサーバーを停止し、同じライブラリでWindowsアプリを起動。確認画像は.local/hybrid-storage-proof.jpg。既存DBは追加前にSQLite backup APIで退避。
## Remaining Issues
リモート実体もこのPC内の模擬保存。AWS、共有DB、転送・容量解放、複数所在・端末保持、任意フォルダ登録、移動の自動追跡・同じパスの改訂登録は未実装。Mac／Swift実機検証は未実施。参照元を残した削除後は次回フォルダ登録で再登録される。
