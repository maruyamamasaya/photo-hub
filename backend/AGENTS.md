# 署名API領域
- API Gateway JWT検証とOwnerSub照合は本番必須。
- S3キーは本人prefixと正規の写真・バックアップ形状だけを許可する。
- 署名URL、JWT、秘密値をログへ出さない。
- PUTはSHA256とContent-Typeを署名する。写真と正常バックアップは条件付き新規作成、latestポインターだけ更新可能。
- 失敗を成功と返さない。削除は冪等だが、署名PUTが存続中の削除制限はOPERATIONSに記録する。
- 検証は `python3 -m unittest discover -s backend/tests`。
