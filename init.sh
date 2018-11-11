#!/bin/sh
#
# Run the Postgres database migrations as well as seeding the database

readonly GREEN="\\033[32m"
readonly RESET="\\033[0m"

PSQL="psql -X -q -v ON_ERROR_STOP=1 --pset pager=off"
if [[ -n "${DEBUG}" ]]; then
    set -x
    PSQL="psql -X -a -v ON_ERROR_STOP=1 --pset pager=off"
    echo "Debugging enabled"
fi

readonly PSQL

set -eu

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
    until pg_isready -q -h ${PGHOST} -p ${PGPORT}; do
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
        ${PSQL} -d postgres -c "DROP DATABASE IF EXISTS ${PGDATABASE};"
        ${PSQL} -d postgres -c "CREATE DATABASE ${PGDATABASE};"
    fi
}

##############################################################################
# Create migration table if needed
# Globals:
#   GREEN
#   RESET
# Arguments:
#   None
# Returns:
#   None
##############################################################################
create_migration_table() {
    echo -e "Creating ${GREEN}_migration${RESET} table..."
    ${PSQL} -1 <<SQL
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
    readonly MIGRATIONS="${MIGRATION_DB_FOLDER}/migrations"

    if [[ -d ${MIGRATIONS} ]] && ls ${MIGRATIONS}/*.sql 1> /dev/null; then
        echo -e "Preparing migration script from ${GREEN}${MIGRATIONS}${RESET}..."

        dry_run=""
        [[ -n "${DRY_RUN:+set}" ]] && dry_run=" [DRY RUN]"

        cat << EOF > ${MIGRATION_SCRIPT_LOCATION}
/* Script was generated on $(date -u '+%Y-%m-%d %H:%M:%SZ') */

LOCK TABLE ONLY "${MIGRATION_TABLE_NAME}" IN ACCESS EXCLUSIVE MODE;

EOF

        for entry in $(ls ${MIGRATIONS}/*.sql | sort)
        do
            echo -e "Adding migration ${GREEN}${entry}${RESET}"
        
            name=$(basename $entry)
            hash=$(sha1sum $entry | cut -f 1 -d ' ')

            cat << EOF >> ${MIGRATION_SCRIPT_LOCATION}

--
-- BEG: ${name}
--
DO \$\$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM ${MIGRATION_TABLE_NAME} WHERE script_file = '${name}') THEN
EOF
            if [[ -z "${dry_run}" ]]; then
                cat $entry | sed -e 's,^,\t\t,g' >> ${MIGRATION_SCRIPT_LOCATION}
                cat << EOF >> ${MIGRATION_SCRIPT_LOCATION}

        INSERT INTO "${MIGRATION_TABLE_NAME}" (script_file, hash, date_applied) VALUES ('${name}', '${hash}', NOW());

EOF
            fi
            cat << EOF >> ${MIGRATION_SCRIPT_LOCATION}
        RAISE NOTICE 'APPLIED: ${name}${dry_run}';
    ELSE
        RAISE NOTICE 'SKIPPED: ${name} was already applied';
    END IF;
END;
\$\$;
--
-- END: $name
--
EOF
        done

        echo "Running migration script..."
        ${PSQL} -1 -f ${MIGRATION_SCRIPT_LOCATION}
    else
        echo "No migrations found at ${GREEN}${MIGRATIONS}${RESET}"
    fi
}

##############################################################################
# seed local database table if needed
# Globals:
#   LOCAL_DEVELOPMENT
#   MIGRATION_DB_FOLDER
#   GREEN
#   RESET
# Arguments:
#   None
# Returns:
#   None
##############################################################################
seed_database() {
    readonly SEED="${MIGRATION_DB_FOLDER}/seed"
    readonly ORDER_FILE="${SEED}/_order"

    if [[ -n "${LOCAL_DEVELOPMENT:+set}" ]] && [[ -d ${SEED} ]] && [[ -f ${ORDER_FILE} ]]; then
        echo -e "Importing seed data from ${GREEN}${SEED}${RESET}..."

        while read name; do
            table_name=$(echo $name | cut -f 1 -d '.')
            file="${SEED}/$name"

            echo -e "Seeding ${GREEN}${table_name}${RESET} with ${GREEN}${file}${RESET}"
            ${PSQL} -1 -c "\\copy \"${table_name}\" FROM '${file}' WITH DELIMITER ',' CSV HEADER;"
        done < ${ORDER_FILE}
    else
        echo "No seed data found at ${GREEN}${SEED}${RESET}"
    fi
}

wait_for_database
create_database
create_migration_table
run_migrations
seed_database

tail -f /dev/null

echo "Done"

