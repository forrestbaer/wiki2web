#!/bin/bash

set -Eeuo pipefail

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

# settings
out=~/web/public
wiki=~/wiki

script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd -P)

# clean up dist folder
cd $out
rm -rf *

# make some webpages
for file in $wiki/*.md $wiki/**/*.md; do
  tfn="${file##*/}"
  title="${tfn%%.md}"

  nf="${file%%.md}.html"

  sed "s/_title_/${title}/" $script_dir/default.template > "$nf"
  sed -i "s|_content_|markdown '${file}'|e" "$nf"
  sed -i 's/<a href="\([^mailto].*\)"/<a href="\1\.html"/g' "$nf"
done

# archive the pages
cd $wiki
find . -name "*.html" | tar -cjf ~/sitehtml.tar.bz2 -T-
rm -r *.html

# unpack them at their destination
mv ~/sitehtml.tar.bz2 $out
cd $out
tar -xjvf sitehtml.tar.bz2
rm sitehtml.tar.bz2
