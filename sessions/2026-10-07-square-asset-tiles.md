# 素材一覧の正方形タイル
## Request
一覧を正方形にし、間隔を詰め、タイトルを半透明レイヤー上で画像に重ねる。
## Investigation
AssetCardの画像比率と画像外のタイトル・タグ領域を確認した。
## Changes
画像を1:1にし、タイトルとタグを画像下部へ重ねた。背景は半透明とぼかしを使用。間隔は8px、狭い画面では6pxとした。
## Files Changed
- web/src/App.tsx
- web/src/styles.css
## Validation
- npm run build成功。
- 実ブラウザーでタグ有無のカードが178.5px四方で同じ行位置に並ぶことを確認。
- 幅390pxでも166.5px四方の2列表示を確認。
## Result
密度の高い正方形一覧になり、タグによるカード寸法の差をなくした。
## Remaining Issues
iOS実機確認は未実施。
