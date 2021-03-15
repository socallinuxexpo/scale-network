#!/usr/bin/env bash
LOGDATE=$(date +%s)
IP=${1:-192.168.254.100}
PORT=${2:-5201}
while :
do
  iperf3 -c $IP -p $PORT -f m -P 2 | tee results-${LOGDATE}.log
  echo "sleeping"
  sleep 10
done
