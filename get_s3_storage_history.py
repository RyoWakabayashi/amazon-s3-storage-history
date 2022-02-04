import datetime
from argparse import ArgumentParser

import boto3
import pandas as pd


def parse_args():
    """
    引数パース
    """
    argparser = ArgumentParser()
    argparser.add_argument(
        "-b",
        "--bucket-name",
        help="S3 bucket name",
    )
    argparser.add_argument(
        "-d",
        "--days",
        type=int,
        help="Number of days",
    )
    return argparser.parse_args()


def main(bucket_name, days):
    """
    メイン処理
    """

    client = boto3.client("cloudwatch")

    # 今日の0時0分
    today = datetime.datetime.today().replace(hour=0, minute=0)

    # 集計単位は1日
    period = 24 * 60 * 60

    dimensions = [
        {"Name": "StorageType", "Value": "StandardStorage"},
        {"Name": "BucketName", "Value": bucket_name},
    ]

    statistics = client.get_metric_statistics(
        Namespace="AWS/S3",
        MetricName="BucketSizeBytes",
        Dimensions=dimensions,
        StartTime=today - datetime.timedelta(days=days),
        EndTime=today,
        Period=period,
        Statistics=["Maximum"],
    )

    df = pd.DataFrame(statistics["Datapoints"])

    # 並べ替え
    df = df.sort_values("Timestamp").reset_index()
    # 日付形式変更
    df["Timestamp"] = df["Timestamp"].dt.strftime("%Y/%m/%d")
    df["Maximum"] = df["Maximum"].astype(int)
    # 不要な項目を消してヘッダの修正
    df = df[["Timestamp", "Maximum"]]
    df.columns = ["Date", "Bytes"]

    print(df)

    df.to_csv("s3_storage.csv", index=False)


if __name__ == "__main__":
    ARGS = parse_args()
    main(ARGS.bucket_name, ARGS.days)
