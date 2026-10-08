# S3バックアップ料金の確認
## Request
すぐ取得できるS3バックアップの料金を知りたい。
## Investigation
AWS公式料金ページ、ストレージクラス資料、公開料金APIで東京リージョンを確認。Standardは0.025 USD/GB月、Standard-IAは0.0138、Glacier Instant Retrievalは0.005。IA取得は0.01 USD/GB、Instant Retrieval取得は0.03。
## Changes
調査記録のみ。AWS構成・実装変更なし。
## Files Changed
この記録。
## Validation
公式公開料金APIの東京リージョンの値を取得。コード変更なしのためテスト未実行。
## Result
即時取得できる3クラスの保存費用と取得費用を比較。保存料金とは別に通信・リクエスト料金が必要。
## Remaining Issues
容量、取得頻度、月間ダウンロード量が未確定。円換算は例示用の仮定レートを使用。
