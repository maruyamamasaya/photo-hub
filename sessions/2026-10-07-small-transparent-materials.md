# 小さい素材と透過プレビュー
## Request
小画像は中央に余白付きで表示し、透過背景・寸法・原寸と拡大の切り替えを用意する。
## Investigation
既存プレビューはJPEGへ背景色を合成していた。原本の寸法はDBに存在し、派生のthumbnail処理は元より拡大しない。
## Changes
128px以下の小画像を一覧で中央原寸表示し、寸法を表示。詳細を全体・原寸・4倍とドット鮮明化の切り替えに対応。透過派生はPNGにしてアルファを維持。既存小画像は対応原本を表示するため透過を即時確認可能。
## Files Changed
- web/src/App.tsx, AssetDetail.tsx, styles.css
- local-api/vault/service.py
- local-api/tests/test_vault.py
- CURRENT.md, ARCHITECTURE.md
## Validation
Webビルド成功。素材API24テスト成功（50px維持・半透明アルファ検証を含む）。実ブラウザーで生成した50px透過素材を取り込み、一覧50px、詳細4倍200px・pixelatedを確認。文書verifyとgit diff --check成功。
## Result
通常画像の正方形タイルを維持し、小素材の余白・透過・寸法・拡大を確認できる。
## Remaining Issues
全体26テスト中、別領域test_desktopの起動PID比較がWindowsの親/子プロセス差で1件失敗。素材APIテストは全成功。既存の大画像JPEG派生の透過復元には詳細から再生成が必要。iOSの対応と実機確認は今回未実施。
