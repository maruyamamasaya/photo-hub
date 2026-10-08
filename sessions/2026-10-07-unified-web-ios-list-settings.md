# WebとiOSの統合設定アイコン
## Request
フィルターと並び替えを1つのアイコン・ポップアップにまとめ、iOSも同じ操作にする。
## Investigation
Webの2つの設定モーダルとiOSのPhotoGrid、旧Photoの利用可能な項目を確認。
## Changes
Webは設定アイコン1個で全条件と並び替えを表示。読み上げ名とツールチップを付け、押す領域は44pxを維持。iOSは同じ設定アイコンと統合シートを追加し、拡張子・お気に入りと4項目の昇降順に対応。
## Files Changed
- web/src/App.tsx, styles.css
- ios/PhotoHub/Views.swift
- docs/IOS-WEB-CONTRACT.md
## Validation
Webビルド成功。実ブラウザーで統合ポップアップ内のPNGフィルター・タイトル昇順を設定し4件表示、解除を確認。文書verifyとgit diff --check成功。
## Result
Webの操作欄は複数選択と設定アイコンの2つに集約。iOSも設定を1つのシートに集約。
## Remaining Issues
Windows環境のためiOSビルド・Integration・実機確認は未実行。旧Photoにはタグ・種別・更新日がなく、共通API接続工程で対応する。
