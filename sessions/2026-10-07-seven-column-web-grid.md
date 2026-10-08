# Web一覧の最大7列表示
## Request
5列までのサイズ感を維持し、広い画面では最大7列にする。
## Investigation
1450px以上を5列固定にしていたCSSとコンテンツ幅上限を確認。
## Changes
既存5列以下の指定は維持。1700px以上を6列、1950px以上を7列にし、7列時のコンテンツ幅上限を1900pxへ拡張。
## Files Changed
- web/src/styles.css
## Validation
Webビルド成功。実ブラウザーで1450/1699pxは5列、1700/1949pxは6列、1950/2560pxは7列を確認。列追加直後のタイル幅は約224/227px。文書verifyとgit diff --check成功。
## Result
広い画面ではタイルを小さくしすぎず、最大7列まで表示する。
## Remaining Issues
なし。
