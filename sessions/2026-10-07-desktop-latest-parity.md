# 両OSの最新版追従確認
## Request
WindowsとMacが現在の最新版に追従しているか確認する。
## Investigation
共通シェル・UIビルド・APIと起動入口を確認。最新UI変更後にWebビルドが更新されている。所在表示と参照登録も両OSの共有コード。Mac起動スクリプトだけWebライブラリ切替の引数転送がなかった。
## Changes
Mac起動からElectronへ引数を転送し、--web-libraryの手順を追加。
## Files Changed
scripts/start-desktop.sh、docs/DESKTOP-OPERATIONS.md、本記録。
## Validation
文書fullと差分空白を確認。変更は起動引数転送のみ。Mac実行・実機と開いているアプリの表示バージョンは未検証。
## Result
両OSが同じ最新UI/APIを使う構成と起動オプションを揃えた。起動スクリプトはWebを再ビルドする。起動済みアプリには終了・再起動が必要。
## Remaining Issues
Mac実機検証、各端末への最新ソース取得、配布・自動更新、端末間データ同期は別途必要。
