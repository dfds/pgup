#!/bin/sh
#
# Run the Postgres database migrations as well as seeding the database

[[ -n "${DEBUG}" ]] && set -o xtrace

readonly GREEN="\\033[32m"
readonly RESET="\\033[0m"
readonly PSQL="psql --no-psqlrc $([[ -n "${DEBUG}" ]] && echo "--echo-all" || echo "--quiet") --set ON_ERROR_STOP=1 --pset pager=off"

set -o nounset
set -o errexit

##############################################################################
# wait for database to come online
# Globals:
#   PGHOST
#   PGPORT
#   MIGRATION_TIMEOUT
# Arguments:
#   None
# Returns:
#   None
##############################################################################
wait_for_database() {
    until pg_isready --quiet --host=${PGHOST} --port=${PGPORT}; do
        echo "postgres is unavailable - waiting ${MIGRATION_TIMEOUT}..."
        sleep ${MIGRATION_TIMEOUT}
    done

    echo "postgres is up - preparing database migrations"
}

##############################################################################
# Create database (dropping if needed) for local development
# Globals:
#   LOCAL_DEVELOPMENT
#   PGDATABASE
#   PSQL
#   GREEN
#   RESET
# Arguments:
#   None
# Returns:
#   None
##############################################################################
create_database() {
    if [[ -n "${LOCAL_DEVELOPMENT:+set}" ]]; then
        echo -e "Creating database ${GREEN}${PGDATABASE}${RESET}..."
        ${PSQL} --dbname=postgres --command="DROP DATABASE IF EXISTS ${PGDATABASE};"
        ${PSQL} --dbname=postgres --command="CREATE DATABASE ${PGDATABASE};"
    fi
}

##############################################################################
# Create migration table if needed
# Globals:
#   PSQL
#   MIGRATION_TABLE_NAME
#   GREEN
#   RESET
# Arguments:
#   None
# Returns:
#   None
##############################################################################
create_migration_table() {
    echo -e "Creating ${GREEN}${MIGRATION_TABLE_NAME}${RESET} table..."
    ${PSQL} --single-transaction <<SQL
CREATE TABLE IF NOT EXISTS "${MIGRATION_TABLE_NAME}"
(
    script_file  varchar(255) NOT NULL PRIMARY KEY,
    hash         varchar(64) NOT NULL,
    date_applied timestamp NOT NULL
);

CREATE UNIQUE INDEX IF NOT EXISTS "${MIGRATION_TABLE_NAME}_script_file_idx" ON "${MIGRATION_TABLE_NAME}" (script_file);
SQL
}

##############################################################################
# Run migrations/*.sql scripts
# Globals:
#   MIGRATION_DB_FOLDER
#   MIGRATION_SCRIPT_LOCATION
#   GREEN
#   RESET
# Arguments:
#   None
# Returns:
#   None
##############################################################################
run_migrations() {
    local readonly migrations="${MIGRATION_DB_FOLDER}/migrations"
    local readonly dry_run=$([[ -n "${DRY_RUN:+set}" ]] && echo " [DRY RUN]" || echo "")

    if [[ -d ${migrations} ]] && ls ${migrations}/*.sql 1>/dev/null; then
        echo -e "Preparing migration script from ${GREEN}${migrations}${RESET}..."

        cat << SQL > ${MIGRATION_SCRIPT_LOCATION}
/* Script was generated on $(date -u '+%Y-%m-%d %H:%M:%SZ') */

LOCK TABLE ONLY "${MIGRATION_TABLE_NAME}" IN ACCESS EXCLUSIVE MODE;

SQL

        for entry in $(ls ${migrations}/*.sql | sort)
        do
            echo -e "Adding migration ${GREEN}${entry}${RESET}"
        
            local readonly name=$(basename ${entry})
            local readonly hash=$(sha1sum ${entry} | cut -f 1 -d ' ')

            cat << SQL >> ${MIGRATION_SCRIPT_LOCATION}

--
-- BEG: ${name}
--
DO \$\$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM ${MIGRATION_TABLE_NAME} WHERE script_file = '${name}') THEN
SQL
            if [[ -z "${dry_run}" ]]; then
                cat ${entry} | sed -e 's,^,\t\t,g' >> ${MIGRATION_SCRIPT_LOCATION}
                cat << SQL >> ${MIGRATION_SCRIPT_LOCATION}

        INSERT INTO "${MIGRATION_TABLE_NAME}" (script_file, hash, date_applied) VALUES ('${name}', '${hash}', NOW());

SQL
            fi
            cat << SQL >> ${MIGRATION_SCRIPT_LOCATION}
        RAISE NOTICE 'APPLIED: ${name}${dry_run}';
    ELSE
        RAISE NOTICE 'SKIPPED: ${name} was already applied';
    END IF;
END;
\$\$;
--
-- END: ${name}
--
SQL
        done

        echo "Running migration script..."
        ${PSQL} --single-transaction --file=${MIGRATION_SCRIPT_LOCATION}
    else
        echo -e  "No migrations found at ${GREEN}${migrations}${RESET}"
    fi
}

##############################################################################
# seed local database table if needed
# Globals:
#   LOCAL_DEVELOPMENT
#   MIGRATION_DB_FOLDER
#   DRY_RUN
#   GREEN
#   RESET
# Arguments:
#   None
# Returns:
#   None
##############################################################################
seed_database() {
    local readonly seed="${MIGRATION_DB_FOLDER}/seed"
    local readonly order_file="${seed}/_order"
    local readonly dry_run=$([[ -n "${DRY_RUN:+set}" ]] && echo " [DRY RUN]" || echo "")

    if [[ -n "${LOCAL_DEVELOPMENT:+set}" ]] && [[ -d ${seed} ]] && [[ -f ${order_file} ]]; then
        echo -e "Importing seed data from ${GREEN}${seed}${RESET}..."

        while read name; do
            local readonly table_name=$(echo ${name} | cut -f 1 -d '.')
            local readonly file="${seed}/${name}"

            echo -e "Seeding ${GREEN}${table_name}${RESET} with ${GREEN}${file}${RESET}${dry_run}"
            if [[ -z "${dry_run}" ]]; then
                ${PSQL} --single-transaction --command="\\copy \"${table_name}\" FROM '${file}' WITH DELIMITER ',' CSV HEADER;"
            fi
        done < ${order_file}
    else
        echo -e "No seed data found at ${GREEN}${seed}${RESET}"
    fi
}

wait_for_database
create_database
create_migration_table
run_migrations
seed_database

echo "Done"
