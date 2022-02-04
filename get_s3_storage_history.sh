#!/bin/bash
# -- get_s3_storage_history.sh ----------------------------------------------------------------
#
# Amazon S3 の容量履歴を取得するスクリプト
#
# Copyright (c) 2022 Ryo Wakabayashi
#
# ------------------------------------------------------------------------------

set -uo pipefail

readonly ME=${0##*/}

display_usage() {

    cat <<EOE

    Amazon S3 の容量履歴を取得するスクリプト

    構文: ./${ME} -b <バケット名> -d <日数>

EOE

    exit

}

check_sanity() {

    [[ $(command -v aws) ]] \
        || whoopsie "Please install aws cli first."

    [[ $(command -v jq) ]] \
        || whoopsie "Please install jq first."

    echo 'All checks(sanity) passed...'

}

get_history() {

    backet_name=$1
    days=$2

    end_date=$(date +"%Y-%m-%d")
    start_date=$(date -v -"$days"d +"%Y-%m-%d")

    echo "Date,Bytes" | tee "s3_storage.csv"

    aws cloudwatch get-metric-statistics \
        --namespace AWS/S3 \
        --metric-name BucketSizeBytes \
        --dimensions \
            Name=StorageType,Value=StandardStorage \
            Name=BucketName,Value="$backet_name" \
        --statistics Maximum \
        --start-time "$start_date"T00:00:00Z \
        --end-time "$end_date"T00:00:00Z \
        --period 86400 \
        --unit Bytes \
        | jq -r '
            .Datapoints
            | sort_by(.Timestamp)
            | .[]
            | [(.Timestamp|strptime("%Y-%m-%dT%H:%M:%SZ")|strftime("%Y/%m/%d")), .Maximum]
            | @csv
        ' \
        | tee -a "s3_storage.csv"

}

main() {

    local backet_name=''
    local days=''

    [[ $# -eq 0 ]] && display_usage

    while getopts b:d:h opt; do
        case $opt in
            h)
                display_usage
            ;;
            b)
                backet_name=$OPTARG
            ;;
            d)
                days=$OPTARG
            ;;
            \?)
                whoopsie "Invalid option!"
            ;;
        esac
    done

    shift $((OPTIND-1))

    [[ $# -gt 0 ]] \
        && display_usage

    check_sanity

    get_history "${backet_name}" "$days"

}

whoopsie() {

    local message=$1

    echo "${message} Aborting..."
    exit 192

}

main "$@"

exit 0
