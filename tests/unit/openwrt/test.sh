usage(){
  cat << EOF
usage: $(basename "$0") [OPTIONS] ARGS

Simple test for gomplate generated templates

OPTIONS:
  -h      Show this message
  -t      Target arch to build
  -u      Update golden templates

EXAMPLES:
  Run tests for all templates against existing golden files:

      $(basename "$0")

EOF
}

while getopts "ht:u" OPTION
do
  case $OPTION in
    u )
      UPDATE=1
      ;;
    t )
      TARGET=$OPTARG
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

TARGET=${TARGET:-'ar71xx'}
UPDATE=${UPDATE:-0}

TMPLOC="tmp/${TARGET}"
KEYPATH="../../../facts/keys/"

gen_templates(){
  # Export to support ENV datasource
  export TARGET=$TARGET
  export KEYPATH=$KEYPATH
  gomplate -d openwrt=../../../facts/secrets/${TARGET}-openwrt-example.yaml -d keys_dir=${KEYPATH} --input-dir=../../../openwrt/files --output-dir="./${1}"
}

if [ ${UPDATE} -eq 1 ]; then
  rm -rf "golden/${TARGET}"
  gen_templates "golden/${TARGET}"
fi

gen_templates $TMPLOC

diff -u -r "golden/${TARGET}" $TMPLOC/
