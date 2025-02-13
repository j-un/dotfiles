#!/bin/bash

function usage() {
  cat <<EOS
Usage: $0
 [ -r <region>]
 [ -p <profile>]
 [ -h]
EOS
  exit 1
}

REGION='ap-northeast-1'

while getopts p:r:h OPT; do
  case $OPT in
    p) PROFILE="--profile $OPTARG" ;;
    r) REGION="$OPTARG" ;;
    h) usage ;;
    ?) usage ;;
  esac
done

for INSTANCE in $(aws lightsail get-instances --query 'instances[].name' --output text --region $REGION $PROFILE)
do
  echo === $INSTANCE ===
  aws lightsail get-auto-snapshots --resource-name $INSTANCE --query 'autoSnapshots[0]' --output table --region $REGION $PROFILE
  echo ""
done

