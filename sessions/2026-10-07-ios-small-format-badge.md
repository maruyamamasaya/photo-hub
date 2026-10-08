# iOS形式バッジの右下表示
## Request
Web同様、iOSにも小さい形式バッジを右下に追加する。
## Investigation
PhotoGridのタイトル帯とPhoto.mimeを確認。追加のデータ項目は不要。
## Changes
原本MIMEからPNG/JPEGなどのラベルを表示。基準7ptでDynamic Typeに対応。タイトル帯直上の右下に配置し、帯の高さが変わっても重ならない構造にした。タイル操作を妨げない。
## Files Changed
- ios/PhotoHub/Views.swift
## Validation
文書verifyとgit diff --check成功。Swift/XcodeのないWindows環境のためiOSビルド・Integration・実機確認は未実行。
## Result
iOSの通常一覧・アルバム一覧に共通の形式バッジを追加。
## Remaining Issues
Mac/iPhoneで表示とDynamic Typeを確認する。
