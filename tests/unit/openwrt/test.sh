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

gen_templates(){
  gomplate -d openwrt=../../../facts/secrets/${TARGET}-openwrt-example.yaml --input-dir=../../../openwrt/files --output-dir="./${1}"
}

if [ "${UPDATE}" == "1" ]; then
  gen_templates "golden/${TARGET}"
fi

gen_templates $TMPLOC

diff -u -r "golden/${TARGET}" $TMPLOC/
