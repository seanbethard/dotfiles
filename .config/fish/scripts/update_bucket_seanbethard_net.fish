#!/usr/bin/env fish
source $my_config

# make a backup
mkdir CV/(date)
cp CV/aktuell/bethard_cv.pdf CV/(date)
mkdir HTML/(date)
cp HTML/aktuell/index.html HTML/(date)
mkdir key/(date)
cp key/aktuell/pubkey.asc key/(date)
mkdir favicon/(date)
cp favicon/aktuell/favicon.ico favicon/(date)
mkdir vCard/(date)
cp vCard/aktuell/seanbethard.vcf vCard/(date)

# update bucket
cp CV/aktuell/bethard_cv.pdf bucket
cp HTML/aktuell/index.html bucket
cp key/aktuell/pubkey.asc bucket
cp favicon/aktuell/favicon.ico bucket
cp vCard/aktuell/seanbethard.vcf bucket
aws s3 sync bucket "s3://seanbethard.net" \
    --exclude ".DS_Store" \
    --acl public-read

# stop serving stale content
set -lx DIST_ID $(echo $(aws secretsmanager get-secret-value \
    --secret-id seanbethard \
    | jq -r '.SecretString' \
    | jq -r '.cloudfront'))

aws cloudfront create-invalidation --distribution-id $DIST_ID \
    --paths "/bethard_cv.pdf" \
    "/index.html" \
    "/pubkey.asc" \
    "/favicon.ico" \
    "/seanbethard.vcf"

echo "Distribution $DIST_ID is up to date!"
