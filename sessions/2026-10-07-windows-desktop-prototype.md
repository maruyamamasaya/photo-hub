# Windowsアプリ試作
## Request
Mac・Windows設計に沿ってWindowsから開発を開始する。
## Investigation
既存UI、API境界・原本保存・回復、Web起動と検証を確認。Electron公式APIを参照。既存変更は保持。
## Changes
Electronシェル、Python API子プロセス、動的loopbackポート、起動トークン、専用ライブラリ排他、親のstdin切断で停止する経路を追加。OSメニュー、二重起動抑止、起動・検証スクリプトを追加。現Web UIをそのまま表示。
## Files Changed
desktop/、local-api/desktop_run.py、local-api/vault/app.py、local-api/tests/test_desktop.py、scripts/start-desktop.ps1、verify-desktop.ps1。CURRENT、ARCHITECTURE、CODEMAP、TESTING、OPERATIONS、README、設計・運用文書、判断0007、本記録。
## Validation
共通契約生成一致、文書full、ローカルAPI26件、署名API8件、Web型チェック・ビルド、JS構文を確認。Node統合試験で取り込み・原本バイト一致・再起動保持・旧トークン拒否・APIクラッシュ検出を確認。Electronでサムネイル描画と二重起動抑止を確認し、終了。
初回npm取得とVite/Python子プロセスは制限環境で失敗・停止したため通常実行環境で再検証。Windows venvランチャーと実APIのPID差、起動設定送信、終了イベント再入を修正して再確認。
## Result
Windows x64開発用試作を起動可能にした。画面・試験メトリクスは.localへ保存。Electron 43.7.8の展開済みバイナリ約360MiB（Pythonとインストーラーは含まない）。共有UIの原本取得経路を維持。
## Remaining Issues
手操作の一連評価、追加中終了・親強制終了の実機評価、大規模描画、標準保存領域への移行、native保存連携、起動中画面、Python同梱・署名・インストーラー・Mac検証は後工程。正式採用は未確定。
