#!/bin/bash

docker build -t db .

docker run -it --rm \
    -e PGDATABASE=teamservice \
    -e PGHOST=localhost \
    -e PGPORT=5432 \
    -e PGUSER=postgres \
    -e PGPASSWORD=p \
    db
