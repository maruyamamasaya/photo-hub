# 形式バッジの縮小と右下配置
## Request
PNGなどの形式バッジを右下で小さく表示する。
## Investigation
形式バッジ・画像タイトル帯・小画像の寸法表示のCSSを確認。
## Changes
形式バッジをタイトル帯のすぐ上の右下へ移動し、文字を7pxに縮小。寸法表示との重なりと複数選択時の不要な左位置指定を解消。
## Files Changed
- web/src/styles.css
## Validation
Webビルド成功。文書verifyとgit diff --check成功。前のブラウザータブが閉じられており、実画面確認は未実施。
## Result
右下に小さい形式バッジを表示するCSSを反映。
## Remaining Issues
実画面の表示確認。
