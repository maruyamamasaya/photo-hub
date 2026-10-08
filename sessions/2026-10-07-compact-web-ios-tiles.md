# WebとiOSのコンパクトな一覧
## Request
タイトルを小さくし、タグを保持したまま一覧では非表示にする。iOSにも一覧の表示方針を反映する。
## Investigation
WebのAssetCard、既存iOSのPhotoGridとPhotoImageを確認。iOSは旧Photoモデルのまま。
## Changes
Webタイトルを10pxにし、タグ表示を除去。詳細編集と検索・保存は維持。iOSは正方形3列・6pt間隔とし、基準10ptの名前を半透明帯に表示。Dynamic Typeに対応し、状態とお気に入りを右上へ配置。
## Files Changed
- web/src/App.tsx
- web/src/styles.css
- ios/PhotoHub/Views.swift
- docs/IOS-WEB-CONTRACT.md
## Validation
Webビルド成功。実ブラウザーで10pxタイトル・タグDOMなし・正方形カードを確認。文書verifyとgit diff --check成功。
## Result
一覧をコンパクト化し、iOS側にも表示方針を反映した。
## Remaining Issues
WindowsにSwift/Xcodeがなく、iOSビルド・Integration・実機確認は未実行。Web/iOSのAPI接続は既存の別工程。
