# Vespera installation
## Request
本人がVespera（iPhone17e）を対象と明示確認。photo-hubとPresentation-Viewerのインストールと可能な起動確認。追加権限・信頼設定・データ削除はしない。
## Investigation
接続名Vesperaと既知UDID末尾0E33401Cを再照合。既存profileとidentityで署名済みコピーをcodesign --verify --deep --strictで確認。
## Changes
アプリコード・署名設定変更なし。確認済み端末だけへdevicectl install。アンインストール・ストレージ初期化なし。
## Files Changed
- CURRENT.md
- sessions/2026-10-08-device-install.md
## Validation
Vespera/iPhone17e/iOS26.6.2へのpersonal.photohubインストール成功。devicectl launch成功、PID26274。後続の端末process一覧でプロセス存在、apps一覧でPhoto Hub登録を確認。
Presentation Viewerも同一端末へインストール・起動成功。別端末への操作なし。端末は操作前からDeveloper Mode enabledで、設定変更を行わない。
## Result
Photo Hubは実機に配置し、プロセス起動まで確認。写真ライブラリ、信頼、キーチェーン等の権限プロンプトを承諾していない。公開・pushなし。
## Remaining Issues
画面の目視、ホーム画面アイコン、写真取り込み、保存、認証・同期等の機能は未確認。my-keyboardは既存App Groups対応profile不足で保留。
