#!/bin/sh

aws s3 sync _site/ s3://$BUCKET --content-type "text/html; charset=utf-8" --delete --cache-control "max-age=0" --exclude "*.sh" $@
aws s3 cp _site/assets/css/main-2019.css s3://$BUCKET/assets/css/main-2019.css --content-type="text/css" $@
aws cloudfront create-invalidation --distribution-id $DISTRIBUTION_ID --paths /\* $@
