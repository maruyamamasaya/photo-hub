# VesperaへのiOS導入準備
## Request
最新リモートを取得し、指定Apple IDでVesperaに導入する。
## Investigation
fetch後、mainとorigin/mainはc04d206で一致。Vesperaはペアリング済み、Developer Mode有効だが接続不可。
## Changes
指定Apple IDのTeamで署名済みアプリを一時ディレクトリに作成。コード変更なし。
## Files Changed
この作業記録。
## Validation
実機向け署名なし・署名付きビルドとも成功。画面向きの既存警告あり。実機インストールは端末を検出できず失敗。テストはコード変更がないため未実行。
## Result
署名済みPhotoHub.appを/tmp/photo-hub-device-build/Build/Products/Debug-iphoneosに作成。
## Remaining Issues
Vesperaを接続・ロック解除後にインストールと起動確認が必要。

再確認: ユーザーのロック解除後もdevicectlではVesperaがunavailable、xctraceでもOffline。インストールを再実行したが端末検出エラー。USB接続・信頼の確認待ち。
