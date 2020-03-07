#!/usr/bin/env bash

DOWN=()
UP=()

tally_down(){
  DOWN+=($1)
  echo "Can't ping $1"
}

tally_up(){
  UP+=($1)
}

LIST=($(cd ../../../ansible && python3 inventory.py | jq -r .aps[][]))
#LIST=("upconf-3" "upconf-4")
for i in "${LIST[@]}"
do
  ping -c 1 -W 1 -q $i > /dev/null 2>&1
  if [ "$?" -eq "0" ]; then
    tally_up $i
    if [ ! -z $1 ] && [ -f $1 ]; then
      cat $1 |ssh root@$i -o StrictHostKeyChecking=no /bin/bash
    fi
  else
    tally_down $i
  fi
done

echo "------"
echo "Down list: ${DOWN[@]}"
echo "Down total: ${#DOWN[@]}"
echo "------"
echo "Up list: ${UP[@]}"
echo "Up total: ${#UP[@]}"
