#!/bin/bash

function usage() {
cat <<_EOT_
check-ssl-cipher-suite.sh

Usage:
  check-ssl-cipher-suite.sh https://<URL>

Description:
  Check supported SSL cipher suite of specified URL.

Options:
  -h    Show this help message and exit

_EOT_
exit 1
}

while getopts h OPT
do
  case $OPT in
    h)
      usage
      ;;
    \?)
      echo "Try to enter the h option." 1>&2
      exit 1
      ;;
  esac
done
shift $((OPTIND - 1))


if [ $# -ne 1 ]; then
  usage
else
  URL=$1
fi

declare -a CIPHERS=($(openssl ciphers -v | awk '{print $1}'))
declare -a TLS_VERSIONS=("1.0" "1.1" "1.2" "1.3")

echo "Checking ${URL} ..."
for TLS_VERSION in ${TLS_VERSIONS[@]}
do
  echo "===== ${TLS_VERSION} ====="
  for CIPHER in ${CIPHERS[@]}
  do
    curl $URL --tls-max $TLS_VERSION --ciphers $CIPHER > /dev/null 2>&1
    if [ $? -eq 0 ]; then
      echo "$CIPHER, OK"
    else
      echo "$CIPHER, NG"
    fi
  done
  echo ""
done
