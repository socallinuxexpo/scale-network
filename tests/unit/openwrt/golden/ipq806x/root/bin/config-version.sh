#!/bin/bash

usage(){
  cat << EOF
usage: "$(basename "$0")" [OPTIONS] ARGS
Set OpenWRT config to specific version
OPTIONS:
  -h      Show this message
  -c      Configuration version [default: 0]
EXAMPLES:
  To set config version 1:
      "$(basename "$0")" -c 1
EOF
}

CONFVER=0
FILES=(wireless network)
CONFROOT='/etc/config'

while getopts "h:c:" OPTION
do
  case $OPTION in
    c )
      CONFVER=$OPTARG
      ;;
    h )
      usage
      exit 0
      ;;
    \? )
      usage
      exit 1
      ;;
  esac
done
shift $((OPTIND-1))

RELOAD=0

for file in ${FILES[*]}
do
  # exit if the target version doesn't exist
  if [ ! -f "$CONFROOT/$file.$CONFVER" ]
  then
    echo "no file $CONFROOT/$file.$CONFVER"
    exit 1
  fi
  # create symlinks if the current version isn't active
  if [ ! -L "$CONFROOT/$file" ] || [ ! "$(readlink $CONFROOT/$file)" = "$CONFROOT/$file.$CONFVER" ]
  then
    rm -f $CONFROOT/$file
    ln -s $CONFROOT/$file\.$CONFVER $CONFROOT/$file
    RELOAD=1
  fi
done

# delay reload until after all symlinks have been created
if [ $RELOAD -eq 1 ]; then
    /etc/init.d/network restart
    /sbin/wifi reload
fi
