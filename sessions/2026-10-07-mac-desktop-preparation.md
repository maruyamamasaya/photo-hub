# Macアプリ試作の準備
## Request
Mac実機で確認できる前にMac版も作っておく。
## Investigation
現デスクトップのWindows固定Pythonパスと終了動作、POSIX対応済みAPIロック、共通検証・運用を確認。Electron公式のMac lifecycle/menuを参照。
## Changes
OS別Pythonパスとメニューを追加。Macではウィンドウを閉じてもAPIを維持しactivate/二重起動で再表示、QuitでAPI停止する。Mac用setup/start/verifyのシェルを追加。smokeのprofileを通常試作から独立。Mac実機確認項目と起動手順を記録。
## Files Changed
desktop/main.cjs、api-process.cjs、api-process.test.cjs、platform.cjs、platform.test.cjs、mac-lifecycle.test.cjs、package.json。scripts/setup-desktop.sh、start-desktop.sh、verify-desktop.sh。CURRENT、ARCHITECTURE、CODEMAP、TESTING、OPERATIONS、README、docs/DESKTOP-DESIGN.md、DESKTOP-OPERATIONS.md、本記録。
## Validation
WindowsでJS構文、Node統合/OS分岐/Mac模擬イベントの3テストを通過。Electronの共通UI描画と二重起動を再確認。Git Bashでシェル3本の構文を確認。文書fullと差分空白を確認。Mac上のsetup・起動・APIロック・Cmd/Dock・画面操作は未実行。
## Result
Macで依存を準備して開発用試作を起動する入口と、OS固有のウィンドウ動作を実装。UIはWindows/Webと共通。
## Remaining Issues
Mac実機でarm64/必要ならIntel確認、Finder追加と原本保存、Retina/VoiceOver、容量不足と中断回復を確認する。配布用.app/DMG、Python同梱、署名・公証は未実装。
