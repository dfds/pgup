# :warning: ~Repository not maintained~ :warning:

*as of 22FEB24: Image built from this repo seems to do the bare minimum it's expected to do*

Please note that this repository is no longer being maintained.

- It may contain code, or reference dependencies, with known vulnerabilities
- It may contain out-dated advice, how-to's or other forms of documentation

The contents might still serve as a source of inspiration, but please review any contents before reusing elsewhere.

# Postgres Database Migration

## Installation

### Bash

The following will download the latest version:

```
curl -sSL https://raw.githubusercontent.com/dfds/pgup/master/install.sh | sh -s -
```

## Notes on building `Dockerfile`

When building the docker image `update-ca-certificates` may cause warnings, it should not be an issue according to https://github.com/gliderlabs/docker-alpine/issues/30

## Layout

```bash
/db
┣ migrations/
┃ ┣ 20181017194326_create_team_table.sql
┃ ┣ 20181017194336_create_user_table.sql
┃ ┗ 20181017194344_create_membership_table.sql
┗ seed/
  ┣ _order
  ┣ Membership.csv
  ┣ Team.csv
  ┗ User.csv
```

Using:

```bash
./add-migrations.sh this is the latest and greatest migration
```

to add a new migration script. Will result in a new script file being created in `db/migrations/yyyymmddhhmmss_this_is_the_latest_and_greatest_migration.sql` where yyyymmddhhmmss is the current local timestamp.

## Environment Variables

| Name               | Required | Default     | Comment                                                                      |
| ------------------ | :------: | ----------- | ---------------------------------------------------------------------------- |
| PGDATABASE         |   YES    | n/a         | **MUST** be set to the name of the database                                  |
| PGHOST             |   YES    | n/a         | **MUST** be set to the host (url/ip)                                         |
| PGPORT             |    -     | 5432        | **MAY** be overridden to use a different port                                |
| PGUSER             |   YES    | n/a         | **MUST** be set to the database user                                         |
| PGPASSWORD         |   YES    | n/a         | **MUST** be set to the database user password                                |
| PGSSLMODE          |    -     | verify-full | **MAY** be set to _disable_ for local development                            |
| DEBUG              |    -     | _unset_     | **MAY** be set to any value (=1) to enable script debugging                  |
| LOCAL_DEVELOPMENT  |    -     | _unset_     | **MAY** be set to any value (=1) for local development (see below)           |
| SEED_CSV_SEPARATOR |    -     | ,           | **MAY** be overriden to allow for a different seperator for seeding from csv |

## Local development

Run

```bash
docker-compose up --build
```

Change the environment values in the `docker-compose.yml` file.

- Enable local development using `LOCAL_DEVELOPMENT=1`.
  - Will recreate the database from scratch and run any migrations as well as seed the database.
- Disable SSL mode using `PGSSLMODE=disable`.

### Seeding

To seed the database for local development:

1. create a `seed` folder in the `db` folder, according to the layout above.
1. create one or more `.csv` files
   - the name of the file must match a table in the database (remember Postgres is case-sensitive like Linux).
   - file **must** contain a header
   - all fields (including headers) **must** be separated by commas (`,`).
   - fields **must** be in the same order as the columns in the table schema.
1. create an `_order` file
   - each line **must** contain the name of the CSV-files from the previous step.
   - **only** include the name of the file (case-sensitive and with extension), **not** the path.

_To seed the database for production use is out-of-scope for this README, but consider using regular migration scripts and insert statements, or restoring a prepopulated database._

### Debugging

- Enable debugging by setting environment variable `DEBUG` (e.g. `DEBUG=1`).
- To inspect the final generated migration script it is possible to mount a volumne to `/tmp` in the docker container, like:
  ```yaml
  volumes:
    - ${PWD}/db/output:/tmp
  ```
