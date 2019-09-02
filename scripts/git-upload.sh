#!/bin/bash

owner=${1}
repo=${2}
version=${3}
asset=${4}
token=$(git config --global github.token)

echo "Uploading asset ${asset} to ${version}"

upload_url=$(curl -s "https://api.github.com/repos/${owner}/${repo}/releases/tags/${version}" | \
    grep "upload_url"  | \
    cut -d '"' -f 4 | \
    sed -e "s/{?name,label}//")

curl --netrc \
    --header "Content-Type:application/gzip" \
    --header "Authorization: token ${token}" \
    --data-binary "@${asset}" \
    "${upload_url}?name=$(basename "${asset}")"

