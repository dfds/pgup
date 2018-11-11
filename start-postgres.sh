#!/bin/bash
#
# start a postgres database running in the background

docker run \
    --name postgres \
    --rm \
    -p 5432:5432 \
    -e POSTGRES_USER=postgres \
    -e POSTGRES_PASSWORD=p \
    -d \
    postgres:latest
