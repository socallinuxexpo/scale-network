usage(){
  cat << EOF
usage: $(basename "$0") [OPTIONS] ARGS

Simple test for gomplate generated templates

OPTIONS:
  -h      Show this message
  -o      specify output for temporary generated templates
  -t      Target arch to build
  -u      Update golden templates (no test)

EXAMPLES:
  Run tests for all templates against existing golden files:

      $(basename "$0")

EOF
}

while getopts "ho:t:u" OPTION
do
  case $OPTION in
    u )
      UPDATE=1
      ;;
    t )
      TARGET=$OPTARG
      ;;
    o )
      OUTPUT=$OPTARG
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
shift $((OPTIND -1))

TARGET=${TARGET:-'ath79'}
UPDATE=${UPDATE:-0}

TMPLOC="${OUTPUT:-.}/tmp/${TARGET}"
KEYPATH="../../../facts/keys/"

gen_templates(){
  # Export to support ENV datasource
  export TARGET=$TARGET
  export KEYPATH=$KEYPATH
  rm -rf "${1}"
  gomplate -d openwrt=../../../facts/aps/${TARGET}-openwrt-example.yaml -d keys_dir=${KEYPATH} --input-dir=../../../openwrt/files --output-dir="${1}"
  if [ -d ../../../openwrt/files-${TARGET} ]; then
    gomplate -d openwrt=../../../facts/aps/${TARGET}-openwrt-example.yaml -d keys_dir=${KEYPATH} --input-dir=../../../openwrt/files-${TARGET} --output-dir="${1}"
  fi
}

if [ ${UPDATE} -eq 1 ]; then
  gen_templates "golden/${TARGET}"
else
  gen_templates "$TMPLOC"
  diff -u -r "golden/${TARGET}" $TMPLOC/
fi

