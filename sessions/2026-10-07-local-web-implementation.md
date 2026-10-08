# ローカルWeb素材ライブラリ実装
## Request
精緻な段階プロンプトとテスト・実機確認条件を用意し、順番に実装する。今回の目標はWeb版のローカル動作と、iOSを将来Webに合わせて構築できる共通仕様。
## Investigation
既存設計・コード・対象子AGENTS・運用と検証を確認。WindowsでNode 24.19/Python 3.12を利用。Swift/Xcodeなし。依存選定は公式資料と実環境で確認。
## Changes
6段階プロンプトを作成し、共通契約→保存/追加→Web一覧/詳細→整理/検索→回復/運用→検証を実施。React/TypeScript、FastAPI/SQLite/Pillow、原本・派生保存、タグ・コレクション・検索、ごみ箱・復元・完全削除、再試行、ローカル境界を実装。共通スキーマからWeb型とSwift DTOを生成し、独立したSwift取得クライアントとMac用テストを追加。既存iOSのDBと画面は切り替えていない。
## Files Changed
web/、local-api/、contracts/、Sources/AssetLibraryContract/、Tests/AssetLibraryContractTests/、Package.swift、Web関連scripts、段階・運用・iOS契約文書、役割別ルート文書、decisions/0005、.gitignore、本記録。
## Validation
- API15テスト成功: 原本一致、重複、部分失敗、再起動、中断回復、整理、競合、ごみ箱/復元/削除、容量不足注入、派生再生成、境界、バックアップ復元、契約。
- 既存署名API8テスト成功。Web TypeScript/build成功。文書full・共通生成チェック・git diff --check成功。
- 実ブラウザ: 生成素材12件追加、ファイル選択の重複検出、名前/メモ/タグ/所属/お気に入り保存、検索、詳細、原本取得、ごみ箱→復元。ダウンロード原本は入力とSHA256一致。390px幅で横はみ出しなし、画像12件表示。ブラウザerror/warnログなし。
- 1,000件生成64×64 PNG: 原本とJPEG派生込みの登録219.31秒。API60件一覧中央値402.02ms、100件一致検索中央値400.69ms（各3回）。全1,000件をページ分割して重複なし。Windows 11/Python 3.12。ブラウザ描画・スクロールの1,000件測定とは別。
- 初回sandboxで依存取得/realpath/一時領域が制限され、通常環境で再実行して成功。Starletteのhttpx TestClient非推奨警告あり、テスト失敗ではない。
- Swift全テスト・iOSビルド・シミュレータ・実機は未実行。AWS未作成。継続UI自動テストは未導入。
## Result
ローカルWebを起動して素材管理を試せる状態。起動はscripts/start-web.ps1、準備はsetup-web.ps1、検証はverify-web.ps1。共通契約の生成一致を確認し、iOS接続と実機検証のゲートを文書化。
## Remaining Issues
HEICの画素検証/プレビューとEXIF撮影日時抽出、3D/AI、旧iOS移行・接続、共有メタデータ/認証/同期、AWS移行は未実装。大量ブラウザスクロールと実容量不足は未測定。取り込みは逐次でテストフォルダ追加は同期。Swift新モジュールはMac検証待ち。
