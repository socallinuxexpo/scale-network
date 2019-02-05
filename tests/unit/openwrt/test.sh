usage(){
  cat << EOF
usage: $(basename "$0") [OPTIONS] ARGS

Simple test for gomplate generated templates

OPTIONS:
  -h      Show this message
  -u      Update golden templates

EXAMPLES:
  Run tests for all templates against existing golden files:

      $(basename "$0")

EOF
}

while getopts "hu" OPTION
do
  case $OPTION in
    u )
      UPDATE=1
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

UPDATE=${UPDATE:-0}

TMPLOC="tmp"

gen_templates(){
  gomplate -d openwrt=../../../facts/secrets/openwrt.yaml --input-dir=../../../openwrt/files --output-dir="./${1}"
}

if [ "${UPDATE}" == "1" ]; then
  gen_templates golden
fi

gen_templates $TMPLOC

diff -r golden/ $TMPLOC/
