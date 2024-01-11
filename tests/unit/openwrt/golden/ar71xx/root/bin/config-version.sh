#!/bin/bash

usage(){
  cat << EOF
usage: "$(basename "$0")" [OPTIONS] ARGS

Set OpenWRT config to specific version

OPTIONS:
  -h      Show this message
  -c      Configuration version

EXAMPLES:
  Print out the current config version
      "$(basename "$0")"

  To set config version 1:
      "$(basename "$0")" -c 1

EOF
}

CONFVER=''
# Current files being managed via this script
FILES=(wireless network)
CONFROOT='/etc/config'
CONFLIST=()

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

build_conflist(){
  local prevver=''
  for file in ${FILES[*]}
  do
    # Make sure existing config is a symlink
    p1=$(readlink $CONFROOT/$file)
    if [ "$?" -eq 0 ]; then
      currver=$(echo $p1 | awk -F. '{print $NF}')
      if [ "$prevver" == '' ] || [ "$prevver" -eq "$currver" ]; then
        CONFLIST+=( "$p1" )
        prevver=$currver
      else
        echo "$CONFROOT/${p1} doesnt match other config versions: ${CONFLIST[@]}"
        exit 1
      fi
    else
      echo "No symlink exists for $CONFROOT/$file"
      exit 1
    fi

    # exit if the target config version doesn't exist
    if [ "$CONFVER" != "" ] && [ ! -f "$CONFROOT/$file.$CONFVER" ]
    then
      echo "no file $CONFROOT/$file.$CONFVER"
      exit 1
    fi
  done
}

build_conflist

# If config ver is not passed then print out current version and exit
if [ "$CONFVER" == "" ]; then
   echo ${CONFLIST[0]} |  awk -F. '{print $NF}'
   exit 0
fi

RELOAD=0

for file in ${FILES[*]}
do
  # create symlinks if the current version isn't active
  if [ ! -L "$CONFROOT/$file" ] || [ ! "$(readlink $CONFROOT/$file)" == "$file.$CONFVER" ]
  then
    rm -f $CONFROOT/$file
    # Keep this link relative since that mirrors how its done during build time
    # subshell also allows us not to worry about pwd
    (cd $CONFROOT && ln -s $file\.$CONFVER $file)
    RELOAD=1
  fi
done

# delay reload until after all symlinks have been created
if [ $RELOAD -eq 1 ]; then
    /etc/init.d/network restart
    /sbin/wifi reload
else
  echo "no change to config symlinks required"
fi
