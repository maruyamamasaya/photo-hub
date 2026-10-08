# タグ付き素材カードの整列
## Request
Webのタグ有無によるレイアウトのずれを確認・修正する。
## Investigation
実ブラウザで同じ行の画像上端が13pxずれていた。タグ付きカードに合わせた行の高さと、button内部の中央配置が原因。
## Changes
カード内部を縦flexの上揃えに変更。全カードに高さ20pxのタグ欄を確保し、長いタグは省略表示とtitleで扱う。
## Files Changed
web/src/App.tsx、web/src/styles.css、本記録。
## Validation
Web型チェック・ビルド成功。ブラウザ再読み込み後、同じ行の画像上端297px、カード高さ263.0625px、タグ欄20pxが一致。文書verifyと空白チェックを実施。
## Result
タグ有無で画像・カードの並びがずれなくなった。
## Remaining Issues
iOS実機は対象外。
