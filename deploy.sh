#!/bin/sh

aws s3 sync _site/ s3://dag-aftenskolen.dk --content-type "text/html; charset=utf-8" --delete --exclude "*.sh" $@
aws s3 cp _site/assets/css/main.css s3://dag-aftenskolen.dk/assets/css/main.css $@
