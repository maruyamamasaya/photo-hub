# 段階1: 設計案

## 目的と範囲
個人のiPhone一台で使うSwiftUI写真管理。iOS 17以上。動画、Live Photoの動画部分、RAW、複数端末同期、共有、AI検索、顔認識、App Store公開は初期範囲外。JPEG / HEIC / PNGの静止画を対象とする。

## 画面と操作
- 写真: 撮影日時の新しい順の3列グリッド、複数取り込み、状態表示。
- 詳細: 左右ページ送り、ピンチ拡大、お気に入り、アルバム追加、原本保存、削除確認。
- アルバム: 作成、写真追加・取り外し。
- 設定: 本人認証、アップロード再試行、キャッシュ上限、JSONバックアップ・復元。

取り込みはPHPickerで選び、PhotoKitの許可を得た選択資産の `.photo` リソースをファイルへ書き出す。原本のバイト列を加工しない。HEICは原本をそのまま保管し、表示用とサムネイルだけJPEGへ変換する。編集済み画像を原本と偽らない。ライブラリ権限がない・選択資産を参照できない場合は説明して失敗させる。

## SQLite選定
OS標準SQLite3を小さなRepositoryで包む。追加ライブラリの取得・更新・互換性維持が不要で、SQLとトランザクションを明示できる。GRDBも候補だが、初期の小規模スキーマには依存を増やさない。全DB操作をメインアクターに限定し、画像I/Oとネットワークは非同期に行う。大量データで遅延した場合は専用actorへ移す判断を別途記録する。

写真: UUID、撮影日時、取込日時、元ファイル名、形式、SHA256、原本サイズ、画素数、original/thumbnail/displayのキー、アップロード状態、エラー、お気に入り、削除状態。
アルバム: UUIDと名前。所属: albumID/photoIDの複合主キー。画像本体はSQLiteに入れない。

## オブジェクトと状態
`users/{Cognito sub}/photos/{photo UUID}/original`、`thumbnail.jpg`、`display.jpg`。元の形式・ファイル名はメタデータへ保存。キーは再試行でも同一。期限付きURLは永続化しない。

原本はApplication Supportのpendingへ保存し、JPEGサムネイル512px・表示用2048pxを生成。pending → uploading → uploadedまたはfailed。PUT成功だけで完了にせず、全3オブジェクトのHEADによるサイズ・SHA256照合後にuploadedへ遷移。起動時uploadingをpendingへ戻す。既存一致オブジェクトは再PUTしない。元ライブラリからの重複は資産IDと原本SHA256で防ぐ。

削除は確認後にdeleting状態をSQLiteに記録し、S3の3オブジェクトを冪等に削除してからSQLiteとローカルコピーを削除。通信中断時はdeletingが残り再試行する。AWSではS3 tombstoneを先に作って新規署名を禁止し、既存の5分署名PUTの失効を待つ6分後に削除を再試行する。iPhoneの写真ライブラリは削除しない。

## AWSと認証
東京 ap-northeast-1。非公開S3 Standard、Block Public Access、SSE-S3、TLS強制。API Gateway HTTP API + Python Lambda。Cognito User Poolの自己登録禁止、管理者が本人一人を登録。ネイティブ公開クライアント（client secretなし）、Hosted UI Authorization Code + PKCE S256。API Gateway JWT検証に加えLambdaは設定済みOwnerSubとsubを照合。クライアント指定の任意キーは受けず、IDと種類からサーバー側で生成。IAMも本人prefixだけ許可。

署名URLは5分。有効期限後は再発行。AWS長期秘密鍵はアプリに入れない。API未設定時でもローカル機能を使えるが、クラウド処理はエラーを表示し認証を無効化しない。

## キャッシュと原本管理
thumbnail/displayはCaches配下、既定512MBのLRU。削除されてもS3から再取得可能。pending原本はキャッシュではなく未送信データ。uploaded確認後、ユーザーの容量解放操作で原本コピーを削除可能。iOS写真ライブラリの原本は別途ユーザー自身で管理するため、アプリだけで端末全体の写真容量を自動削減できるわけではない。

## バックアップと復元
schemaVersion=1のJSON: 写真、アルバム、所属、お気に入り、安定したキーとチェックサム。トークン・署名URL・画像本体・キャッシュパスは含めない。未送信原本はクラウドJSONから復元できないため、クラウドバックアップ前はアップロード・削除を完了させる。

時刻とUUID付き `users/{sub}/backups/{UUID}.json` をPUT、HEAD検証し、最新版を指す `backups/latest.json` を最後に更新。古い正常版は残す（初期版は自動削除せず、料金に含める）。空のSQLiteへバージョン・ID・所属整合性を検証してトランザクション復元。本人prefixはログイン中のsubと照合。欠損オブジェクトは閲覧時にエラーとして示し、勝手に消さない。バックアップ以降の変更は復元されない。復元前にこの点を表示する。

## 費用概算（2026-10-07確認）
S3東京の参照単価: Standard $0.025/GB月、PUT $0.0047/1000、GET $0.00037/1000。料金は使用量と転送で変動し、作成直前にAWS見積もりで再確認する。

- 総量100GB（原本・派生・JSON込み）: 約$2.50/月。
- 原本100GB + 25,000枚×(サムネイル50KB+表示500KB) + JSON保持0.1GB: 約113.85GB、約$2.85/月。
- 100枚/日を3オブジェクトPUT: 月9,000 PUTで約$0.042、100閲覧/日×2 GET: 月6,000 GETで約$0.0022。確認HEADもGET料金、バックアップと再試行は別途。
- API Gateway/Lambda/Cognito/CloudWatchは小規模でも無料枠を保証せず、概算の予備費$1/月を加える。概ね$3–5/月を開始時の目安とする。
- 100回/日×500KB表示は約1.5GB/月。100回/日×4MB原本なら約12GB/月。インターネット転送無料枠はAWSアカウント全体で共有されるため、超過時は東京の転送料金を追加。
- 大量初期取込・全原本復元、100枚/日による保存量増加（4MBなら約12GB/月）、古いJSON保持による増加を別途計上する。
- 円換算は仮に$1=150円なら約450–750円/月（為替・税別の仮定）。Apple Developer Program費はAWS費用に含まない。

料金出典: [S3](https://aws.amazon.com/s3/pricing/)、[API Gateway](https://aws.amazon.com/api-gateway/pricing/)、[Lambda](https://aws.amazon.com/lambda/pricing/)、[Cognito](https://aws.amazon.com/cognito/pricing/)。

## 実機利用
Xcodeでプロジェクトを開き、Signing Teamと一意のBundle IDを設定。iPhoneを接続してDeveloper Modeを有効化し実行。Personal Teamは7日でプロファイルが期限切れとなるため再インストールが必要。長期利用はDeveloper Programでの開発配布を検討。アプリ削除はローカルDBとpending原本を失うため、正常なクラウドバックアップを確認してから行う。

[Appleのアカウント説明](https://developer.apple.com/help/account/basics/about-your-developer-account)、[PhotoKitの原本リソース](https://developer.apple.com/documentation/photos/phassetresourcemanager)、[Cognito PKCE](https://docs.aws.amazon.com/cognito/latest/developerguide/authorization-endpoint.html)、[S3 checksum](https://docs.aws.amazon.com/AmazonS3/latest/userguide/checking-object-integrity.html)。
