#!/bin/sh

JEKYLL_VERSION=3.5
docker run --rm --volume=$PWD:/srv/jekyll -it jekyll/jekyll:$JEKYLL_VERSION jekyll build $@

find _site -name "*.html" | xargs recode utf8..iso88591
