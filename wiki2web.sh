#!/bin/bash

set -uo pipefail
trap cleanup SIGINT SIGTERM ERR EXIT

# wiki2web
#
# converts a vim wiki from markdown to html then moves those files somewhere else 
# uses markdown from discount: http://pell.portland.or.us/~orc/Code/discount/
#
# vim wiki settings:
# vim.g.vimwiki_list = {{
#   syntax = 'markdown',
#   ext = '.md'
# }}

script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd -P)

usage() {
  cat <<EOF
Usage: $(basename "${BASH_SOURCE[0]}") [-h] [-v] -o output_dir -s source_wiki

Script description here.

Available options:

-h, --help      Print this help and exit
-v, --verbose   Print script debug info
-o, --out       Output directory for files
-s, --source    VimWiki source folder
EOF
  exit
}

cleanup() {
  trap - SIGINT SIGTERM ERR EXIT
  # script cleanup here
}

setup_colors() {
  if [[ -t 2 ]] && [[ -z "${NO_COLOR-}" ]] && [[ "${TERM-}" != "dumb" ]]; then
    NOFORMAT='\033[0m' RED='\033[0;31m' GREEN='\033[0;32m' ORANGE='\033[0;33m' BLUE='\033[0;34m' PURPLE='\033[0;35m' CYAN='\033[0;36m' YELLOW='\033[1;33m'
  else
    NOFORMAT='' RED='' GREEN='' ORANGE='' BLUE='' PURPLE='' CYAN='' YELLOW=''
  fi
}
setup_colors

msg() {
  echo >&2 -e "${1-}"
}

die() {
  local msg=$1
  local code=${2-1} # default exit status 1
  msg "$msg"
  exit "$code"
}

parse_params() {
  # default values
  out=''
  source=''

  while :; do
    case "${1-}" in
    -h | --help) usage ;;
    -v | --verbose) set -x ;;
    --no-color) NO_COLOR=1 ;;
    -f | --flag) flag=1 ;; # example flag
    -s | --source) 
      source="${2-}"
      shift
      ;;
    -o | --out) 
      out="${2-}"
      shift
      ;;
    -?*) die "Unknown option: $1" ;;
    *) break ;;
    esac
    shift
  done

  args=("$@")

  [[ -z "${source-}" ]] && die "${RED}-x- ${NOFORMAT}Missing required parameter: source"
  [[ -z "${out-}" ]] && die "${RED}-x- ${NOFORMAT}Missing required parameter: out"

  return 0
}

parse_params "$@"

# clean up dist folder
if cd $out ; then
  if rm -rf * ; then
    msg "${GREEN}-✓- ${NOFORMAT}output directory ${out} cleared"
  fi
fi

# make some webpages
for file in $source/*.md $source/**/*.md; do
  if [[ -f $file ]]; then
    tfn="${file##*/}"
    title="${tfn%%.md}"

    nf="${file%%.md}.html"
    
    cat $script_dir/header.tpl > "$nf"
    markdown "$file" >> "$nf"
    cat $script_dir/footer.tpl >> "$nf"

    perl -pi -e "s/_title_/${title}/" "$nf"
    perl -pi -e 's/<a href="([^@]*?)"/<a href="$1\.html"/g' "$nf"
  fi
done

# archive the pages
cd $source
find . -name "*.html" | tar -cjf ~/sitehtml.tar.bz2 -T- &>/dev/null
rm -r *.html

# unpack them at their destination
mv ~/sitehtml.tar.bz2 $out
cd $out
tar -xjvf sitehtml.tar.bz2 &>/dev/null
rm sitehtml.tar.bz2
