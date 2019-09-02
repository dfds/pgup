#!/bin/bash

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

read -p "Please enter the title of your new migration script: " inputName

name=$(echo ${inputName} | tr "[:blank:]" "_")
dir="$(pwd)/db/migrations"

if [ ! -d ${dir} ]; then
    mkdir ${dir}
fi

version=$(date '+%Y%m%d%H%M%S')

file="${dir}/${version}_${name}.sql"

echo "-- $(date '+%Y-%m-%d %H:%M:%S') : ${inputName}" > ${file}

echo "Created migration script in: ${file}"
