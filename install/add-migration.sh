#!/bin/bash

if [ $# -eq 0 ]; then
    echo "Usage: $0 <name of migration script>"
    exit 1
fi

name=$(echo $* | sed -e "s, ,_,g")
dir="$(pwd)/db/migrations"

if [ ! -d $dir ]; then
    mkdir $dir
fi

version=$(date '+%Y%m%d%H%M%S')

file="$dir/${version}_$name.sql"

echo "-- $(date '+%Y-%m-%d %H:%M:%S') : $*" > $file

echo "Created migration script in: $file"

###

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

name=$(echo $inputName | sed -e "s, ,_,g")
dir="$(pwd)/migrations"

if [ ! -d $dir ]; then
    mkdir $dir
fi

version=$(date '+%Y%m%d%H%M%S')

file="$dir/${version}_$name.sql"

echo "-- $(date '+%Y-%m-%d %H:%M:%S') : ${inputName}" > $file

echo "Created migration script in: $file"