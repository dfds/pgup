FROM alpine:latest

RUN apk --update add postgresql-client ca-certificates \
    && rm -rf /var/cache/apk/* \
    && wget https://truststore.pki.rds.amazonaws.com/global/global-bundle.pem -O /tmp/rds-combined-ca-bundle.pem \
    && mv /tmp/rds-combined-ca-bundle.pem /usr/local/share/ca-certificates/rds-combined-ca-bundle.crt \
    && update-ca-certificates

# Default environment settings
ENV PGSSLROOTCERT /etc/ssl/certs/ca-certificates.crt
ENV PGSSLMODE=verify-full
ENV PGPORT=5432
ENV MIGRATION_TIMEOUT=1s
ENV MIGRATION_TABLE_NAME="_migrations"
ENV MIGRATION_DB_FOLDER="/db"
ENV MIGRATION_SCRIPT_LOCATION="/tmp/script.sql"
ENV SEED_CSV_SEPARATOR=","

WORKDIR /

COPY init.sh ./
RUN chmod +x init.sh
ENTRYPOINT [ "./init.sh" ]
