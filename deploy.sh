#!/bin/sh

aws s3 sync _site/ s3://dag-aftenskolen.dk --content-type "text/html; charset=utf-8" --delete --cache-control "max-age=0" --exclude "*.sh" $@
aws s3 cp _site/assets/css/main-2019.css s3://dag-aftenskolen.dk/assets/css/main-2019.css --content-type="text/css" $@
aws cloudfront create-invalidation --distribution-id EO900804BMV13 --paths /\* $@
