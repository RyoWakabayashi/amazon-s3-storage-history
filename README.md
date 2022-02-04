# amazon-s3-storage-history

Amazon S3 のストレージ容量履歴を取得する

バケット名と、当日から遡って取得する日数を指定する

## Python 版

- 必要な環境

  Python3

- パッケージインストール

  ```bash
  pip install --requirement requirements.txt
  ```

- 実行

  ```bash
  python get_s3_storage_history.py -b <バケット名> -d <日数>
  ```

- 出力結果

  s3_storage.csv

## シェルスクリプト版

- 必要な環境

  - aws cli
  - jq

- 実行

  ```bash
  ./get_s3_storage_history.sh -b <バケット名> -d <日数>
  ```

- 出力結果

  s3_storage.csv
