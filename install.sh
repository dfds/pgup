#!/bin/bash

path="_db"

[[ -d ${path} ]] && echo "${path} already exists, aborting..." && exit 1

echo "Installing database migration "


mkdir -p _db/{migrations,seed}

# mktemp -d -t ci-XXXXXXXXXX