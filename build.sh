#!/bin/sh

export JEKYLL_VERSION=3.8
docker run --rm --volume=$PWD:/srv/jekyll -i jekyll/jekyll:$JEKYLL_VERSION jekyll build $@
