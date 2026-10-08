# Device signing preparation
## Request
指定端末へのビルドとインストール。既存署名資産だけを使用し、新規権限・証明書・信頼設定を作らない。
## Investigation
接続端末の実名Vespera（iPhone17e）と依頼表記Vesparaが異なり、対象確認を提示。既存ワイルドカードprofileはこの端末を含み、現在のpersonal.photohubに対応可能。
## Changes
アプリソース・プロジェクト設定変更なし。署名済みコピーは作業成果物vespera-install/PhotoHub.appへ配置。
## Files Changed
- sessions/2026-10-08-device-signing-preparation.md
## Validation
既存profileをXcode手動署名へ指定するとXcode管理profileとの不一致で失敗。自動署名はauto-reviewがApple側の管理資産更新リスクを理由に拒否。
安全な代替として既存profileをコピーへ埋め込み、対応する既存identityでオフラインcodesign。許可済み標準entitlementsの範囲内で、App Groups等の追加なし。通常Securityサービス下でcodesign --verify --deep --strict成功。信頼設定、証明書、認証設定、プロジェクト設定変更なし。
## Result
署名済みのPhotoHub.appを準備済み。対象名の確認待ちでインストール・起動未実施。
## Remaining Issues
本人が実名Vesperaが指定対象であることを確認後、既存データを保持してインストールする。写真ライブラリ権限、Developer Mode、信頼、キーチェーン確認は代行しない。
