#!/bin/bash

[[ -n "${DEBUG}" ]] && set -o xtrace

set -o errexit
set -o pipefail

target="${PWD}"
target_name=$(basename ${target})
db_path="${target}/db"

function err() {
    echo $*
    exit 1
}

[[ -d ${db_path} ]] && err "${db_path} already exists, aborting..."
[[ -f "add-migration.sh" ]] && err "add-migration.sh already exists, aborting..."
[[ -d "docker-compose.yml" ]] && err "docker-compose.yml already exists, aborting..."

temp=$(mktemp -d)

echo ''
echo ' (             *    (           (                  (       )     )  '
echo ' )\ )   (    (  `   )\ ) (      )\ )   (      *   ))\ ) ( /(  ( /(  '
echo '(()/( ( )\   )\))( (()/( )\ )  (()/(   )\   ` )  /(()/( )\()) )\()) '
echo ' /(_)))((_) ((_)()\ /(_)|()/(   /(_)|(((_)(  ( )(_))(_)|(_)\ ((_)\  '
echo '(_))_((_)_  (_()((_|_))  /(_))_(_))  )\ _ )\(_(_()|_))   ((_) _((_) '
echo ' |   \| _ ) |  \/  |_ _|(_)) __| _ \ (_)_\(_)_   _|_ _| / _ \| \| | '
echo ' | |) | _ \ | |\/| || |   | (_ |   /  / _ \   | |  | | | (_) | .` | '
echo ' |___/|___/ |_|  |_|___|   \___|_|_\ /_/ \_\  |_| |___| \___/|_|\_| '
echo '                                                                    '
echo ''
echo "Installing database migration in '${target_name}'..."

pushd ${temp} 1>/dev/null

curl -s https://api.github.com/repos/dfds/pgup/releases/latest | \
    grep "tarball_url" | \
    cut -d '"' -f 4 | \
    xargs curl -o pgup.tar.gz -sSL

tar xzf pgup.tar.gz --strip-component 1

popd 1>/dev/null

cp -r ${temp}/db ${target}
cp -r ${temp}/install/* ${target}

rm -rf ${temp}

echo
echo "The following directories and files have been added:"
echo
echo "${target_name}"
echo "├ db/                 # database migration root"
echo "│ ├ migrations/       # contains example migration scripts"
echo "│ └ seed/             # contains example seed data"
echo "├ add-migration.sh    # use this script to add migrations"
echo "└ docker-compose.yaml # example of database and migration container"
echo
echo -e "\033[1m** NOTE: remember to remove any example scripts before committing...\033[0m"

