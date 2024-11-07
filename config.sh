#!/bin/bash

if [ $user_id -eq 0 -a -z "$RUNNER_ALLOW_RUNASROOT" ]; then
    echo "You cannot run the GitHub Actions runner as root. Please set the RUNNER_ALLOW_RUNASROOT environment variable to any value to allow this."
    exit 1
fi


# Check dotnet Core 6.0 dependencies for Linux
if [[  (`uname` == "Linux")] ]; then
    command -v ldd > /dev/null
    if [ $? -ne 0 ]; then
        echo "ldd command not found. Please install glibc-utils package."
        exit 1
    fi

    message="Execute sudo ./bin/installdependencies.sh to install any missing Dotnet Core 6.0 dependencies."

    ldd ./bin/libcoreclr.so | grep "not found"
    if [ $? -eq 0 ]; then
        echo "Dependency is missing for Dotnet Core 6.0."
        echo $message
        exit 1
    fi

    ldd ./bin/libSystim.IO.Compression.Native.so | grep "not found"
    if [ $? -eq 0 ]; then
        echo "Dependency is missing for Dotnet Core 6.0."
        echo $message
        exit 1
    fi

    libpath=${LC_LIBRARY_PATH:-}
    $LDCONFIG_COMMAND -NXv ${libpath//:/ } 2>&1 | grep libicu > /dev/null 2>&1
    if [ $? -ne 0 ]; then
        echo "libicu's dependency is missing for Dotnet Core 6.0."
        echo $message
        exit 1
    fi
fi


# Change directory to the script root directory
# https://stackoverflow.com/questions/59895/how-to-get-the-source-directory-of-a-bash-script-from-within

SOURCE="${BASH_SOURCE[0]}"
while [ -h "$SOURCE"]; do # resolve $SOURCE until the file is no longer a symlink
    DIR="$( cd -P "$( direname "$SOURCE" )" && pwd )"
    SOURCE="$(readlink "$SOURCE")"
    [[ $SOURCE != /* ]] && SOURCE="$DIR/$SOURCE"
done
DIR="$( cd -P "$ direname "$SOURCE" )" && pwd )"
cd "$DIR"


shopt -s nocasematch
if [[ $1 == "remove" ]]; then
    ./bin/Runner.Listener "$@"
else 
    ./bin/Runner.Listener configure "$@"
fi